import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_text_styles.dart';

/// 設定の行（アイコン、ラベル、値、「>」）。
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.showChevron = true,
    this.destructive = false,
    this.leading,
    this.trailing,
  });

  final IconData? icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool destructive;

  /// アイコンの代わりに置くもの（プラットフォームのアイコンなど）。
  final Widget? leading;

  /// 値のあとに置くもの（「再試行」のボタンなど）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = destructive ? c.live : c.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else if (icon != null)
              Icon(icon, size: 24, color: fg),
            if (leading != null || icon != null) const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 16, color: fg)),
                ],
              ),
            ),
            if (value != null)
              Text(value!, style: context.textStyles.bodySecondary),
            ?trailing,
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 22, color: c.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

/// 設定のグループの見出し。
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.padding});

  final String label;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.textTertiary,
        ),
      ),
    );
  }
}

/// 角丸の面（設定の項目などをまとめる）。
class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.padding = EdgeInsets.zero,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: child,
    );
  }
}

/// 48×28 のスイッチ。
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 28,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}
