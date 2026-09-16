import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/download_task.dart';
import 'app_database.dart';
import 'download_repository.dart';
import 'download_storage_service.dart';
import 'settings_repository.dart';

/// Database singleton provider.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Download repository provider with storage service awareness.
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final storageService = ref.watch(downloadStorageServiceProvider);
  return DownloadRepository(db, storageService);
});

/// Settings repository provider.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepository(db);
});

/// Stream of active download tasks (queued, downloading, paused, finalizing).
final activeDownloadsStreamProvider = StreamProvider<List<DownloadTask>>((ref) {
  final repo = ref.watch(downloadRepositoryProvider);
  return repo.watchActiveTasks();
});

/// Stream of completed history tasks.
final completedDownloadsStreamProvider = StreamProvider<List<DownloadTask>>((ref) {
  final repo = ref.watch(downloadRepositoryProvider);
  return repo.watchCompletedTasks();
});

/// Stream of persisted ThemeMode.
final persistedThemeModeProvider = StreamProvider<ThemeMode>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchThemeMode();
});

/// Stream of max concurrent downloads setting.
final maxConcurrentDownloadsProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchMaxConcurrentDownloads();
});

/// Stream of auto-clipboard setting.
final autoClipboardProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchAutoClipboard();
});

/// Stream of notifications enabled setting.
final notificationsEnabledProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchNotificationsEnabled();
});

/// Stream of AMOLED dark mode setting.
final amoledDarkStreamProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchAmoledDark();
});

