import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    show AppleLogoPainter;

import '../../../domain/models/login_method.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/one_line_text.dart';

/// ログインに使うサービスのアイコン。X と Twitch は SNS のアイコンを使う。
/// Apple と Google は、各社の決まりに合わせる（tech-risks.md 2.21）。Apple は公式のロゴの形
/// （`sign_in_with_apple` の [AppleLogoPainter]）を黒の上に白で、Google は公式の「G」を、
/// 公式のアイコンだけのボタン（白・枠 #747775）と同じ割合で出す。
/// [plain] が真なら、ボタンの中に置くため、ロゴだけを出す。
class LoginProviderIcon extends StatelessWidget {
  const LoginProviderIcon(
    this.provider, {
    super.key,
    this.size = 28,
    this.plain = false,
  });

  final LoginProvider provider;
  final double size;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (provider) {
      LoginProvider.x => PlatformIcon(SnsService.x, size: size),
      LoginProvider.twitch => PlatformIcon(SnsService.twitch, size: size),
      LoginProvider.apple when plain => _AppleLogo(
        height: size * 0.8,
        color: Colors.black,
      ),
      LoginProvider.apple => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
        child: _AppleLogo(height: size * 0.5, color: Colors.white),
      ),
      // 暗いボタンでは、G を白い丸に入れる（Google のボタンの dark と同じ）。
      LoginProvider.google when plain && dark => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.15),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const _GoogleG(),
      ),
      LoginProvider.google when plain => SizedBox.square(
        dimension: size,
        child: const _GoogleG(),
      ),
      LoginProvider.google => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 12 / 44),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF747775)),
          borderRadius: BorderRadius.circular(size * 4 / 44),
        ),
        child: const _GoogleG(),
      ),
    };
  }
}

class _AppleLogo extends StatelessWidget {
  const _AppleLogo({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: height * 25 / 31,
    height: height,
    child: CustomPaint(painter: AppleLogoPainter(color: color)),
  );
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brands/google_g.png',
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
  );
}

/// ログインのボタンの文言。Apple と Google は、各社が決めた文言にする（tech-risks.md 2.21）。
/// [continueLabel] が真なら、アカウント作成／ログイン（シート）の「〇〇で続ける」。偽なら、本人の確認の「〇〇でログイン」。
String loginButtonLabel(
  AppLocalizations l10n,
  LoginProvider provider, {
  bool continueLabel = false,
}) => switch (provider) {
  LoginProvider.apple =>
    continueLabel
        ? l10n.settingsContinueWithApple
        : l10n.settingsLoginWithApple,
  LoginProvider.google =>
    continueLabel
        ? l10n.settingsContinueWithGoogle
        : l10n.settingsLoginWithGoogle,
  _ =>
    continueLabel
        ? l10n.settingsContinueWith(provider.label)
        : l10n.settingsLoginWith(provider.label),
};

/// ログインのボタン（アカウント作成／ログインのシート・本人の確認のシート）。
/// 4つのボタンの見た目をそろえる（2026-11-10 本人）：高さ・角の丸み・枠の太さと色・文字の大きさと太さ・
/// アイコンの大きさと位置（左の決まった位置。文字は真ん中）。
/// 色は Google のボタンの決まりに合わせる：明るい画面は白・枠 #747775・文字 #1F1F1F、暗い画面は
/// #131314・枠 #8E918F・文字 #E3E3E3。X と Twitch も同じ色にする。
/// Apple は、白の背景に黒のロゴと文字（「白・枠付き」の形）。暗い画面でも白のまま（黒い背景に黒のボタンは置かない）。
class LoginProviderButton extends StatelessWidget {
  const LoginProviderButton({
    super.key,
    required this.provider,
    required this.label,
    required this.onPressed,
    this.subtitle,
  });

  final LoginProvider provider;
  final String label;
  final VoidCallback? onPressed;

  /// ボタンの文言の下に小さく出す文（結び付けたアカウント）。
  final String? subtitle;

  static const height = 48.0;
  static const radius = 12.0;
  static const borderWidth = 1.0;
  static const fontSize = 15.0;
  static const fontWeight = FontWeight.w600;
  static const iconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (
      Color background,
      Color foreground,
      Color border,
    ) = switch (provider) {
      LoginProvider.apple => (
        Colors.white,
        Colors.black,
        dark ? const Color(0xFF8E918F) : const Color(0xFF747775),
      ),
      _ when dark => (
        const Color(0xFF131314),
        const Color(0xFFE3E3E3),
        const Color(0xFF8E918F),
      ),
      _ => (Colors.white, const Color(0xFF1F1F1F), const Color(0xFF747775)),
    };
    final branded =
        provider == LoginProvider.apple || provider == LoginProvider.google;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size.fromHeight(height),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        side: BorderSide(color: border, width: borderWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: Row(
        children: [
          // アイコンは、どのボタンでも同じ大きさで、左の同じ位置に置く。
          SizedBox.square(
            dimension: iconSize + 4,
            child: Center(
              child: LoginProviderIcon(
                provider,
                size: iconSize,
                plain: branded,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: foreground,
                  ),
                ),
                if (subtitle case final subtitle?)
                  OneLineText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: foreground.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          // 文字が真ん中に来るよう、右にもアイコンと同じ幅を空ける。
          const SizedBox(width: iconSize + 4),
        ],
      ),
    );
  }
}
