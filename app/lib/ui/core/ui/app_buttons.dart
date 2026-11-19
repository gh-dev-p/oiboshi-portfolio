import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// 主色の塗りのボタン（高さ 50、角丸 12）。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.trailing,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  /// ラベルの右に添えるもの（「PR」のラベルなど）。
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final color = !enabled
        ? c.disabled
        : destructive
        ? c.live
        : c.primary;
    return SizedBox(
      width: expand ? double.infinity : null,
      height: 50,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    // 消すなどの操作（赤）は、ライト・ダークとも白の文字。
                    color: destructive && enabled ? Colors.white : c.onPrimary,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 薄い塗りのボタン（高さ 50、角丸 12）。
class TonalButton extends StatelessWidget {
  const TonalButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: c.tonal,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 小さな角丸のボタン（角丸 8、文字 13 の太字）。行の右端に置く（「連携する」など）。
/// [tonal] なら、薄い塗りに文字の色。そうでなければ、主色の塗りに白の文字。
class SmallPillButton extends StatelessWidget {
  const SmallPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tonal = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: tonal ? c.tonal : c.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tonal ? c.textPrimary : c.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 文字だけのボタン。
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? context.colors.primary,
        ),
      ),
    );
  }
}

/// 丸いアイコンのボタン（ベル・カレンダー・ミュートなど）。
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 36,
    this.iconSize = 22,
    this.background,
    this.foreground,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = Material(
      color: background ?? c.avatarFill,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: foreground ?? c.textSecondary,
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// 「PR」の枠線のラベル。
class PrLabel extends StatelessWidget {
  const PrLabel({super.key, this.onDark = false});

  /// 主色のボタンの上に置くときは、白い枠にする。
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark
        ? context.colors.onPrimary.withValues(alpha: 0.8)
        : context.colors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PR',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// 状態のチップ（「これから」「終了しました」「イベント」「基本プラン」など）。
class StatusChip extends StatelessWidget {
  const StatusChip(
    this.label, {
    super.key,
    this.icon,
    this.background,
    this.foreground,
    this.muted = false,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  /// 終わった予定のように、薄い見た目にする。
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = foreground ?? (muted ? c.textSecondary : c.textPrimary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? (muted ? c.surfaceVariant : c.avatarFill),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
