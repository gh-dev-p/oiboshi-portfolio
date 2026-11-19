import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/enum_name.dart';
import '../../../domain/models/login_method.dart';
import '../../../domain/models/user_settings.dart';

/// 端末内の保存領域。初回起動の完了と、初回起動の引き継ぎでクリップボードを確かめたかと、画面モードと、表示言語と、通知の許可を求めたかと、固定ビューアのスイッチをユーザーが切ったかと、固定ビューアで最後に流していたもの。
class AppPreferencesStore {
  AppPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingDoneKey = 'onboardingDone';
  static const _clipboardLinkCheckedKey = 'clipboardLinkChecked';
  static const _displayModeKey = 'displayMode';
  static const _appLanguageKey = 'appLanguage';
  static const _notificationPermissionRequestedKey =
      'notificationPermissionRequested';
  static const _fixedViewerUserOffKey = 'fixedViewerUserOff';
  static const _lastPlaybackKey = 'fixedViewerLastPlayback';
  static const _passwordLoginFailuresKey = 'passwordLoginFailures';
  static const _passwordLoginLockedUntilKey = 'passwordLoginLockedUntil';
  static const _announceTemplateKey = 'announceTemplate';

  bool get onboardingDone => _prefs.getBool(_onboardingDoneKey) ?? false;

  /// 週間の告知画像で選んだテンプレの ID（届ける・広める仕様書 4.4.1）。選んでいなければ null。
  String? get announceTemplateId => _prefs.getString(_announceTemplateKey);

  Future<void> setAnnounceTemplateId(String id) =>
      _prefs.setString(_announceTemplateKey, id);

  Future<void> setOnboardingDone(bool done) =>
      _prefs.setBool(_onboardingDoneKey, done);

  /// 初回起動の引き継ぎで、クリップボードを確かめたか（1回だけ確かめる。届ける・広める仕様書 4.3.4）。
  bool get clipboardLinkChecked =>
      _prefs.getBool(_clipboardLinkCheckedKey) ?? false;

  Future<void> setClipboardLinkChecked() =>
      _prefs.setBool(_clipboardLinkCheckedKey, true);

  DisplayMode get displayMode =>
      DisplayMode.values.byNameOrNull(_prefs.getString(_displayModeKey)) ??
      DisplayMode.system;

  Future<void> setDisplayMode(DisplayMode mode) =>
      _prefs.setString(_displayModeKey, mode.name);

  AppLanguage get appLanguage =>
      AppLanguage.values.byNameOrNull(_prefs.getString(_appLanguageKey)) ??
      AppLanguage.system;

  Future<void> setAppLanguage(AppLanguage language) =>
      _prefs.setString(_appLanguageKey, language.name);

  /// この端末で、アプリが通知の許可を求めたことがあるか（OS の許可の画面を出したか）。
  bool get notificationPermissionRequested =>
      _prefs.getBool(_notificationPermissionRequestedKey) ?? false;

  Future<void> setNotificationPermissionRequested() =>
      _prefs.setBool(_notificationPermissionRequestedKey, true);

  /// ユーザーが固定ビューアのスイッチを切ったか（機能仕様書 4.3.5）。切っていれば、開き直しても切ったままにする。
  /// 推しが0人のために自動で切ったときは、記録しない。
  bool get fixedViewerUserOff =>
      _prefs.getBool(_fixedViewerUserOffKey) ?? false;

  Future<void> setFixedViewerUserOff(bool off) =>
      _prefs.setBool(_fixedViewerUserOffKey, off);

  /// 固定ビューアで最後に流していたもの（[LastPlayback] の文字列。機能仕様書 4.3.5）。
  String? get lastPlayback => _prefs.getString(_lastPlaybackKey);

  Future<void> setLastPlayback(String? value) => value == null
      ? _prefs.remove(_lastPlaybackKey)
      : _prefs.setString(_lastPlaybackKey, value);

  /// アプリ運営用ログインの、端末の回数の制限（機能仕様書 4.1.4）。
  PasswordLoginLock get passwordLoginLock {
    final until = _prefs.getInt(_passwordLoginLockedUntilKey);
    return PasswordLoginLock(
      failures: _prefs.getInt(_passwordLoginFailuresKey) ?? 0,
      lockedUntil: until == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(until, isUtc: true),
    );
  }

  Future<void> setPasswordLoginLock(PasswordLoginLock lock) async {
    await _prefs.setInt(_passwordLoginFailuresKey, lock.failures);
    final until = lock.lockedUntil;
    if (until == null) {
      await _prefs.remove(_passwordLoginLockedUntilKey);
    } else {
      await _prefs.setInt(
        _passwordLoginLockedUntilKey,
        until.millisecondsSinceEpoch,
      );
    }
  }

  /// 退会で、端末内の保存をすべて消す。
  Future<void> clear() => _prefs.clear();
}
