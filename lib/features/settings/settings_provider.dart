import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/settings_repository.dart';
import '../../core/storage/storage_providers.dart';

/// Persisted theme mode preference backed by Drift SQLite.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(repo);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._repository) : super(ThemeMode.system) {
    _loadInitial();
  }

  final SettingsRepository _repository;

  Future<void> _loadInitial() async {
    final savedMode = await _repository.getThemeMode();
    state = savedMode;
  }

  Future<void> setLight() async {
    state = ThemeMode.light;
    await _repository.setThemeMode(ThemeMode.light);
  }

  Future<void> setDark() async {
    state = ThemeMode.dark;
    await _repository.setThemeMode(ThemeMode.dark);
  }

  Future<void> setSystem() async {
    state = ThemeMode.system;
    await _repository.setThemeMode(ThemeMode.system);
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    await _repository.setThemeMode(newMode);
  }
}

/// Pure Black (AMOLED) mode toggle provider.
final amoledDarkProvider = StateNotifierProvider<AmoledNotifier, bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return AmoledNotifier(repo);
});

class AmoledNotifier extends StateNotifier<bool> {
  AmoledNotifier(this._repository) : super(false) {
    _loadInitial();
  }

  final SettingsRepository _repository;

  Future<void> _loadInitial() async {
    final saved = await _repository.getAmoledDark();
    state = saved;
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    await _repository.setAmoledDark(newValue);
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await _repository.setAmoledDark(value);
  }
}

