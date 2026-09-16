import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/core/storage/app_database.dart';
import 'package:tiktok_downloader/core/storage/download_repository.dart';
import 'package:tiktok_downloader/shared/models/download_task.dart';

void main() {
  late AppDatabase db;
  late DownloadRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DownloadRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DownloadRepository Drift integration tests', () {
    final testTask = DownloadTask(
      id: 'task_001',
      url: 'https://www.tiktok.com/@creator/video/1001',
      title: 'Amazing Dance',
      author: 'SuperCreator',
      authorAvatarUrl: 'https://avatar.png',
      thumbnailUrl: 'https://thumb.png',
      durationSeconds: 30,
      targetFilePath: '/downloads/tiktok_test.mp4',
      fileName: 'tiktok_test.mp4',
      totalBytes: 5000000,
      downloadedBytes: 1000000,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );

    test('Insert and fetch task by ID', () async {
      await repository.saveTask(testTask);

      final fetched = await repository.getTaskById('task_001');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'task_001');
      expect(fetched.title, 'Amazing Dance');
      expect(fetched.author, 'SuperCreator');
      expect(fetched.status, DownloadStatus.downloading);
    });

    test('Update progress updates downloadedBytes and status in DB', () async {
      await repository.saveTask(testTask);

      await repository.updateProgress(
        id: 'task_001',
        downloadedBytes: 4000000,
        totalBytes: 5000000,
        status: DownloadStatus.downloading,
      );

      final updated = await repository.getTaskById('task_001');
      expect(updated!.downloadedBytes, 4000000);
      expect(updated.status, DownloadStatus.downloading);
    });

    test('Mark completed updates status and completedAt', () async {
      await repository.saveTask(testTask);

      await repository.markCompleted(
        id: 'task_001',
        finalFilePath: '/movies/final.mp4',
        finalSizeBytes: 5000000,
      );

      final completed = await repository.getTaskById('task_001');
      expect(completed!.status, DownloadStatus.completed);
      expect(completed.completedAt, isNotNull);
      expect(completed.targetFilePath, '/movies/final.mp4');

      final recent = await repository.getRecentCompleted(limit: 5);
      expect(recent.length, 1);
      expect(recent.first.id, 'task_001');
    });

    test('Search history finds completed task by query', () async {
      await repository.saveTask(testTask);
      await repository.markCompleted(
        id: 'task_001',
        finalFilePath: '/movies/final.mp4',
        finalSizeBytes: 5000000,
      );

      final results = await repository.searchHistory('Dance');
      expect(results.length, 1);

      final emptyResults = await repository.searchHistory('Cooking');
      expect(emptyResults.isEmpty, isTrue);
    });

    test('Delete task removes record from DB', () async {
      await repository.saveTask(testTask);
      await repository.deleteTask('task_001');

      final fetched = await repository.getTaskById('task_001');
      expect(fetched, isNull);
    });

    test('Export and import history JSON backup works symmetrically', () async {
      await repository.saveTask(testTask);
      await repository.markCompleted(
        id: 'task_001',
        finalFilePath: '/movies/final.mp4',
        finalSizeBytes: 5000000,
      );

      final exportedJson = await repository.exportHistoryJson();
      expect(exportedJson, contains('"version": 1'));
      expect(exportedJson, contains('Amazing Dance'));

      // Create a fresh clean database and import
      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRepo = DownloadRepository(freshDb);

      final importedCount = await freshRepo.importHistoryJson(exportedJson);
      expect(importedCount, equals(1));

      final restoredTask = await freshRepo.getTaskById('task_001');
      expect(restoredTask, isNotNull);
      expect(restoredTask!.title, equals('Amazing Dance'));
      expect(restoredTask.author, equals('SuperCreator'));

      await freshDb.close();
    });
  });
}
