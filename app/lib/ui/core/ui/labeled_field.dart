import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../themes/app_colors.dart';
import '../themes/app_text_styles.dart';

/// 入力欄（ラベル・必須の印・入力・注記）。
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.error = false,
    this.note,
    this.badge,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final String label;
  final Widget child;
  final bool required;

  /// 必須の項目が未入力。
  final bool error;
  final String? note;

  /// ラベルの右に出す印（例：取り込んだ下書き）。
  final Widget? badge;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: error ? c.live : c.textTertiary,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE2E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.commonRequired,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
              if (badge != null) ...[const SizedBox(width: 8), badge!],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: error
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.live, width: 1.5),
                  )
                : null,
            child: child,
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(note!, style: context.textStyles.hint),
          ],
        ],
      ),
    );
  }
}
