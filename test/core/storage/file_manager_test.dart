import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/core/storage/file_manager.dart';

void main() {
  group('FileManager filename sanitization & security tests', () {
    test('sanitizeFileName removes illegal filesystem characters', () {
      const input = 'video:title/with?illegal*chars<and>pipes|quotes".mp4';
      final sanitized = FileManager.sanitizeFileName(input);

      expect(sanitized.contains(':'), isFalse);
      expect(sanitized.contains('/'), isFalse);
      expect(sanitized.contains('?'), isFalse);
      expect(sanitized.contains('*'), isFalse);
      expect(sanitized.contains('<'), isFalse);
      expect(sanitized.contains('>'), isFalse);
      expect(sanitized.contains('|'), isFalse);
      expect(sanitized.contains('"'), isFalse);
    });

    test('sanitizeFileName prevents directory traversal attacks', () {
      const traversal1 = '../../../etc/passwd.mp4';
      final sanitized1 = FileManager.sanitizeFileName(traversal1);
      expect(sanitized1.contains('..'), isFalse);
      expect(sanitized1.contains('/'), isFalse);

      const traversal2 = r'..\..\Windows\System32\cmd.exe';
      final sanitized2 = FileManager.sanitizeFileName(traversal2);
      expect(sanitized2.contains('..'), isFalse);
      expect(sanitized2.contains(r'\'), isFalse);
    });

    test('sanitizeFileName sanitizes Windows/Android reserved device names', () {
      expect(FileManager.sanitizeFileName('CON.mp4'), 'CON_file.mp4');
      expect(FileManager.sanitizeFileName('prn.mp4'), 'prn_file.mp4');
      expect(FileManager.sanitizeFileName('aux.mp4'), 'aux_file.mp4');
      expect(FileManager.sanitizeFileName('nul.mp4'), 'nul_file.mp4');
      expect(FileManager.sanitizeFileName('com1.mp4'), 'com1_file.mp4');
      expect(FileManager.sanitizeFileName('lpt1.mp4'), 'lpt1_file.mp4');
    });

    test('sanitizeFileName handles empty and whitespace-only strings', () {
      final sanitized = FileManager.sanitizeFileName('   ', defaultName: 'fallback_name');
      expect(sanitized, 'fallback_name');
    });

    test('sanitizeFileName strips trailing dots and spaces from stem', () {
      final sanitized = FileManager.sanitizeFileName('my video... .mp4');
      expect(sanitized, 'my video.mp4');
    });

    test('sanitizeFileName preserves Unicode and emojis safely', () {
      const input = 'TikTok 🎵 Viral Dance ✨ 2026.mp4';
      final sanitized = FileManager.sanitizeFileName(input);
      expect(sanitized, 'TikTok 🎵 Viral Dance ✨ 2026.mp4');
    });

    test('sanitizeFileName applies extensionOverride correctly', () {
      final sanitized = FileManager.sanitizeFileName(
        'music_track.unknown',
        extensionOverride: '.mp3',
      );
      expect(sanitized, 'music_track.mp3');
    });
  });

  group('FileManager MIME & extension resolution tests', () {
    test('resolveMimeType maps video and audio extensions', () {
      expect(FileManager.resolveMimeType('video.mp4'), 'video/mp4');
      expect(FileManager.resolveMimeType('clip.webm'), 'video/webm');
      expect(FileManager.resolveMimeType('song.mp3'), 'audio/mpeg');
      expect(FileManager.resolveMimeType('audio.m4a'), 'audio/mp4');
      expect(FileManager.resolveMimeType('unknown_file', isAudio: true), 'audio/mpeg');
      expect(FileManager.resolveMimeType('unknown_file', isAudio: false), 'video/mp4');
    });

    test('resolveExtension maps MIME types to extensions', () {
      expect(FileManager.resolveExtension('video/mp4'), '.mp4');
      expect(FileManager.resolveExtension('audio/mpeg'), '.mp3');
      expect(FileManager.resolveExtension('audio/mp4'), '.m4a');
      expect(FileManager.resolveExtension('video/webm'), '.webm');
    });
  });
}
