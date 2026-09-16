import 'dart:async';
import 'dart:io';
import '../../shared/models/download_task.dart';
import '../constants/app_constants.dart';
import '../storage/download_repository.dart';
import '../storage/download_storage_service.dart';
import '../storage/file_manager.dart';
import '../utils/app_logger.dart';
import '../utils/notification_service.dart';
import 'download_engine.dart';
import 'download_service_channel.dart';

typedef TaskUpdatedCallback = void Function(DownloadTask task);

/// Queue managing active and pending downloads with concurrency limits
/// and enterprise MediaStore finalization.
class DownloadQueue {
  DownloadQueue({
    required this.repository,
    required this.onTaskUpdated,
    DownloadStorageService? storageService,
  }) : _storageService = storageService ??
            (Platform.isAndroid
                ? AndroidMediaStoreStorageService()
                : DefaultFileSystemStorageService());

  final DownloadRepository repository;
  final TaskUpdatedCallback onTaskUpdated;
  final DownloadStorageService _storageService;

  int _maxConcurrent = AppConstants.defaultMaxConcurrentDownloads;
  final List<String> _queuedIds = [];
  final Map<String, DownloadEngine> _runningEngines = {};
  final Map<String, DownloadTask> _activeTasks = {};
  final Map<String, String> _streamUrls = {};

  void setMaxConcurrency(int max) {
    _maxConcurrent = max.clamp(1, 3);
    _checkQueue();
  }

  /// Add a task to download queue.
  Future<void> enqueue(DownloadTask task, {required String streamUrl}) async {
    _activeTasks[task.id] = task;
    _streamUrls[task.id] = streamUrl;

    await repository.saveTask(task);
    onTaskUpdated(task);

    if (!_queuedIds.contains(task.id) && !_runningEngines.containsKey(task.id)) {
      _queuedIds.add(task.id);
    }

    _checkQueue();
  }

  /// Pause an active download.
  Future<void> pause(String taskId) async {
    final engine = _runningEngines[taskId];
    if (engine != null) {
      engine.pause();
    } else if (_queuedIds.contains(taskId)) {
      _queuedIds.remove(taskId);
      final task = _activeTasks[taskId];
      if (task != null) {
        final updated = task.copyWith(status: DownloadStatus.paused);
        _activeTasks[taskId] = updated;
        await repository.updateStatus(taskId, DownloadStatus.paused);
        onTaskUpdated(updated);
      }
    }
  }

  /// Resume a paused or failed task.
  Future<void> resume(String taskId) async {
    final task = _activeTasks[taskId] ?? await repository.getTaskById(taskId);
    final streamUrl = _streamUrls[taskId] ?? task?.url;

    if (task != null && streamUrl != null) {
      final updated = task.copyWith(status: DownloadStatus.queued, errorMessage: null);
      _activeTasks[taskId] = updated;
      _streamUrls[taskId] = streamUrl;
      await repository.updateStatus(taskId, DownloadStatus.queued);
      onTaskUpdated(updated);

      if (!_queuedIds.contains(taskId) && !_runningEngines.containsKey(taskId)) {
        _queuedIds.add(taskId);
      }
      _checkQueue();
    }
  }

  /// Cancel a download and clean up temp files.
  Future<void> cancel(String taskId) async {
    final engine = _runningEngines[taskId];
    if (engine != null) {
      engine.cancel();
    } else {
      _queuedIds.remove(taskId);
      final tempPath = await FileManager.getTempFilePath(taskId);
      await FileManager.deleteFileIfExists(tempPath);

      final task = _activeTasks[taskId];
      if (task != null) {
        final updated = task.copyWith(status: DownloadStatus.cancelled);
        _activeTasks.remove(taskId);
        await repository.updateStatus(taskId, DownloadStatus.cancelled);
        onTaskUpdated(updated);
      }
    }
    _checkQueue();
  }

  /// Retry a failed or cancelled task.
  Future<void> retry(String taskId) async {
    await resume(taskId);
  }

  /// Evaluates queue and launches pending tasks within concurrency limit.
  void _checkQueue() {
    while (_runningEngines.length < _maxConcurrent && _queuedIds.isNotEmpty) {
      final nextId = _queuedIds.removeAt(0);
      _startTask(nextId);
    }

    _updateForegroundService();
  }

