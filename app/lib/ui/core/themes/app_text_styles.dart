import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 本文の補助的な文字のスタイル。画面側で繰り返していた `context.textStyles.note`
/// のような直書きをまとめたもので、見た目（サイズ・色・太さ）は直書きと同じ。
///
/// 文字色が表示中のモード（ライト／ダーク）で変わるため、画面側では `context.textStyles.note` のように
/// [AppColors] から組み立てたものを使う。フォントは指定せず、端末のシステムフォントのまま。
class AppTextStyles {
  const AppTextStyles(this._colors);

  final AppColors _colors;

  /// 本文の補足（設定の説明文、プランの説明など）。
  TextStyle get bodySecondary =>
      TextStyle(fontSize: 14, color: _colors.textSecondary);

  /// 注意書き・案内（入力欄の下の説明、確認の文言など）。
  TextStyle get note => TextStyle(fontSize: 13, color: _colors.textSecondary);

  /// 行の下の小さな補足（時刻、件数など）。
  TextStyle get caption =>
      TextStyle(fontSize: 12, color: _colors.textSecondary);

  /// 薄い小さな補足（空のときの案内、ヒント、@ID など）。
  TextStyle get hint => TextStyle(fontSize: 12, color: _colors.textTertiary);
}

extension AppTextStylesContext on BuildContext {
  /// 表示中のモード（ライト／ダーク）の文字スタイル。
  AppTextStyles get textStyles => AppTextStyles(colors);
}
