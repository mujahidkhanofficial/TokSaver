import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/shared/models/download_task.dart';

void main() {
  group('Picture-in-Picture & Media Task Model Tests', () {
    test('Identifies video vs audio tasks for PiP vs Ringtone actions', () {
      final videoTask = DownloadTask(
        id: 'task_video_1',
        url: 'https://www.tiktok.com/@user/video/123456789',
        title: 'Dance Challenge',
        author: 'User',
        targetFilePath: 'Dance_Challenge.mp4',
        fileName: 'Dance_Challenge.mp4',
        storageType: 'media_store',
        storageUri: 'content://media/external/video/media/100',
        mimeType: 'video/mp4',
        isAudioOnly: false,
        createdAt: DateTime.now(),
      );

      final audioTask = DownloadTask(
        id: 'task_audio_1',
        url: 'https://www.tiktok.com/@user/video/123456789',
        title: 'Dance Sound',
        author: 'User',
        targetFilePath: 'Dance_Sound.mp3',
        fileName: 'Dance_Sound.mp3',
        storageType: 'media_store',
        storageUri: 'content://media/external/audio/media/200',
        mimeType: 'audio/mpeg',
        isAudioOnly: true,
        createdAt: DateTime.now(),
      );

      expect(videoTask.isAudioOnly, isFalse);
      expect(videoTask.mimeType, equals('video/mp4'));
      expect(videoTask.canonicalUri, equals('content://media/external/video/media/100'));

      expect(audioTask.isAudioOnly, isTrue);
      expect(audioTask.mimeType, equals('audio/mpeg'));
      expect(audioTask.canonicalUri, equals('content://media/external/audio/media/200'));
    });
  });
}