  void _startTask(String taskId) async {
    final task = _activeTasks[taskId];
    final streamUrl = _streamUrls[taskId];
    if (task == null || streamUrl == null) return;

    final mime = task.mimeType ??
        FileManager.resolveMimeType(task.fileName, isAudio: task.isAudioOnly);

    final engine = DownloadEngine(
      taskId: taskId,
      downloadUrl: streamUrl,
      fileName: task.fileName,
      mimeType: mime,
      isAudioOnly: task.isAudioOnly,
      storageService: _storageService,
    );
    _runningEngines[taskId] = engine;

    final runningTask = task.copyWith(status: DownloadStatus.downloading);
    _activeTasks[taskId] = runningTask;
    await repository.updateStatus(taskId, DownloadStatus.downloading);
    onTaskUpdated(runningTask);
    _updateForegroundService();

    // Throttled DB save timestamp
    var lastDbSync = DateTime.now();

    try {
      final finalizeResult = await engine.execute(
        onProgress: ({
          required int downloadedBytes,
          required int totalBytes,
          required int speedBytesPerSec,
          Duration? eta,
        }) {
          final updated = (_activeTasks[taskId] ?? runningTask).copyWith(
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            speedBytesPerSec: speedBytesPerSec,
            etaDuration: eta,
            status: DownloadStatus.downloading,
          );
          _activeTasks[taskId] = updated;
          onTaskUpdated(updated);

          // Update foreground service notification
          DownloadServiceChannel.updateProgress(
            title: updated.title,
            text: '${updated.progressPercent}% (${updated.formattedDownloadedSize} / ${updated.formattedTotalSize}) • ${updated.formattedSpeed}',
            progress: updated.progressPercent,
          );

          // Sync with DB every 1 second
          final now = DateTime.now();
          if (now.difference(lastDbSync).inMilliseconds >= 1000) {
            lastDbSync = now;
            repository.updateProgress(
              id: taskId,
              downloadedBytes: downloadedBytes,
              totalBytes: totalBytes,
              status: DownloadStatus.downloading,
            );
          }
        },
      );

      // Successfully completed
      final completedTask = (_activeTasks[taskId] ?? runningTask).copyWith(
        status: DownloadStatus.completed,
        downloadedBytes: finalizeResult.sizeBytes,
        totalBytes: finalizeResult.sizeBytes,
        speedBytesPerSec: 0,
        etaDuration: null,
        targetFilePath: finalizeResult.filePath ?? finalizeResult.storageUri,
        storageType: finalizeResult.storageType,
        storageUri: finalizeResult.storageUri,
        mimeType: finalizeResult.mimeType,
        fileName: finalizeResult.displayName,
        completedAt: DateTime.now(),
      );

      _runningEngines.remove(taskId);
      _activeTasks.remove(taskId);
      _streamUrls.remove(taskId);

      await repository.markCompleted(
        id: taskId,
        finalFilePath: finalizeResult.filePath ?? finalizeResult.storageUri,
        finalSizeBytes: finalizeResult.sizeBytes,
        storageType: finalizeResult.storageType,
        storageUri: finalizeResult.storageUri,
        mimeType: finalizeResult.mimeType,
      );
      onTaskUpdated(completedTask);

      // Show completion notification
      final notifId = taskId.hashCode.abs();
      NotificationService.showDownloadCompleted(
        id: notifId,
        title: completedTask.title,
        filePath: finalizeResult.storageUri,
      );
    } catch (e) {
      _runningEngines.remove(taskId);

      if (engine.isPaused) {
        final current = _activeTasks[taskId] ?? runningTask;
        final pausedTask = current.copyWith(
          status: DownloadStatus.paused,
          speedBytesPerSec: 0,
          etaDuration: null,
        );
        _activeTasks[taskId] = pausedTask;
        await repository.updateStatus(taskId, DownloadStatus.paused);
        onTaskUpdated(pausedTask);
      } else if (engine.isCancelled) {
        final current = _activeTasks[taskId] ?? runningTask;
        final cancelledTask = current.copyWith(
          status: DownloadStatus.cancelled,
          speedBytesPerSec: 0,
          etaDuration: null,
        );
        _activeTasks.remove(taskId);
        _streamUrls.remove(taskId);
        await repository.updateStatus(taskId, DownloadStatus.cancelled);
        onTaskUpdated(cancelledTask);
      } else {
        AppLogger.e('Task $taskId failed: $e');
        final current = _activeTasks[taskId] ?? runningTask;
        final errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('StorageError: ', '');
        final failedTask = current.copyWith(
          status: DownloadStatus.failed,
          errorMessage: errorMsg,
          speedBytesPerSec: 0,
          etaDuration: null,
        );
        _activeTasks[taskId] = failedTask;
        await repository.markFailed(taskId, errorMsg);
        onTaskUpdated(failedTask);

        // Show failure notification
        final notifId = taskId.hashCode.abs();
        NotificationService.showDownloadFailed(
          id: notifId,
          title: failedTask.title,
          error: failedTask.errorMessage ?? 'Download failed',
        );
      }
    } finally {
      _checkQueue();
    }
  }

  void _updateForegroundService() {
    if (_runningEngines.isEmpty) {
      DownloadServiceChannel.stopService();
    } else {
      final firstTask = _activeTasks[_runningEngines.keys.first];
      if (firstTask != null) {
        if (!DownloadServiceChannel.isRunning) {
          DownloadServiceChannel.startService(title: firstTask.title);
        }
      }
    }
  }
}
