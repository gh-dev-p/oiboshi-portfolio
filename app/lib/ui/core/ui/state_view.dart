import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../themes/app_colors.dart';
import 'app_buttons.dart';

/// 空・読み込めない状態の表示（画面定義書 5.1.3）。イラスト・見出し・説明・ボタンを画面の中央に出す。
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  }) : _error = false;

  /// 読み込めなかったときの表示。文言は、表示言語で build のときに決める。
  const StateView.error({super.key, required VoidCallback onRetry})
    : icon = Icons.cloud_off,
      title = '',
      message = '',
      buttonLabel = null,
      onPressed = onRetry,
      _error = true;

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final bool _error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final title = _error ? l10n.commonLoadFailedTitle : this.title;
    final message = _error ? l10n.commonLoadFailedMessage : this.message;
    final buttonLabel = _error ? l10n.commonTryAgain : this.buttonLabel;
    // 場所が足りないとき（検索でキーボードを出しているときなど）は、スクロールして全部を見せる。
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateIllustration(icon: icon),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 22 / 14,
                color: c.textSecondary,
              ),
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: buttonLabel,
                onPressed: onPressed,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 状態表示のイラスト（薄い丸の上に、アイコンの丸）。
class StateIllustration extends StatelessWidget {
  const StateIllustration({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 何もないときの絵は、紺色の輪と、緑・青・赤の粒（差し色）。
              color: c.accentNavy.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.accentNavyFill,
            ),
            child: Icon(icon, size: 40, color: c.accentNavy),
          ),
          for (final (dx, dy, r, color) in [
            (117.0, 19.0, 5.0, c.accentGreen),
            (12.0, 104.0, 4.0, c.accentBlue),
            (123.0, 111.0, 3.0, c.accentRed),
          ])
            Positioned(
              left: dx - r,
              top: dy - r,
              child: Container(
                width: r * 2,
                height: r * 2,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ),
        ],
      ),
    );
  }
}
