import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/core/storage/download_storage_service.dart';
import 'package:tiktok_downloader/shared/models/download_task.dart';

void main() {
  group('DownloadStorageService & Model tests', () {
    test('StorageFinalizeResult holds storage metadata correctly', () {
      const result = StorageFinalizeResult(
        storageType: 'media_store',
        storageUri: 'content://media/external/video/media/1001',
        filePath: null,
        displayName: 'test_video.mp4',
        mimeType: 'video/mp4',
        relativePath: 'Movies/TokSaver',
        sizeBytes: 15420000,
      );

      expect(result.storageType, 'media_store');
      expect(result.storageUri, 'content://media/external/video/media/1001');
      expect(result.displayName, 'test_video.mp4');
      expect(result.mimeType, 'video/mp4');
      expect(result.relativePath, 'Movies/TokSaver');
      expect(result.sizeBytes, 15420000);
    });

    test('DownloadTask canonicalUri prefers storageUri over targetFilePath', () {
      final taskWithUri = DownloadTask(
        id: 'task_001',
        url: 'https://tiktok.com/video/1',
        title: 'Dance',
        author: 'User',
        targetFilePath: 'Dance.mp4',
        fileName: 'Dance.mp4',
        storageType: 'media_store',
        storageUri: 'content://media/external/video/media/555',
        mimeType: 'video/mp4',
        createdAt: DateTime.now(),
      );

      expect(taskWithUri.canonicalUri, 'content://media/external/video/media/555');

      final taskWithPathOnly = DownloadTask(
        id: 'task_002',
        url: 'https://tiktok.com/video/2',
        title: 'Song',
        author: 'Singer',
        targetFilePath: '/storage/emulated/0/Music/TokSaver/Song.mp3',
        fileName: 'Song.mp3',
        storageType: 'legacy_file',
        storageUri: null,
        mimeType: 'audio/mpeg',
        createdAt: DateTime.now(),
      );

      expect(taskWithPathOnly.canonicalUri, '/storage/emulated/0/Music/TokSaver/Song.mp3');
    });

    test('DownloadStatus handles finalizing lifecycle correctly', () {
      expect(DownloadStatus.finalizing.isActive, isTrue);
      expect(DownloadStatus.finalizing.isTerminal, isFalse);
      expect(DownloadStatus.finalizing.canPause, isFalse);

      expect(DownloadStatus.completed.isTerminal, isTrue);
      expect(DownloadStatus.failed.isTerminal, isTrue);
      expect(DownloadStatus.cancelled.isTerminal, isTrue);
    });
  });
}
