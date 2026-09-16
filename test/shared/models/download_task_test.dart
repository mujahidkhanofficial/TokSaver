import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/shared/models/download_task.dart';
import 'package:tiktok_downloader/shared/models/video_metadata.dart';

void main() {
  group('DownloadTask tests', () {
    test('Calculates progress and formatting correctly', () {
      final task = DownloadTask(
        id: '123',
        url: 'https://www.tiktok.com/@user/video/123',
        title: 'Dance Video',
        author: 'dancer',
        targetFilePath: '/path/to/video.mp4',
        fileName: 'video.mp4',
        totalBytes: 10 * 1024 * 1024, // 10 MB
        downloadedBytes: 5 * 1024 * 1024, // 5 MB
        speedBytesPerSec: 2 * 1024 * 1024, // 2 MB/s
        createdAt: DateTime.now(),
      );

      expect(task.progress, closeTo(0.5, 0.01));
      expect(task.progressPercent, 50);
      expect(task.formattedTotalSize, '10.0 MB');
      expect(task.formattedDownloadedSize, '5.0 MB');
      expect(task.formattedSpeed, '2.0 MB/s');
    });

    test('DownloadStatus getters behave as expected', () {
      expect(DownloadStatus.queued.isActive, isTrue);
      expect(DownloadStatus.downloading.isActive, isTrue);
      expect(DownloadStatus.downloading.canPause, isTrue);
      expect(DownloadStatus.paused.canResume, isTrue);
      expect(DownloadStatus.completed.isTerminal, isTrue);
      expect(DownloadStatus.failed.isTerminal, isTrue);
      expect(DownloadStatus.failed.canRetry, isTrue);
    });
  });

  group('VideoMetadata tests', () {
    test('Default file names are sanitized and formatted', () {
      const metadata = VideoMetadata(
        id: '789456',
        originalUrl: 'https://tiktok.com/@cool_user/video/789456',
        title: 'My Cool Video!',
        authorName: 'Cool User',
        authorUsername: 'cool.user:special',
        videoUrlNoWatermark: 'https://stream.mp4',
        durationSeconds: 75,
      );

      expect(metadata.formattedDuration, '1:15');
      expect(metadata.defaultVideoFileName, 'tiktok_cool_user_special_789456.mp4');
      expect(metadata.defaultAudioFileName, 'tiktok_cool_user_special_789456.mp3');
    });
  });
}
