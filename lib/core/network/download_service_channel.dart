import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Dart wrapper communicating with Android's native DownloadService ForegroundService.
class DownloadServiceChannel {
  static const MethodChannel _channel =
      MethodChannel(AppConstants.downloadServiceChannel);

  static bool _isRunning = false;
  static bool get isRunning => _isRunning;

  /// Start foreground service on Android with initial notification.
  static Future<void> startService({required String title}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startService', {'title': title});
      _isRunning = true;
    } catch (e) {
      AppLogger.w('Failed to start native download foreground service: $e');
    }
  }

  /// Update native ongoing notification with progress and status text.
  static Future<void> updateProgress({
    required String title,
    required String text,
    required int progress,
  }) async {
    if (kIsWeb || !Platform.isAndroid || !_isRunning) return;
    try {
      await _channel.invokeMethod('updateProgress', {
        'title': title,
        'text': text,
        'progress': progress,
      });
    } catch (e) {
      AppLogger.w('Failed to update native download notification: $e');
    }
  }

  /// Stop native foreground service.
  static Future<void> stopService() async {
    if (kIsWeb || !Platform.isAndroid || !_isRunning) return;
    try {
      await _channel.invokeMethod('stopService');
      _isRunning = false;
    } catch (e) {
      AppLogger.w('Failed to stop native download service: $e');
    }
  }
}
