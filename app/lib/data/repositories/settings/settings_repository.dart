import '../../../domain/models/last_playback.dart';
import '../../../domain/models/user_settings.dart';
import '../../services/settings/app_info_service.dart';
import '../../services/settings/app_preferences_store.dart';
import '../../services/settings/user_settings_service.dart';
import '../common/error_mapping.dart';

/// ユーザーの設定（サーバーの通知の設定と、端末内の設定）。
class SettingsRepository {
  SettingsRepository(this._settings, this._prefs, this._appInfo);

  final UserSettingsService _settings;
  final AppPreferencesStore _prefs;
  final AppInfoService _appInfo;

  Future<UserSettings> fetchUserSettings() => mapErrors(() async {
    final row = await _settings.fetch();
    return row == null ? const UserSettings() : UserSettings.fromRow(row);
  });

  Future<void> setNotificationsEnabled(bool enabled) =>
      mapErrors(() => _settings.save(enabled));

  bool get onboardingDone => _prefs.onboardingDone;

  Future<void> setOnboardingDone() => _prefs.setOnboardingDone(true);

  /// 初回起動の引き継ぎで、クリップボードを確かめたか（1回だけ確かめる）。
  bool get clipboardLinkChecked => _prefs.clipboardLinkChecked;

  Future<void> setClipboardLinkChecked() => _prefs.setClipboardLinkChecked();

  DisplayMode get displayMode => _prefs.displayMode;

  Future<void> setDisplayMode(DisplayMode mode) => _prefs.setDisplayMode(mode);

  bool get fixedViewerUserOff => _prefs.fixedViewerUserOff;

  Future<void> setFixedViewerUserOff(bool off) =>
      _prefs.setFixedViewerUserOff(off);

  /// 固定ビューアで最後に流していたもの。覚えていなければ null。
  LastPlayback? get lastPlayback => LastPlayback.decode(_prefs.lastPlayback);

  Future<void> setLastPlayback(LastPlayback? value) =>
      _prefs.setLastPlayback(value?.encode());

  AppLanguage get appLanguage => _prefs.appLanguage;

  Future<void> setAppLanguage(AppLanguage language) =>
      _prefs.setAppLanguage(language);

  Future<String> appVersion() => _appInfo.appVersion();

  String osName() => _appInfo.osName();
}
