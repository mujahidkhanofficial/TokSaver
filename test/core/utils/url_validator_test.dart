import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/core/utils/url_validator.dart';

void main() {
  group('UrlValidator tests', () {
    test('Identifies valid TikTok URLs', () {
      expect(UrlValidator.isValidTikTokUrl('https://www.tiktok.com/@user/video/123456789'), isTrue);
      expect(UrlValidator.isValidTikTokUrl('https://vm.tiktok.com/ZM8v1234/'), isTrue);
      expect(UrlValidator.isValidTikTokUrl('https://vt.tiktok.com/ZS8v1234/'), isTrue);
      expect(UrlValidator.isValidTikTokUrl('https://m.tiktok.com/v/1234.html'), isTrue);
      expect(
        UrlValidator.isValidTikTokUrl('Check this out: https://vt.tiktok.com/ZS8v1234/ and tell me!'),
        isTrue,
      );
    });

    test('Rejects invalid or non-TikTok URLs', () {
      expect(UrlValidator.isValidTikTokUrl('https://youtube.com/watch?v=123'), isFalse);
      expect(UrlValidator.isValidTikTokUrl('https://instagram.com/p/123'), isFalse);
      expect(UrlValidator.isValidTikTokUrl('random text with no link'), isFalse);
      expect(UrlValidator.isValidTikTokUrl(''), isFalse);
    });

    test('Extracts first URL from dirty text', () {
      const text = 'Hey watch this https://vm.tiktok.com/ZM8v1234/! So cool';
      final extracted = UrlValidator.extractFirstUrl(text);
      expect(extracted, 'https://vm.tiktok.com/ZM8v1234/');
    });

    test('Cleans tracking parameters', () {
      const dirty = 'https://www.tiktok.com/@user/video/123?is_from_webapp=1&sender_device=pc&utm_source=share';
      final cleaned = UrlValidator.cleanTrackingParameters(dirty);
      expect(cleaned, 'https://www.tiktok.com/@user/video/123');
    });
  });
}
