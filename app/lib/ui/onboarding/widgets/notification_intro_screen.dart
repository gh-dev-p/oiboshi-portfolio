import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../view_models/notification_intro_viewmodel.dart';
import 'welcome_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/one_line_text.dart';

/// 通知の説明（画面定義書 2.1.3）。通知の許可を求める理由を説明してから、OS の許可の画面を出す。
class NotificationIntroScreen extends ConsumerStatefulWidget {
  const NotificationIntroScreen({super.key});

  @override
  ConsumerState<NotificationIntroScreen> createState() =>
      _NotificationIntroScreenState();
}

class _NotificationIntroScreenState
    extends ConsumerState<NotificationIntroScreen> {
  /// どちらかのボタンを押してから、ホームへ進むまで。連打で、許可の要求や画面を閉じる処理を2回走らせない。
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    // 作り直す前（同じフレームの中）に、続けて押されたときも弾く。
    if (_busy) return;
    setState(() => _busy = true);
    await action();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(notificationIntroViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _NotificationPreview(),
                      const SizedBox(height: 36),
                      const OnboardingIllustration(icon: Icons.notifications),
                      const SizedBox(height: 24),
                      Text(
                        l10n.onboardingNotificationTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          height: 32 / 22,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.onboardingNotificationMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 22 / 14,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  OnboardingPrimaryButton(
                    label: l10n.onboardingNotificationEnable,
                    onPressed: _busy
                        ? null
                        : () => _run(vm.requestNotification),
                  ),
                  const SizedBox(height: 4),
                  AppTextButton(
                    label: l10n.onboardingNotificationSkip,
                    color: c.textSecondary,
                    onPressed: _busy ? null : () => _run(vm.skipNotification),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 通知の見本カード。
class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? c.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A33).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.star, size: 22, color: c.onPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboardingNotificationSampleTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                OneLineText(
                  l10n.onboardingNotificationSampleBody,
                  style: context.textStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
