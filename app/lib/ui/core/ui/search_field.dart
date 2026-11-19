import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// 検索フィールド（薄い面の小さな角丸）。推しリスト・推しを探す・推しを選ぶ・設定で使う。
/// 入力前の文字（「検索」）・入力した文字・虫めがねを、欄の上下の真ん中にそろえる（2026-11-19 本人）。
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 8),
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final EdgeInsets padding;

  /// 文字の行の高さ（倍率）。行の上下に同じだけ余白をとり、文字を真ん中に置く。
  static const _lineHeight = 1.3;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.fieldFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: c.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontSize: 14,
                  height: _lineHeight,
                  leadingDistribution: TextLeadingDistribution.even,
                  color: c.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  // アプリ全体の入力欄の余白（左右 14・上下 12。app_theme.dart）がかかると、文字が上と右にずれるので、消す。
                  contentPadding: EdgeInsets.zero,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    height: _lineHeight,
                    leadingDistribution: TextLeadingDistribution.even,
                    color: c.textTertiary,
                  ),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
