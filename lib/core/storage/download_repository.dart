import 'dart:convert';
import 'package:drift/drift.dart';
import '../../shared/models/download_task.dart';
import 'app_database.dart';
import 'download_storage_service.dart';

/// Repository abstracting DownloadRecords storage operations and mapping to domain models.
class DownloadRepository {
  DownloadRepository(this._database, [DownloadStorageService? storageService])
      : _storageService = storageService;

  final AppDatabase _database;
  final DownloadStorageService? _storageService;
  DownloadDao get _dao => _database.downloadDao;

  /// Map Drift table row to in-memory domain DownloadTask.
  static DownloadTask recordToTask(DownloadRecord record) {
    DownloadStatus status;
    try {
      status = DownloadStatus.values.byName(record.status);
    } catch (_) {
      status = DownloadStatus.failed;
    }

    return DownloadTask(
      id: record.id,
      url: record.url,
      title: record.title,
      author: record.author,
      authorAvatarUrl: record.authorAvatarUrl,
      thumbnailUrl: record.thumbnailUrl,
      durationSeconds: record.durationSeconds,
      targetFilePath: record.filePath,
      fileName: record.fileName,
      storageType: record.storageType,
      storageUri: record.storageUri,
      mimeType: record.mimeType,
      totalBytes: record.fileSizeBytes,
      downloadedBytes: record.downloadedBytes,
      status: status,
      hasWatermark: record.hasWatermark,
      isAudioOnly: record.isAudioOnly,
      createdAt: record.createdAt,
      completedAt: record.completedAt,
      errorMessage: record.errorMessage,
    );
  }

  /// Watch active tasks (queued, downloading, paused, finalizing).
  Stream<List<DownloadTask>> watchActiveTasks() {
    return _dao.watchActiveDownloads().map((records) => records.map(recordToTask).toList());
  }

  /// Watch completed history tasks.
  Stream<List<DownloadTask>> watchCompletedTasks() {
    return _dao.watchCompletedDownloads().map((records) => records.map(recordToTask).toList());
  }

  /// Watch all tasks ordered by createdAt desc.
  Stream<List<DownloadTask>> watchAllTasks() {
    return _dao.watchAllDownloads().map((records) => records.map(recordToTask).toList());
  }

  /// Get recent completed tasks.
  Future<List<DownloadTask>> getRecentCompleted({int limit = 5}) async {
    final records = await _dao.getRecentCompleted(limit);
    return records.map(recordToTask).toList();
  }

  /// Search completed history by query.
  Future<List<DownloadTask>> searchHistory(String query) async {
    if (query.trim().isEmpty) {
      final records = await _dao.watchCompletedDownloads().first;
      return records.map(recordToTask).toList();
    }
    final records = await _dao.searchHistory(query.trim());
    return records.map(recordToTask).toList();
  }

  /// Export entire completed history as JSON string.
  Future<String> exportHistoryJson() async {
    final records = await _dao.watchCompletedDownloads().first;
    final tasks = records.map(recordToTask).map((t) => t.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks,
    });
  }

  /// Import history from JSON string into database.
  Future<int> importHistoryJson(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic> || decoded['tasks'] is! List) {
      throw const FormatException('Invalid TokSaver history backup format.');
    }

    final list = decoded['tasks'] as List;
    int imported = 0;

    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final task = DownloadTask.fromJson(item);
        await saveTask(task);
        imported++;
      }
    }

    return imported;
  }

  /// Get task by ID.
  Future<DownloadTask?> getTaskById(String id) async {
    final record = await _dao.getById(id);
    if (record == null) return null;
    return recordToTask(record);
  }

  /// Save or update task.
  Future<void> saveTask(DownloadTask task) async {
    await _dao.insertOrUpdate(
      DownloadRecordsCompanion(
        id: Value(task.id),
        url: Value(task.url),
        title: Value(task.title),
        author: Value(task.author),
        authorAvatarUrl: Value(task.authorAvatarUrl),
        thumbnailUrl: Value(task.thumbnailUrl),
        durationSeconds: Value(task.durationSeconds),
        filePath: Value(task.targetFilePath),
        fileName: Value(task.fileName),
        storageType: Value(task.storageType),
        storageUri: Value(task.storageUri),
        mimeType: Value(task.mimeType),
        fileSizeBytes: Value(task.totalBytes),
        downloadedBytes: Value(task.downloadedBytes),
        hasWatermark: Value(task.hasWatermark),
        isAudioOnly: Value(task.isAudioOnly),
        status: Value(task.status.name),
        errorMessage: Value(task.errorMessage),
        createdAt: Value(task.createdAt),
        completedAt: Value(task.completedAt),
      ),
    );
  }

  /// Update download progress.
  Future<void> updateProgress({
    required String id,
    required int downloadedBytes,
    required int totalBytes,
    required DownloadStatus status,
  }) async {
    await _dao.updateProgress(
      id: id,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      status: status.name,
    );
  }

  /// Update status of a task.
  Future<void> updateStatus(String id, DownloadStatus status) async {
    await _dao.updateStatus(id, status.name);
  }

  /// Mark download completed with storage metadata.
  Future<void> markCompleted({
    required String id,
    required String finalFilePath,
    required int finalSizeBytes,
    String storageType = 'media_store',
    String? storageUri,
    String? mimeType,
  }) async {
    await _dao.markCompleted(
      id: id,
      finalFilePath: finalFilePath,
      finalSizeBytes: finalSizeBytes,
      storageType: storageType,
      storageUri: storageUri,
      mimeType: mimeType,
    );
  }

  /// Mark download failed with error message.
  Future<void> markFailed(String id, String errorMessage) async {
    await _dao.markFailed(id, errorMessage);
  }

  /// Delete task record and optionally delete physical file / MediaStore item.
  Future<void> deleteTask(String id, {bool deleteFile = false}) async {
    if (deleteFile) {
      final task = await getTaskById(id);
      if (task != null && _storageService != null) {
        await _storageService.deleteStoredFile(
          storageUri: task.storageUri ?? task.targetFilePath,
          storageType: task.storageType,
          filePath: task.targetFilePath,
        );
      }
    }
    await _dao.deleteRecord(id);
  }

  /// Clear all completed history.
  Future<void> clearHistory({bool deleteFiles = false}) async {
    if (deleteFiles && _storageService != null) {
      final records = await _dao.watchCompletedDownloads().first;
      for (final rec in records) {
        await _storageService.deleteStoredFile(
          storageUri: rec.storageUri ?? rec.filePath,
          storageType: rec.storageType,
          filePath: rec.filePath,
        );
      }
    }
    await _dao.clearCompletedHistory();
  }

  /// Prune old history entries when exceeding limit.
  Future<void> pruneOldHistory(int maxEntries) async {
    await _dao.pruneOldHistory(maxEntries);
  }
}
