import '../constants/app_constants.dart';

/// Utility to validate, extract, and clean TikTok URLs.
abstract final class UrlValidator {
  /// Regular expression to match URLs inside a copied text string.
  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s<>"{}|\\^`]+',
    caseSensitive: false,
  );

  /// Check whether a string is or contains a valid TikTok URL.
  static bool isValidTikTokUrl(String input) {
    final clean = extractFirstUrl(input);
    if (clean == null) return false;

    try {
      final uri = Uri.parse(clean);
      final host = uri.host.toLowerCase();
      return AppConstants.tiktokHosts.any(
        (allowedHost) => host == allowedHost || host.endsWith('.$allowedHost'),
      );
    } catch (_) {
      return false;
    }
  }

  /// Extracts the first URL from a given text (handles "Look at this: https://vt.tiktok.com/...").
  static String? extractFirstUrl(String text) {
    final match = _urlRegex.firstMatch(text.trim());
    if (match == null) return null;
    var url = match.group(0);
    if (url == null) return null;

    // Clean trailing punctuation
    url = url.replaceAll(RegExp(r'[.,;!?)>]+$'), '');
    return url;
  }

  /// Clean tracking parameters from TikTok URL for privacy and caching consistency.
  static String cleanTrackingParameters(String url) {
    try {
      final uri = Uri.parse(url);
      // Strip common analytics parameters like is_from_webapp, sender_device, etc.
      final filteredQuery = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((key, _) =>
            key.startsWith('utm_') ||
            key == 'is_from_webapp' ||
            key == 'sender_device' ||
            key == 'u_code' ||
            key == 'share_app_id');

      if (filteredQuery.isEmpty) {
        return uri.replace(query: '').toString().replaceAll(RegExp(r'\?$'), '');
      } else {
        return uri.replace(queryParameters: filteredQuery).toString();
      }
    } catch (_) {
      return url;
    }
  }
}
