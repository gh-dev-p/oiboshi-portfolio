import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/user_settings.dart';
import 'stored_setting.dart';

/// 画面モード（ライト・ダーク・端末の設定に従う）。端末内に保存する。
class DisplayModeNotifier extends StoredSetting<DisplayMode> {
  @override
  DisplayMode load(SettingsRepository repo) => repo.displayMode;

  @override
  Future<void> save(SettingsRepository repo, DisplayMode value) =>
      repo.setDisplayMode(value);

  Future<void> set(DisplayMode mode) async {
    state = mode;
    await store(mode);
  }
}

final displayModeProvider = NotifierProvider<DisplayModeNotifier, DisplayMode>(
  DisplayModeNotifier.new,
);

extension DisplayModeTheme on DisplayMode {
  ThemeMode get themeMode => switch (this) {
    DisplayMode.system => ThemeMode.system,
    DisplayMode.light => ThemeMode.light,
    DisplayMode.dark => ThemeMode.dark,
  };
}
