import 'package:flutter/material.dart';
import 'app_database.dart';

/// Repository for persisting and streaming application user settings.
class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;
  SettingsDao get _dao => _database.settingsDao;

  // Setting keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyAmoledDark = 'amoled_dark';
  static const String keyMaxConcurrentDownloads = 'max_concurrent_downloads';
  static const String keyAutoClipboard = 'auto_clipboard';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keySaveLocation = 'save_location';
  static const String keyCustomApiUrl = 'custom_api_url';

  // ── Theme Mode ─────────────────────────────────────────────────────────────
  Stream<ThemeMode> watchThemeMode() {
    return _dao.watchSetting(keyThemeMode).map((val) {
      if (val == 'light') return ThemeMode.light;
      if (val == 'dark') return ThemeMode.dark;
      return ThemeMode.system;
    });
  }

  Future<ThemeMode> getThemeMode() async {
    final val = await _dao.getSetting(keyThemeMode);
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _dao.setSetting(keyThemeMode, mode.name);
  }

  // ── AMOLED Dark Mode ───────────────────────────────────────────────────────
  Stream<bool> watchAmoledDark() {
    return _dao.watchSetting(keyAmoledDark).map((val) => val == 'true');
  }

  Future<bool> getAmoledDark() async {
    final val = await _dao.getSetting(keyAmoledDark);
    return val == 'true';
  }

  Future<void> setAmoledDark(bool enabled) async {
    await _dao.setSetting(keyAmoledDark, enabled.toString());
  }

  // ── Concurrent Downloads ───────────────────────────────────────────────────
  Stream<int> watchMaxConcurrentDownloads() {
    return _dao.watchSetting(keyMaxConcurrentDownloads).map((val) {
      return int.tryParse(val ?? '1') ?? 1;
    });
  }

  Future<int> getMaxConcurrentDownloads() async {
    final val = await _dao.getSetting(keyMaxConcurrentDownloads);
    return int.tryParse(val ?? '1') ?? 1;
  }

  Future<void> setMaxConcurrentDownloads(int count) async {
    final clamped = count.clamp(1, 3);
    await _dao.setSetting(keyMaxConcurrentDownloads, clamped.toString());
  }

  // ── Auto Clipboard Detection ──────────────────────────────────────────────
  Stream<bool> watchAutoClipboard() {
    return _dao.watchSetting(keyAutoClipboard).map((val) => val != 'false');
  }

  Future<bool> getAutoClipboard() async {
    final val = await _dao.getSetting(keyAutoClipboard);
    return val != 'false';
  }

  Future<void> setAutoClipboard(bool enabled) async {
    await _dao.setSetting(keyAutoClipboard, enabled.toString());
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  Stream<bool> watchNotificationsEnabled() {
    return _dao.watchSetting(keyNotificationsEnabled).map((val) => val != 'false');
  }

  Future<bool> getNotificationsEnabled() async {
    final val = await _dao.getSetting(keyNotificationsEnabled);
    return val != 'false';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _dao.setSetting(keyNotificationsEnabled, enabled.toString());
  }

  // ── Custom Save Location ───────────────────────────────────────────────────
  Stream<String?> watchSaveLocation() {
    return _dao.watchSetting(keySaveLocation);
  }

  Future<String?> getSaveLocation() async {
    return await _dao.getSetting(keySaveLocation);
  }

  Future<void> setSaveLocation(String? path) async {
    if (path == null || path.isEmpty) {
      await _dao.deleteSetting(keySaveLocation);
    } else {
      await _dao.setSetting(keySaveLocation, path);
    }
  }

  // ── Custom API Endpoint ───────────────────────────────────────────────────
  Future<String?> getCustomApiUrl() async {
    return await _dao.getSetting(keyCustomApiUrl);
  }

  Future<void> setCustomApiUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _dao.deleteSetting(keyCustomApiUrl);
    } else {
      await _dao.setSetting(keyCustomApiUrl, url.trim());
    }
  }
}
