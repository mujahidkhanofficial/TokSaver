import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_logger.dart';

/// Bridge service for native Android Picture-in-Picture and Audio/Ringtone utilities.
class PipService {
  static const MethodChannel _pipChannel =
      MethodChannel('com.afridilabz.tiktok_downloader/pip');
  static const MethodChannel _audioChannel =
      MethodChannel('com.afridilabz.tiktok_downloader/audio_utility');

  static final PipService instance = PipService._();

  final StreamController<bool> _pipStreamController =
      StreamController<bool>.broadcast();

  PipService._() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _pipChannel.setMethodCallHandler((call) async {
        if (call.method == 'onPipModeChanged') {
          final isInPip = call.arguments as bool? ?? false;
          AppLogger.i('Native PiP mode changed: isInPip = $isInPip');
          _pipStreamController.add(isInPip);
        }
      });
    }
  }

  /// Stream of Picture-in-Picture mode change events.
  Stream<bool> get onPipModeChanged => _pipStreamController.stream;

  /// Check if device supports Picture-in-Picture.
  Future<bool> isPipSupported() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final supported = await _pipChannel.invokeMethod<bool>('isPipSupported');
      return supported ?? false;
    } catch (e) {
      AppLogger.w('isPipSupported error: $e');
      return false;
    }
  }

  /// Enter native Android Picture-in-Picture mode with given aspect ratio.
  Future<bool> enterPictureInPicture({
    int numerator = 9,
    int denominator = 16,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final entered = await _pipChannel.invokeMethod<bool>(
        'enterPictureInPicture',
        {
          'numerator': numerator,
          'denominator': denominator,
        },
      );
      return entered ?? false;
    } catch (e) {
      AppLogger.w('Failed to enter Picture-in-Picture: $e');
      return false;
    }
  }

  /// Opens the system ringtone chooser/setter for the given audio content URI.
  Future<bool> setAsRingtone({
    required String uri,
    required String title,
    String? mimeType,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final success = await _audioChannel.invokeMethod<bool>(
        'setAsRingtone',
        {
          'uri': uri,
          'title': title,
        },
      );
      return success ?? false;
    } catch (e) {
      AppLogger.w('Failed to set ringtone: $e');
      return false;
    }
  }
}
