import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../domain/models/creator_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/legal_link_text.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/creator_register_viewmodel.dart';
import 'account_link_screen.dart';
import 'profile_edit_screen.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 発信者として登録（画面定義書 2.2.1）。2つの手順と、規約への同意が済むと、登録できる。
class CreatorRegisterScreen extends ConsumerWidget {
  const CreatorRegisterScreen({super.key});

  /// 見出しの右に置く、緑の星のキャラクター（背景が透明。app/assets/characters/）。
  static const greenStarCharacter = 'assets/characters/green.png';

  /// アカウント（ログイン方法）があるか。なければ、知らせる。登録の流れの中では、ログイン方法を結び付けない
  /// （機能仕様書 4.6.1。アカウント作成の前は、設定のカードが押せず、ウェルカムからは先に作るので、ふつうは来ない）。
  static Future<bool> _hasAccount(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(creatorRegisterViewModelProvider.notifier)
        .hasLoginMethod();
    if (!ok && context.mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.settingsAccountRequired,
      );
    }
    return ok;
  }

  Future<void> _register(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(creatorRegisterViewModelProvider.notifier);
    if (!await _hasAccount(context, ref) || !context.mounted) return;
    final result = await ref
        .read(loadingOverlayProvider.notifier)
        .run(vm.register);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (result) {
      RegisterResult.registered => l10n.creatorAdminRegistered,
      RegisterResult.registeredPartially =>
        l10n.creatorAdminRegisteredPartially,
      RegisterResult.idTaken => l10n.creatorAdminRegisterIdTaken,
      RegisterResult.duplicate => l10n.creatorAdminRegisterDuplicate,
      RegisterResult.closed => l10n.creatorAdminRegisterClosed,
      RegisterResult.failed => l10n.creatorAdminRegisterFailed,
    };
    showAppSnackBar(context, message);
    if (result.isRegistered) Navigator.of(context).pop();
  }

  /// オーナーが退会した発信者を取り戻す（機能仕様書 4.6.1.2）。登録と同じく、アカウントがあるときだけ。
  Future<void> _reclaim(
    BuildContext context,
    WidgetRef ref,
    ReclaimableCreator creator,
  ) async {
    final vm = ref.read(creatorRegisterViewModelProvider.notifier);
    if (!await _hasAccount(context, ref) || !context.mounted) return;
    final result = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => vm.reclaim(creator.id));
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (result) {
      ReclaimResult.reclaimed => l10n.creatorAdminReclaimed(creator.name),
      ReclaimResult.notReclaimable => l10n.creatorAdminReclaimNotReclaimable,
      ReclaimResult.duplicate => l10n.creatorAdminReclaimDuplicate,
      ReclaimResult.closed => l10n.creatorAdminRegisterClosed,
      ReclaimResult.failed => l10n.creatorAdminReclaimFailed,
    };
    showAppSnackBar(context, message);
    if (result == ReclaimResult.reclaimed) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final state = ref.watch(creatorRegisterViewModelProvider);
    final vm = ref.read(creatorRegisterViewModelProvider.notifier);
    final reclaimable = state.reclaimable;
    final linkDone = state.linkDone;
    void push(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.creatorAdminRegisterTitle),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 見出し（2026-11-10 本人、案3。キャラクターは緑）。ラベルの行の右に、緑の星（飾り。読み上げない）。
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.accentNavyFill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.creatorAdminRegisterEyebrow,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: c.accentNavy,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ExcludeSemantics(
                      child: Image.asset(
                        greenStarCharacter,
                        height: 44,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.creatorAdminRegisterHeadline,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    letterSpacing: -0.3,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.creatorAdminRegisterLead,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (reclaimable != null)
            _ReclaimPanel(
              creator: reclaimable,
              onReclaim: () => _reclaim(context, ref, reclaimable),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SurfacePanel(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _StepRow(
                    number: 1,
                    title: l10n.creatorAdminRegisterStepLink,
                    done: linkDone,
                    sub: linkDone
                        ? l10n.creatorAdminRegisterStepLinkDone(
                            state.linkedServices
                                .map(l10n.sns)
                                .join(l10n.commonListSeparator),
                          )
                        : null,
                    onTap: () => push(const AccountLinkScreen()),
                  ),
                  _StepRow(
                    number: 2,
                    title: l10n.creatorAdminRegisterStepProfile,
                    done: state.profileDone,
                    sub: state.profileDone
                        ? l10n.creatorAdminRegisterStepProfileDone(
                            state.profileName,
                            state.profileId,
                          )
                        : null,
                    last: true,
                    onTap: () => push(const ProfileEditScreen()),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: InkWell(
              onTap: () => vm.setAgreed(!state.agreed),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: state.agreed ? c.primary : null,
                      borderRadius: BorderRadius.circular(6),
                      border: state.agreed
                          ? null
                          : Border.all(color: c.unselected, width: 2),
                    ),
                    child: state.agreed
                        ? Icon(Icons.check, size: 16, color: c.onPrimary)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    // どの入口から来ても、3つの規約にまとめて同意してもらう（機能仕様書 4.1.2）。
                    child: LegalLinkText([
                      (l10n.creatorAdminRegisterAgreePrefix, null),
                      (l10n.commonTermsOfService, termsUrl),
                      (l10n.creatorAdminRegisterAgreeSeparator, null),
                      (l10n.commonPrivacyPolicy, privacyUrl),
                      (l10n.creatorAdminRegisterAgreeLastSeparator, null),
                      (l10n.creatorAdminRegisterTerms, creatorTermsUrl),
                      (l10n.creatorAdminRegisterAgreeSuffix, null),
                    ], style: TextStyle(fontSize: 14, color: c.textPrimary)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: PrimaryButton(
              label: l10n.creatorAdminRegisterAction,
              onPressed: state.canRegister
                  ? () => _register(context, ref)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 取り戻しの案内（画面定義書 2.2.1）。手順1で連携したアカウントが、オーナーが退会した発信者のものだったときに出す。
class _ReclaimPanel extends StatelessWidget {
  const _ReclaimPanel({required this.creator, required this.onReclaim});

  final ReclaimableCreator creator;
  final VoidCallback onReclaim;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SurfacePanel(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.creatorAdminReclaimTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.creatorAdminReclaimMessage(
                creator.name,
                creator.id,
                fullDate(creator.purgeAt, l10n),
                // 永年無料・運営・確認用の発信者は、X の連携を含むので、引き継ぎの文を出さない（画面定義書 2.2.1）。
                creator.plan.includesX ? '' : l10n.creatorAdminReclaimNeedsPlan,
              ),
              style: context.textStyles.note,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: l10n.creatorAdminReclaimAction,
              onPressed: onReclaim,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.done,
    required this.onTap,
    this.sub,
    this.last = false,
  });

  final int number;
  final String title;
  final bool done;
  final String? sub;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.verifiedFill : c.avatarFill,
              ),
              alignment: Alignment.center,
              child: done
                  ? Icon(Icons.check, size: 18, color: c.verifiedText)
                  : Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: TextStyle(
                        fontSize: 12,
                        color: done ? c.verifiedText : c.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
