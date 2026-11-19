import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/plan_billing.dart';
import '../../../domain/models/sns_service.dart';
import '../../../utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/legal_link_text.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../core/ui/subscription_management.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/plan_viewmodel.dart';
import '../../core/ui/viewer_aware_header.dart';

/// プラン（画面定義書 2.3.6）。いまのプランを出し、X連携プラン（X の連携）に、ストアで加入・解約する。
/// 基本プランは無料。発信者メニューから開く。加入中かどうかは、ストアの購入から決める。
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key, this.plan = CreatorPlan.standard});

  /// いまのプランの種類。永年無料・運営・確認用なら、X の連携を含むので、いまのプランだけを出す。
  final CreatorPlan plan;

  Future<void> _purchase(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => ref.read(planViewModelProvider.notifier).purchase());
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      // 買えたら、画面は閉じずに、X連携プランのカードを加入中の表示に変える。
      case PlanPurchaseResult.purchased:
      case PlanPurchaseResult.cancelled:
        break;
      case PlanPurchaseResult.pending:
        showAppSnackBar(context, l10n.creatorAdminPlanPurchasePending);
      case PlanPurchaseResult.failed:
        showAppSnackBar(context, l10n.creatorAdminPlanPurchaseFailed);
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final found = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => ref.read(planViewModelProvider.notifier).restore());
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showAppSnackBar(context, switch (found) {
      true => l10n.creatorAdminPlanRestored,
      false => l10n.creatorAdminPlanNothingToRestore,
      null => l10n.creatorAdminPlanRestoreFailed,
    });
  }

  /// 「解約する」。解約はストアの画面で行うので、確かめてから、ストアのサブスクの管理を開く
  /// （本人の確認は出さない。機能仕様書 4.1.4.1）。
  Future<void> _manageSubscriptions(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.creatorAdminPlanCancelConfirmTitle,
      message: l10n.creatorAdminPlanCancelConfirmMessage,
      confirmLabel: l10n.creatorAdminPlanCancelConfirmAction,
    );
    if (!confirmed || !context.mounted) return;
    await openSubscriptionManagement(
      context,
      ref.read(planViewModelProvider.notifier).manageSubscriptionsUrl,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (plan.includesX) {
      return HeaderScaffold(
        appBar: ScreenAppBar(title: l10n.creatorAdminPlanTitle),
        body: ListView(
          children: [
            _CurrentPlanCard(
              plan: plan,
              note: l10n.creatorAdminPlanIncludedNote,
            ),
          ],
        ),
      );
    }
    final state = ref.watch(planViewModelProvider);
    final current = _CurrentPlanCard(
      plan: plan,
      note: l10n.creatorAdminPlanFree,
      features: [
        // この版で出さない SNS（v1.0.0 の Instagram・ツイキャス）は挙げない（機能仕様書 4.6.6）。
        // X は X連携プランの内容なので、ここには挙げない。
        l10n.creatorAdminPlanBasicFeatureFetch(
          [
            for (final s in SnsService.offeredValues)
              if (s != SnsService.x) l10n.sns(s),
          ].join(l10n.commonListSeparator),
        ),
        l10n.creatorAdminPlanBasicFeatureReservations,
        l10n.creatorAdminPlanBasicFeatureCalendar,
      ],
    );
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.creatorAdminPlanTitle),
      body: state.when(
        skipLoadingOnRefresh: true,
        loading: () => ListView(
          children: [
            current,
            const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonBox(height: 200, radius: 20),
            ),
          ],
        ),
        error: (_, _) => Column(
          children: [
            current,
            Expanded(
              child: StateView.error(
                onRetry: ref.read(planViewModelProvider.notifier).retry,
              ),
            ),
          ],
        ),
        data: (s) {
          final offer = s.offer;
          if (offer == null) {
            return Column(
              children: [
                current,
                const Expanded(child: _UnavailableView()),
              ],
            );
          }
          return _body(context, ref, current, offer, s.subscription);
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    Widget current,
    PlanOffer offer,
    PlanSubscription sub,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final expiresAt = sub.expiresAt;
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        current,
        SectionLabel(l10n.creatorAdminPlanAddOns),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SurfacePanel(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.creatorAdminPlanXOptionTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (sub.xOption)
                      StatusChip(
                        l10n.creatorAdminPlanSubscribed,
                        background: c.verifiedFill,
                        foreground: c.verifiedText,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.creatorAdminPlanPerMonth(l10n.planPrice(offer.xOption)),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                if (sub.xOption && expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sub.willRenew
                        ? l10n.creatorAdminPlanRenewsOn(
                            fullDate(expiresAt, l10n),
                          )
                        : l10n.creatorAdminPlanEndsOn(
                            fullDate(expiresAt, l10n),
                          ),
                    style: context.textStyles.note,
                  ),
                ],
                _Features([
                  l10n.creatorAdminPlanXFeatureFetch,
                  l10n.creatorAdminPlanXFeatureNoReposts,
                ]),
                if (!sub.xOption) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: l10n.creatorAdminPlanSubscribe,
                    onPressed: () => _purchase(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (sub.xOption)
          Center(
            child: AppTextButton(
              label: l10n.creatorAdminPlanCancel,
              fontWeight: FontWeight.w500,
              color: c.live,
              onPressed: () => _manageSubscriptions(context, ref),
            ),
          ),
        Center(
          child: AppTextButton(
            label: l10n.creatorAdminPlanRestore,
            fontWeight: FontWeight.w500,
            onPressed: () => _restore(context, ref),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            l10n.creatorAdminPlanSubscriptionTerms,
            style: TextStyle(
              fontSize: 12,
              height: 18 / 12,
              color: c.textTertiary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: LegalLinkText([
            (l10n.commonTermsOfService, termsUrl),
            (l10n.creatorAdminPlanLegalSeparator, null),
            (l10n.commonPrivacyPolicy, privacyUrl),
          ], style: context.textStyles.hint),
        ),
      ],
    );
  }
}

/// 「いまのプラン」のカード。プラン名と、料金の注記（基本プランなら「無料」）と、使えること。
class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.plan,
    required this.note,
    this.features = const [],
  });

  final CreatorPlan plan;
  final String note;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SurfacePanel(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.creatorAdminPlanCurrent,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.creatorPlan(plan),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(note, style: context.textStyles.note),
            _Features(features),
          ],
        ),
      ),
    );
  }
}

/// 使えることの一覧（チェックの印つき）。
class _Features extends StatelessWidget {
  const _Features(this.features);

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in features) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check, size: 16, color: c.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(f, style: context.textStyles.note)),
            ],
          ),
        ],
      ],
    );
  }
}

/// この端末では課金を使えない（RevenueCat のキーがない）とき。
class _UnavailableView extends StatelessWidget {
  const _UnavailableView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StateView(
      icon: Icons.workspace_premium_outlined,
      title: l10n.creatorAdminPlanUnavailableTitle,
      message: l10n.creatorAdminPlanUnavailableMessage,
    );
  }
}
