import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';

/// Handles runtime permission requests across different Android API levels.
class StoragePermissionHandler {
  /// Request permissions needed for downloading and notifications.
  /// Returns true if necessary permissions are granted.
  static Future<bool> requestDownloadPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      // Notification permission is needed on Android 13+ (API 33+) for foreground service
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        final res = await Permission.notification.request();
        AppLogger.d('Notification permission requested: $res');
      }

      // Storage permission check for Android <= 9
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted && !storageStatus.isLimited) {
        final res = await Permission.storage.request();
        AppLogger.d('Storage permission requested: $res');
      }

      return true;
    } catch (e) {
      AppLogger.e('Error requesting download permissions', e);
      return true; // Still allow trying because app-specific directories require no permission
    }
  }

  /// Check if notification permission is granted.
  static Future<bool> hasNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Request notification permission explicitly (e.g. from Settings screen).
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      AppLogger.e('Failed to request notification permission: $e');
      return false;
    }
  }
}
