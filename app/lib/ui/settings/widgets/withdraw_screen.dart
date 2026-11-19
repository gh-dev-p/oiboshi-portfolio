import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/subscription_management.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/withdraw_viewmodel.dart';
import 'reauth_sheet.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 退会（画面定義書 2.1.4）。データを削除して、退会する。
class WithdrawScreen extends ConsumerWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(withdrawViewModelProvider);
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.settingsWithdraw),
      // 案内が増えても、ボタンまで届くようにスクロールできる。
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: Column(
          children: [
            Text(
              l10n.settingsWithdrawWarning,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 24 / 15,
                color: c.textPrimary,
              ),
            ),
            // 発信者のオーナーは、発信者が90日残り、取り戻せる（機能仕様書 4.1.3）。
            if (state.ownsCreator) ...[
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.settingsWithdrawCreatorNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  color: c.textSecondary,
                ),
              ),
            ],
            // Apple のひも付けは、iOS の標準のシートでしか取り消せない（機能仕様書 4.1.3）。
            if (state.appleElsewhere || state.appleOnlyElsewhere) ...[
              const SizedBox(height: 16),
              Text(
                // Apple だけなら、この端末では本人を確かめられないので、iPhone で退会してもらう。
                state.appleOnlyElsewhere
                    ? l10n.settingsWithdrawAppleOnly
                    : l10n.settingsWithdrawAppleElsewhere,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  color: c.textSecondary,
                ),
              ),
            ],
            // ストアのサブスクは、退会しても解約されない（機能仕様書 4.1.3）。
            if (state.subscriptionNotice) ...[
              const SizedBox(height: 16),
              Text(
                l10n.settingsWithdrawSubscriptionNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TonalButton(
                label: l10n.settingsWithdrawManageSubscription,
                onPressed: () => openSubscriptionManagement(
                  context,
                  ref
                      .read(withdrawViewModelProvider.notifier)
                      .manageSubscriptionsUrl,
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.settingsWithdrawButton,
              destructive: true,
              onPressed: state.appleOnlyElsewhere
                  ? null
                  : () async {
                      // ログイン方法を結び付けたユーザーは、先に本人を確かめる（機能仕様書 4.1.4.1）。
                      if (!await ensureReauthenticated(
                            context,
                            ref,
                            withdraw: true,
                          ) ||
                          !context.mounted) {
                        return;
                      }
                      final ok = await ref
                          .read(loadingOverlayProvider.notifier)
                          .run(
                            () => ref
                                .read(withdrawViewModelProvider.notifier)
                                .withdraw(),
                          );
                      if (!context.mounted) return;
                      if (!ok) {
                        showAppSnackBar(context, l10n.settingsWithdrawFailed);
                        return;
                      }
                      // 初回起動の画面に戻る。
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
            ),
            const SizedBox(height: 24),
            AppTextButton(
              label: l10n.commonCancel,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
