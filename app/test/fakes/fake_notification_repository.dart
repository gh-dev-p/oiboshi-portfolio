import 'dart:async';

import 'package:oiboshi/data/repositories/notification/notification_repository.dart';
import 'package:oiboshi/domain/models/live_notification.dart';
import 'package:oiboshi/domain/models/notification_permission.dart';

class FakeNotificationRepository implements NotificationRepository {
  bool granted = true;
  int requests = 0;

  /// サーバーに登録した送り先。
  final registered = <String>[];

  /// 登録を消した回数。
  int unregisters = 0;

  /// 次に FCM が返す送り先。
  String fid = 'fid-1';

  final _registrationChanges = StreamController<String>.broadcast();
  final _opened = StreamController<LiveNotification>.broadcast();
  final _foreground = StreamController<LiveNotification>.broadcast();
  LiveNotification? initialOpened;

  /// FCM が送り先を変えた。
  void changeRegistration(String next) => _registrationChanges.add(next);

  /// 通知を押して開いた（アプリが裏にいた）。
  void openNotification(LiveNotification n) => _opened.add(n);

  /// アプリを開いているときに届いた。
  void receiveNotification(LiveNotification n) => _foreground.add(n);

  /// 許可を求めたことがあるか。許可されていないとき、まだ求めていないか・断ったあとかを分ける。
  bool requestedBefore = true;

  /// OS の許可の画面で、許可するか（[requestPermission] で [granted] になる）。
  bool grantOnRequest = false;

  /// サーバーに登録した送り先の言語（[registered] と同じ順）。
  final registeredLanguages = <String>[];

  /// この起動で登録した送り先。
  String? _registered;

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<NotificationPermission> permissionState() async => granted
      ? NotificationPermission.granted
      : requestedBefore
      ? NotificationPermission.denied
      : NotificationPermission.notRequested;

  @override
  Future<bool> requestPermission() async {
    requests++;
    requestedBefore = true;
    if (grantOnRequest) granted = true;
    return granted;
  }

  @override
  Future<bool> openDeviceSettings() async => true;

  @override
  bool pushAvailable = true;

  @override
  Future<void> registerDevice(String language) =>
      saveRegistration(fid, language);

  @override
  Stream<String> get registrationChanges => _registrationChanges.stream;

  @override
  Future<void> saveRegistration(String fid, String language) async {
    registered.add(fid);
    registeredLanguages.add(language);
    _registered = fid;
  }

  @override
  Future<void> updateLanguage(String language) async {
    final fid = _registered;
    if (fid != null) await saveRegistration(fid, language);
  }

  @override
  Future<void> unregisterDevice() async {
    unregisters++;
    _registered = null;
  }

  @override
  Future<LiveNotification?> initialOpenedNotification() async {
    final n = initialOpened;
    initialOpened = null;
    return n;
  }

  @override
  Stream<LiveNotification> get openedNotifications => _opened.stream;

  @override
  Stream<LiveNotification> get foregroundNotifications => _foreground.stream;
}
