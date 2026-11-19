import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/view_models/settings_providers.dart';
import 'onboarding_providers.dart';

/// 通知の説明（画面定義書 2.1.3）の操作。どちらを選んでも、初回起動を済みにする。
class NotificationIntroViewModel extends Notifier<void> {
  @override
  void build() {}

  /// 「通知をオンにする」。OS の許可の画面を出す。結果にかかわらずホームへ進む。
  Future<void> requestNotification() async {
    await requestNotificationPermission(ref);
    await ref.read(onboardingDoneProvider.notifier).complete();
  }

  /// 「いまはしない」。
  Future<void> skipNotification() =>
      ref.read(onboardingDoneProvider.notifier).complete();
}

final notificationIntroViewModelProvider =
    NotifierProvider<NotificationIntroViewModel, void>(
      NotificationIntroViewModel.new,
    );
