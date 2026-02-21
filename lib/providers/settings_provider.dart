import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/models/settings.dart';
import 'package:sudoku_app/services/storage_service.dart';

// ---------------------------------------------------------------------------
// Settings notifier
// ---------------------------------------------------------------------------

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(StorageService.loadSettings());

  void toggleDarkMode() {
    // When manually toggling dark mode, disable follow system
    state = state.copyWith(isDarkMode: !state.isDarkMode, followSystem: false);
    _save();
  }

  void toggleFollowSystem() {
    state = state.copyWith(followSystem: !state.followSystem);
    _save();
  }

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    _save();
  }

  void toggleHaptic() {
    state = state.copyWith(hapticEnabled: !state.hapticEnabled);
    _save();
  }

  void toggleTimer() {
    state = state.copyWith(showTimer: !state.showTimer);
    _save();
  }

  void setMistakeLimit(int limit) {
    state = state.copyWith(mistakeLimit: limit);
    _save();
  }

  void toggleAutoRemoveNotes() {
    state = state.copyWith(autoRemoveNotes: !state.autoRemoveNotes);
    _save();
  }

  void toggleHighlightIdentical() {
    state = state.copyWith(highlightIdentical: !state.highlightIdentical);
    _save();
  }

  void toggleHighlightConflicts() {
    state = state.copyWith(highlightConflicts: !state.highlightConflicts);
    _save();
  }

  void setAccentColor(int index) {
    state = state.copyWith(accentColorIndex: index);
    _save();
  }

  void setLocale(String locale) {
    state = state.copyWith(locale: locale);
    _save();
  }

  void _save() {
    StorageService.saveSettings(state);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
