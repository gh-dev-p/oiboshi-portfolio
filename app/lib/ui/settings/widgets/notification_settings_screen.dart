import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/notification_permission.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../view_models/notification_settings_viewmodel.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 通知設定（画面定義書 2.1.2）。配信開始の通知をオン・オフする。
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 端末の設定から戻ってきたら、許可を確かめ直す。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationSettingsViewModelProvider.notifier).recheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(notificationSettingsViewModelProvider.notifier);
    final state = ref.watch(notificationSettingsViewModelProvider);
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.settingsNotificationSettingsTitle),
      body: state.when(
        skipLoadingOnRefresh: true,
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 160),
              SizedBox(height: 10),
              SkeletonLine(width: 240, height: 10),
            ],
          ),
        ),
        error: (_, _) => StateView.error(onRetry: vm.recheck),
        data: (s) => ListView(
          children: [
            // 許可を一度も求めていなければ許可カード、断ったあとなら注意カード（端末の設定へ）。
            switch (s.permission) {
              NotificationPermission.notRequested => _PermissionCard(
                icon: Icons.notifications_active_outlined,
                iconColor: c.primary,
                message: l10n.settingsNotificationPermissionPrompt,
                actionLabel: l10n.settingsAllowNotifications,
                onAction: vm.requestPermission,
              ),
              NotificationPermission.denied => _PermissionCard(
                icon: Icons.notifications_off,
                iconColor: c.live,
                message: l10n.settingsDeviceNotificationsOff,
                actionLabel: l10n.settingsOpenDeviceSettings,
                onAction: vm.openDeviceSettings,
              ),
              NotificationPermission.granted => const SizedBox.shrink(),
            },
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsLiveStartNotification,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.settingsLiveStartNotificationDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppSwitch(
                    value: s.enabled,
                    onChanged: (v) async {
                      if (!await vm.setEnabled(v) && context.mounted) {
                        showAppSnackBar(
                          context,
                          l10n.commonNotificationSettingChangeFailed,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.settingsPerCreatorNotificationNote,
                style: context.textStyles.hint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 通知の許可のカード（許可カード・注意カード）。一番上に出す。アイコンと案内と、テキストボタン。
class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 24, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(fontSize: 14, color: c.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AppTextButton(label: actionLabel, onPressed: onAction),
            ),
          ],
        ),
      ),
    );
  }
}
