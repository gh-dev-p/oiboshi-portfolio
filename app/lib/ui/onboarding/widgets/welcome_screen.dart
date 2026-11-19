import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/legal_link_text.dart';
import '../../core/ui/state_view.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../creator_admin/widgets/creator_register_screen.dart';
import '../../settings/view_models/login_viewmodel.dart';
import '../../settings/widgets/login_sheet.dart';
import '../view_models/welcome_viewmodel.dart';
import 'choose_oshi_screen.dart';
import '../../../l10n/app_localizations.dart';

/// ウェルカム（画面定義書 2.1.1）。初回起動で最初に出す。
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// 「はじめる」を押してから、推しを選ぶから戻るまで。連打で、推しを選ぶを何枚も積まない。
  bool _starting = false;

  Future<void> _start() async {
    // 作り直す前（同じフレームの中）に、続けて押されたときも弾く。
    if (_starting) return;
    setState(() => _starting = true);
    final vm = ref.read(welcomeViewModelProvider.notifier);
    await vm.start();
    // 共有のページから入れた人には、推しを選ぶの前に、その発信者のページを出す。戻ると推しを選ぶ（4.3.4）。
    // 誘う用のリンク（4.3.6）なら、先にその発信者をフォローし、ページで知らせる。
    final linked = await vm.takeClipboardLink();
    if (linked != null && mounted) {
      final followedName = linked.invite
          ? await vm.followInvited(linked.creatorId)
          : null;
      if (mounted) {
        final pushed = Navigator.of(
          context,
        ).push(CreatorScreen.route(linked.creatorId));
        if (followedName != null) {
          showAppSnackBar(
            context,
            AppLocalizations.of(
              context,
            )!.onboardingInviteFollowed(followedName),
          );
        }
        await pushed;
      }
    }
    if (mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ChooseOshiScreen()));
    }
    if (mounted) setState(() => _starting = false);
  }

  /// 「発信者の方はこちら」。アカウントがなければ、先にアカウント作成／ログイン（シート）を出し、済んだら登録へ進む
  /// （機能仕様書 4.6.1）。使ったことのあるアカウントで、もう発信者のオーナーなら、登録へは進まない。
  Future<void> _forCreators() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final vm = ref.read(welcomeViewModelProvider.notifier);
      if (await vm.needsAccount()) {
        if (!mounted) return;
        final outcome = await showLoginSheet(context, forCreator: true);
        if (outcome == null || !mounted) return;
        showLoginOutcomeSnackBar(context, outcome);
        if (outcome == LoginOutcome.loggedIn && await vm.ownsCreator()) return;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CreatorRegisterScreen()),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
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
                      const OnboardingIllustration(icon: Icons.star),
                      const SizedBox(height: 24),
                      Text(
                        l10n.appTitle,
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.onboardingWelcomeTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 26 / 16,
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
                    label: l10n.onboardingStart,
                    onPressed: _starting ? null : _start,
                  ),
                  const SizedBox(height: 4),
                  AppTextButton(
                    label: l10n.onboardingForCreators,
                    onPressed: _starting ? null : _forCreators,
                  ),
                  const SizedBox(height: 4),
                  LegalLinkText(
                    [
                      (l10n.onboardingAgreePrefix, null),
                      (l10n.commonTermsOfService, termsUrl),
                      (l10n.onboardingAgreeAnd, null),
                      (l10n.commonPrivacyPolicy, privacyUrl),
                      (l10n.onboardingAgreeSuffix, null),
                    ],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 17 / 11,
                      color: c.textTertiary,
                    ),
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

/// 初回起動の丸いイラスト（160）。
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 160 / 140,
      child: StateIllustration(icon: icon),
    );
  }
}

/// 初回起動の主ボタン（高さ 52、角丸 26）。
class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
