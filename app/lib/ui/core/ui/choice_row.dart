import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// 選択肢の行。左に文言、右にチェックの丸（選んでいれば塗った丸）。押すと [onTap]。
/// 1つを選ぶときに使う（言語のシート、イベントの長さの画面とシート）。
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.horizontalPadding = 16,
    this.fontSize = 15,
    this.boldWhenSelected = true,
    this.divider = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// 行の左右の余白。
  final double horizontalPadding;
  final double fontSize;

  /// 選んでいる行の文言を太字にするか（ほかの行は、ふつうの太さ）。false なら、文字の太さを決めない。
  final bool boldWhenSelected;

  /// 行の下に、区切りの線を引くか（面の中に並べるとき。最後の行は引かない）。
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 14,
        ),
        decoration: divider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: c.divider)),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: !boldWhenSelected
                      ? null
                      : selected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: c.textPrimary,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 24,
              color: selected ? c.primary : c.unselected,
            ),
          ],
        ),
      ),
    );
  }
}
