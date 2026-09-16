import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/download_queue.dart';
import '../../core/storage/download_storage_service.dart';
import '../../core/storage/file_manager.dart';
import '../../core/storage/storage_permission_handler.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/models/download_task.dart';
import '../../shared/models/video_metadata.dart';

/// State of active in-memory downloads map: taskId -> DownloadTask.
final downloadTasksMapProvider =
    StateNotifierProvider<DownloadTasksNotifier, Map<String, DownloadTask>>((ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  final storageService = ref.watch(downloadStorageServiceProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  final notifier = DownloadTasksNotifier(ref);

  final queue = DownloadQueue(
    repository: repository,
    storageService: storageService,
    onTaskUpdated: (task) {
      notifier.updateTask(task);
    },
  );

  // Sync settings max concurrency initially and on changes
  settingsRepo.getMaxConcurrentDownloads().then((count) {
    queue.setMaxConcurrency(count);
  });

  ref.listen<AsyncValue<int>>(maxConcurrentDownloadsProvider, (_, next) {
    final count = next.value;
    if (count != null) {
      queue.setMaxConcurrency(count);
    }
  });

  notifier.setQueue(queue);
  return notifier;
});

class DownloadTasksNotifier extends StateNotifier<Map<String, DownloadTask>> {
  DownloadTasksNotifier(this._ref) : super({});

  final Ref _ref;
  DownloadQueue? _queue;

  void setQueue(DownloadQueue queue) {
    _queue = queue;
  }

  void updateTask(DownloadTask task) {
    state = {...state, task.id: task};
  }

  /// Start a new download from parsed VideoMetadata.
  Future<String?> startDownload(
    VideoMetadata metadata, {
    bool hasWatermark = false,
    bool isAudioOnly = false,
  }) async {
    try {
      // Ensure permissions
      await StoragePermissionHandler.requestDownloadPermissions();

      // Determine stream URL
      final streamUrl = isAudioOnly
          ? (metadata.audioUrl ?? metadata.videoUrlNoWatermark)
          : (hasWatermark
              ? (metadata.videoUrlWatermark ?? metadata.videoUrlNoWatermark)
              : metadata.videoUrlNoWatermark);

      final baseFileName = isAudioOnly
          ? metadata.defaultAudioFileName
          : metadata.defaultVideoFileName;

      final extensionOverride = isAudioOnly ? '.mp3' : '.mp4';
      final sanitizedName = FileManager.sanitizeFileName(
        baseFileName,
        extensionOverride: extensionOverride,
      );

      final mimeType = isAudioOnly ? 'audio/mpeg' : 'video/mp4';
      final taskId = '${metadata.id}_${isAudioOnly ? 'audio' : 'video'}_${DateTime.now().millisecondsSinceEpoch}';

      if (kIsWeb) {
        final uri = Uri.parse(streamUrl);
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );

        final task = DownloadTask(
          id: taskId,
          url: metadata.originalUrl,
          title: metadata.displayTitle,
          author: metadata.authorName,
          authorAvatarUrl: metadata.authorAvatarUrl,
          thumbnailUrl: metadata.coverUrl,
          durationSeconds: metadata.durationSeconds,
          targetFilePath: streamUrl,
          fileName: sanitizedName,
          storageType: 'web_storage',
          storageUri: streamUrl,
          mimeType: mimeType,
          totalBytes: isAudioOnly ? metadata.audioSizeBytes : metadata.videoSizeBytes,
          downloadedBytes: isAudioOnly ? metadata.audioSizeBytes : metadata.videoSizeBytes,
          hasWatermark: hasWatermark,
          isAudioOnly: isAudioOnly,
          status: DownloadStatus.completed,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        try {
          final repository = _ref.read(downloadRepositoryProvider);
          await repository.saveTask(task);
        } catch (e) {
          AppLogger.w('Web local database task save skipped: $e');
        }

        updateTask(task);
        return taskId;
      }

      final storageType = (!kIsWeb && Platform.isAndroid) ? 'media_store' : 'file_system';

      final task = DownloadTask(
        id: taskId,
        url: metadata.originalUrl,
        title: metadata.displayTitle,
        author: metadata.authorName,
        authorAvatarUrl: metadata.authorAvatarUrl,
        thumbnailUrl: metadata.coverUrl,
        durationSeconds: metadata.durationSeconds,
        targetFilePath: sanitizedName,
        fileName: sanitizedName,
        storageType: storageType,
        mimeType: mimeType,
        totalBytes: isAudioOnly ? metadata.audioSizeBytes : metadata.videoSizeBytes,
        hasWatermark: hasWatermark,
        isAudioOnly: isAudioOnly,
        status: DownloadStatus.queued,
        createdAt: DateTime.now(),
      );

      AppLogger.i('Enqueueing download task $taskId: ${task.fileName} ($mimeType)');
      await _queue?.enqueue(task, streamUrl: streamUrl);

      return taskId;
    } catch (e, stack) {
      AppLogger.e('Failed to start download', e, stack);
      return null;
    }
  }

  /// Start downloading all photos from a slideshow post as individual tasks in the queue.
  Future<List<String>> startPhotoDownloads(VideoMetadata metadata) async {
    try {
      await StoragePermissionHandler.requestDownloadPermissions();
      final List<String> taskIds = [];
      final storageType = (!kIsWeb && Platform.isAndroid) ? 'media_store' : 'file_system';

      for (int i = 0; i < metadata.images.length; i++) {
        final imageUrl = metadata.images[i];
        final baseFileName = metadata.defaultPhotoFileName(i + 1);
        final sanitizedName = FileManager.sanitizeFileName(
          baseFileName,
          extensionOverride: '.jpg',
        );
        final taskId = '${metadata.id}_img_${i + 1}_${DateTime.now().millisecondsSinceEpoch}';

        if (kIsWeb) {
          final uri = Uri.parse(imageUrl);
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
          taskIds.add(taskId);
          continue;
        }

        final task = DownloadTask(
          id: taskId,
          url: metadata.originalUrl,
          title: '${metadata.displayTitle} (${i + 1}/${metadata.images.length})',
          author: metadata.authorName,
          authorAvatarUrl: metadata.authorAvatarUrl,
          thumbnailUrl: imageUrl,
          targetFilePath: sanitizedName,
          fileName: sanitizedName,
          storageType: storageType,
          mimeType: 'image/jpeg',
          hasWatermark: false,
          isAudioOnly: false,
          status: DownloadStatus.queued,
          createdAt: DateTime.now(),
        );

        AppLogger.i('Enqueueing photo task $taskId: $sanitizedName');
        await _queue?.enqueue(task, streamUrl: imageUrl);
        taskIds.add(taskId);
      }
      return taskIds;
    } catch (e, stack) {
      AppLogger.e('Failed to start photo downloads', e, stack);
      return [];
    }
  }

  Future<void> pauseDownload(String taskId) async {
    await _queue?.pause(taskId);
  }

  Future<void> resumeDownload(String taskId) async {
    await _queue?.resume(taskId);
  }

  Future<void> cancelDownload(String taskId) async {
    await _queue?.cancel(taskId);
    final newState = Map<String, DownloadTask>.from(state);
    newState.remove(taskId);
    state = newState;
  }

  Future<void> retryDownload(String taskId) async {
    await _queue?.retry(taskId);
  }

  Future<void> deleteTask(String taskId, {bool deleteFile = false}) async {
    await _queue?.cancel(taskId);
    final repository = _ref.read(downloadRepositoryProvider);
    await repository.deleteTask(taskId, deleteFile: deleteFile);
    final newState = Map<String, DownloadTask>.from(state);
    newState.remove(taskId);
    state = newState;
  }
}
