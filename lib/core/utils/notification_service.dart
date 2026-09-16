import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_logger.dart';

/// Manages local notifications for download completion and failure alerts.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String channelCompletedId = 'download_completed_channel';
  static const String channelCompletedName = 'TokSaver Completed';

  static const String channelFailedId = 'download_failed_channel';
  static const String channelFailedName = 'TokSaver Alerts';

  static Future<void> initialize() async {
    if (kIsWeb || _initialized || !Platform.isAndroid) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          AppLogger.d('Notification clicked with payload: ${response.payload}');
        },
      );

      _initialized = true;
      AppLogger.i('NotificationService initialized successfully.');
    } catch (e) {
      AppLogger.w('Failed to initialize NotificationService: $e');
    }
  }

  /// Show notification when a download completes.
  static Future<void> showDownloadCompleted({
    required int id,
    required String title,
    required String filePath,
  }) async {
    if (kIsWeb || !_initialized || !Platform.isAndroid) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        channelCompletedId,
        channelCompletedName,
        channelDescription: 'Notifications shown when a TokSaver download finishes',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      await _plugin.show(
        id,
        'Download Complete',
        title,
        const NotificationDetails(android: androidDetails),
        payload: filePath,
      );
    } catch (e) {
      AppLogger.w('Failed to show completed notification: $e');
    }
  }

  /// Show notification when a download fails.
  static Future<void> showDownloadFailed({
    required int id,
    required String title,
    required String error,
  }) async {
    if (kIsWeb || !_initialized || !Platform.isAndroid) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        channelFailedId,
        channelFailedName,
        channelDescription: 'Notifications shown when a TokSaver download encounters an error',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      await _plugin.show(
        id,
        'Download Failed',
        '$title: $error',
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      AppLogger.w('Failed to show failed notification: $e');
    }
  }
}
