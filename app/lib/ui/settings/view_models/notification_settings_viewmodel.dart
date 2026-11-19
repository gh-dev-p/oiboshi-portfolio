import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/notification_permission.dart';
import '../../core/view_models/guard.dart';
import '../../notification/view_models/notification_providers.dart';
import 'settings_providers.dart';

/// 通知設定（画面定義書 2.1.2）。
class NotificationSettingsState {
  const NotificationSettingsState({
    required this.permission,
    required this.enabled,
  });

  /// 端末（OS）の通知の許可の状態。
  final NotificationPermission permission;

  /// 配信開始の通知の、全体のスイッチ。
  final bool enabled;

  /// 端末（OS）の通知が許可されているか。
  bool get deviceGranted => permission == NotificationPermission.granted;
}

/// 通知設定の操作。端末の許可と、全体のスイッチ。
class NotificationSettingsViewModel
    extends AsyncNotifier<NotificationSettingsState> {
  @override
  Future<NotificationSettingsState> build() async {
    final permission = await ref
        .read(notificationRepositoryProvider)
        .permissionState();
    final settings = await ref.watch(userSettingsProvider.future);
    return NotificationSettingsState(
      permission: permission,
      enabled: settings.notificationsEnabled,
    );
  }

  /// 全体のスイッチを変える。失敗したら false。
  Future<bool> setEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return false;
    state = AsyncData(
      NotificationSettingsState(
        permission: current.permission,
        enabled: enabled,
      ),
    );
    final ok = await succeeded(() async {
      await ref
          .read(settingsRepositoryProvider)
          .setNotificationsEnabled(enabled);
      ref.invalidate(userSettingsProvider);
    });
    if (!ok && ref.mounted) state = AsyncData(current);
    return ok;
  }

  /// 「通知を許可する」。OS の許可の画面を出し、結果で表示を変える。許可されたら、通知の送り先を登録する
  /// （許可されなかったら、許可カードの代わりに注意カードを出す）。
  Future<void> requestPermission() async {
    await requestNotificationPermission(ref);
    if (ref.mounted) recheck();
  }

  /// 端末の通知の設定を開く。
  Future<void> openDeviceSettings() =>
      ref.read(notificationRepositoryProvider).openDeviceSettings();

  /// アプリが前面に戻ったときに、端末の許可を確かめ直す。許可されていれば、通知の送り先を登録し直す
  /// （機能仕様書 4.3.3。登録は、許可されているときだけ行う）。
  void recheck() {
    ref.invalidateSelf();
    ref.invalidate(pushRegistrationProvider);
  }
}

final notificationSettingsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationSettingsViewModel,
      NotificationSettingsState
    >(NotificationSettingsViewModel.new);
