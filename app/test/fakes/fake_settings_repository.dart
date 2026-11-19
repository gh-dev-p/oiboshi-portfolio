import 'dart:async';

import 'package:oiboshi/data/repositories/settings/settings_repository.dart';
import 'package:oiboshi/domain/models/last_playback.dart';
import 'package:oiboshi/domain/models/user_settings.dart';

import 'fake_data.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository(this.data);

  final FakeData data;

  @override
  Future<UserSettings> fetchUserSettings() async {
    data.check();
    return data.settings;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    data.settings = UserSettings(notificationsEnabled: enabled);
  }

  @override
  bool get onboardingDone => data.onboardingDone;

  @override
  Future<void> setOnboardingDone() async {
    if (data.failOnboardingSave) throw Exception('保存できない');
    data.onboardingDone = true;
  }

  @override
  bool get clipboardLinkChecked => data.clipboardLinkChecked;

  @override
  Future<void> setClipboardLinkChecked() async {
    data.clipboardLinkChecked = true;
  }

  @override
  DisplayMode get displayMode => data.displayMode;

  @override
  Future<void> setDisplayMode(DisplayMode mode) async =>
      data.displayMode = mode;

  @override
  bool get fixedViewerUserOff => data.fixedViewerUserOff;

  @override
  Future<void> setFixedViewerUserOff(bool off) async =>
      data.fixedViewerUserOff = off;

  @override
  LastPlayback? get lastPlayback => data.lastPlayback;

  @override
  Future<void> setLastPlayback(LastPlayback? value) async =>
      data.lastPlayback = value;

  @override
  AppLanguage get appLanguage => data.appLanguage;

  @override
  Future<void> setAppLanguage(AppLanguage language) async =>
      data.appLanguage = language;

  @override
  Future<String> appVersion() async => '1.0.0 (1)';

  @override
  String osName() => 'test';
}
