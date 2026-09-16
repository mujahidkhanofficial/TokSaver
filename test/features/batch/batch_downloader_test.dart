import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/core/utils/url_validator.dart';

void main() {
  group('Batch Downloader URL Extraction & Deduplication Tests', () {
    test('Correctly parses newline and whitespace separated URLs', () {
      const rawInput = '''
https://www.tiktok.com/@user/video/7100000000000000001
https://vt.tiktok.com/ZS8ABCDEF/
https://vm.tiktok.com/ZMeABCDEF/
      ''';

      final lines = rawInput
          .split(RegExp(r'[\r\n\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final valid = <String>[];
      final seen = <String>{};
      int duplicates = 0;

      for (final token in lines) {
        final extracted = UrlValidator.extractFirstUrl(token) ?? token;
        if (UrlValidator.isValidTikTokUrl(extracted)) {
          final clean = UrlValidator.cleanTrackingParameters(extracted);
          if (seen.contains(clean)) {
            duplicates++;
          } else {
            seen.add(clean);
            valid.add(clean);
          }
        }
      }

      expect(valid.length, equals(3));
      expect(duplicates, equals(0));
    });

    test('Deduplicates duplicate URLs and removes tracking queries', () {
      const rawInput = '''
https://www.tiktok.com/@user/video/7100000000000000001?is_from_webapp=1
https://www.tiktok.com/@user/video/7100000000000000001?sender_device=pc
https://www.tiktok.com/@user/video/7100000000000000002
      ''';

      final lines = rawInput
          .split(RegExp(r'[\r\n\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final valid = <String>[];
      final seen = <String>{};
      int duplicates = 0;

      for (final token in lines) {
        final extracted = UrlValidator.extractFirstUrl(token) ?? token;
        if (UrlValidator.isValidTikTokUrl(extracted)) {
          final clean = UrlValidator.cleanTrackingParameters(extracted);
          if (seen.contains(clean)) {
            duplicates++;
          } else {
            seen.add(clean);
            valid.add(clean);
          }
        }
      }

      expect(valid.length, equals(2));
      expect(duplicates, equals(1));
    });

    test('Isolates invalid tokens and enforces maximum 20 limit', () {
      final lines = List.generate(25, (i) => 'https://www.tiktok.com/@user/video/71000000000000000$i');
      lines.add('https://google.com/not_tiktok');
      lines.add('invalid string here');

      final valid = <String>[];
      final invalid = <String>[];
      final seen = <String>{};

      for (final token in lines) {
        final extracted = UrlValidator.extractFirstUrl(token) ?? token;
        if (UrlValidator.isValidTikTokUrl(extracted)) {
          final clean = UrlValidator.cleanTrackingParameters(extracted);
          if (!seen.contains(clean)) {
            seen.add(clean);
            if (valid.length < 20) {
              valid.add(clean);
            }
          }
        } else {
          invalid.add(token);
        }
      }

      expect(valid.length, equals(20));
      expect(invalid.length, equals(2));
    });
  });
}
