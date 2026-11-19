import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../domain/models/notification_permission.dart';

/// 端末（OS）の通知の許可。
class NotificationPermissionService {
  const NotificationPermissionService();

  /// 許可されているか。
  Future<bool> isGranted() async =>
      (await Permission.notification.status).isGranted;

  /// 許可の状態。[requestedBefore] は、この端末で、アプリが許可を求めたことがあるか。
  /// iOS は、まだ求めていないとき `denied`、断ったあと `permanentlyDenied` を返す。Android 13 以上は、
  /// まだ求めていないときも、一度断ったあとも `denied` を返すので、求めたかの印で分ける。
  Future<NotificationPermission> status({required bool requestedBefore}) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return NotificationPermission.granted;
    if (status.isPermanentlyDenied) return NotificationPermission.denied;
    if (defaultTargetPlatform == TargetPlatform.iOS || !requestedBefore) {
      return NotificationPermission.notRequested;
    }
    return NotificationPermission.denied;
  }

  /// OS の許可の画面を出す。結果は許可されたか。
  Future<bool> request() async =>
      (await Permission.notification.request()).isGranted;

  /// 端末の設定アプリを開く。
  Future<bool> openSettings() => openAppSettings();
}
