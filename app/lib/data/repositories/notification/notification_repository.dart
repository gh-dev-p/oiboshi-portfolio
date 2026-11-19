import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/live_notification.dart';
import '../../../domain/models/notification_permission.dart';
import '../../services/notification/device_token_service.dart';
import '../../services/notification/notification_permission_service.dart';
import '../../services/notification/push_messaging_service.dart';
import '../../services/settings/app_preferences_store.dart';

/// 端末の通知の許可と、配信開始の通知の送り先の登録、届いた通知（機能仕様書 4.3.3）。
class NotificationRepository {
  NotificationRepository(
    this._permission,
    this._push,
    this._tokens,
    this._prefs,
  );

  final NotificationPermissionService _permission;
  final PushMessagingService _push;
  final DeviceTokenService _tokens;
  final AppPreferencesStore _prefs;

  /// この起動で、サーバーに登録した送り先（FID）。
  String? _registered;

  Future<bool> isPermissionGranted() => _permission.isGranted();

  /// 許可の状態（まだ求めていない・許可・不許可）。
  Future<NotificationPermission> permissionState() => _permission.status(
    requestedBefore: _prefs.notificationPermissionRequested,
  );

  /// OS の許可の画面を出す。求めたことを、端末内に残す（Android で、まだ求めていないかを分けるため）。
  Future<bool> requestPermission() async {
    await _prefs.setNotificationPermissionRequested();
    return _permission.request();
  }

  Future<bool> openDeviceSettings() => _permission.openSettings();

  /// 通知の送り先を登録できる端末か（Firebase の接続の値がビルドに入っている）。
  bool get pushAvailable => _push.available;

  /// FCM に登録し、いまのユーザーの送り先として、サーバーに登録する。
  /// [language] は、通知の文言の言語（`ja`・`en`。i18n設計書 6.5）。
  Future<void> registerDevice(String language) async {
    if (!_push.available) return;
    await saveRegistration(await _push.register(), language);
  }

  /// FCM が送り先を変えたとき。[saveRegistration] で、サーバーに登録し直す。
  Stream<String> get registrationChanges => _push.onRegistered;

  Future<void> saveRegistration(String fid, String language) async {
    await _tokens.register(fid, _platform, language);
    _registered = fid;
  }

  /// 表示言語を変えたとき。この起動で登録した送り先を、新しい言語で登録し直す。
  /// まだ登録していなければ、何もしない。
  Future<void> updateLanguage(String language) async {
    final fid = _registered;
    if (fid == null) return;
    await saveRegistration(fid, language);
  }

  /// いまのユーザーから、この端末の登録を消す（ログアウト・ユーザーの切り替えの前）。
  Future<void> unregisterDevice() async {
    final fid = _registered;
    if (fid == null) return;
    await _tokens.delete(fid);
    _registered = null;
  }

  /// アプリが終わっていたときに、配信開始の通知を押して開いたなら、その通知。
  Future<LiveNotification?> initialOpenedNotification() async {
    final message = await _push.initialMessage();
    return message == null ? null : _toLive(message);
  }

  /// アプリが裏にいるときに、配信開始の通知を押して開いた。
  Stream<LiveNotification> get openedNotifications =>
      _push.onMessageOpenedApp.map(_toLive).where((n) => n != null).cast();

  /// アプリを開いているときに、配信開始の通知が届いた。
  Stream<LiveNotification> get foregroundNotifications =>
      _push.onMessage.map(_toLive).where((n) => n != null).cast();

  static LiveNotification? _toLive(RemoteMessage m) =>
      LiveNotification.fromMessage(
        m.data,
        title: m.notification?.title,
        body: m.notification?.body,
      );

  static String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}
