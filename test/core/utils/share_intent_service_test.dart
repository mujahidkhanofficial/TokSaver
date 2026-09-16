import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/core/utils/url_validator.dart';

void main() {
  group('Share Intent Parsing & URL Extraction Tests', () {
    test('Extracts valid TikTok link from complex share text', () {
      const shareText = '''
Check out this amazing video! https://vm.tiktok.com/ZM8abc123/ sent via TikTok app.
      ''';

      final extracted = UrlValidator.extractFirstUrl(shareText);
      expect(extracted, isNotNull);
      expect(UrlValidator.isValidTikTokUrl(extracted!), isTrue);
      expect(UrlValidator.cleanTrackingParameters(extracted), equals('https://vm.tiktok.com/ZM8abc123/'));
    });

    test('Ignores non-TikTok share text', () {
      const shareText = 'Look at this photo: https://instagram.com/p/Cxyz123/';
      final extracted = UrlValidator.extractFirstUrl(shareText);
      expect(extracted, isNotNull);
      expect(UrlValidator.isValidTikTokUrl(extracted!), isFalse);
    });

    test('Handles raw URL share directly without extra text', () {
      const rawUrl = 'https://www.tiktok.com/@creator/video/7100000000000000000';
      final extracted = UrlValidator.extractFirstUrl(rawUrl);
      expect(extracted, equals(rawUrl));
      expect(UrlValidator.isValidTikTokUrl(extracted!), isTrue);
    });
  });
}
