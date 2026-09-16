import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';
import '../utils/url_validator.dart';

/// Callback type for when a valid shared TikTok URL is extracted.
typedef SharedUrlCallback = void Function(String url);

/// Service listening to Android system share sheet intents (ACTION_SEND).
/// Handles cold starts, warm starts, and deduplicates repeated lifecycle events.
class ShareIntentService {
  static const MethodChannel _channel =
      MethodChannel('com.afridilabz.tiktok_downloader/share_intent');

  static final ShareIntentService instance = ShareIntentService._();
  ShareIntentService._();

  SharedUrlCallback? _urlCallback;
  String? _lastProcessedText;
  DateTime? _lastProcessedTime;

  /// Initialize listener for incoming system share intents.
  void initialize({required SharedUrlCallback onUrlReceived}) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _urlCallback = onUrlReceived;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedTextReceived') {
        final text = call.arguments as String?;
        if (text != null) {
          _processSharedText(text);
        }
      }
    });

    // Check cold-start intent
    _checkInitialShare();
  }

  Future<void> _checkInitialShare() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final initial = await _channel.invokeMethod<String>('getInitialSharedText');
      if (initial != null && initial.isNotEmpty) {
        AppLogger.i('Received initial cold-start share text: $initial');
        _processSharedText(initial);
      }
    } catch (e) {
      AppLogger.w('Failed to get initial shared text: $e');
    }
  }

  void _processSharedText(String rawText) {
    final now = DateTime.now();
    // Deduplication protection: Ignore duplicate intent within 3 seconds
    if (_lastProcessedText == rawText &&
        _lastProcessedTime != null &&
        now.difference(_lastProcessedTime!).inSeconds < 3) {
      AppLogger.d('Ignoring duplicate share intent event.');
      return;
    }

    _lastProcessedText = rawText;
    _lastProcessedTime = now;

    final extractedUrl = UrlValidator.extractFirstUrl(rawText);
    if (extractedUrl != null && UrlValidator.isValidTikTokUrl(extractedUrl)) {
      final cleanUrl = UrlValidator.cleanTrackingParameters(extractedUrl);
      AppLogger.i('Valid shared TikTok URL extracted: $cleanUrl');
      _urlCallback?.call(cleanUrl);
    } else {
      AppLogger.d('Shared text does not contain a recognized TikTok link: $rawText');
    }
  }
}
