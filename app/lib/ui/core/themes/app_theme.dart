import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ライト・ダークのテーマ。色は [AppColors]（案：白と黒の中立の枠＋キャラクターの差し色）。フォントは端末の標準。
abstract final class AppTheme {
  static ThemeData light = _build(AppColors.light, Brightness.light);
  static ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      surface: c.background,
      onSurface: c.textPrimary,
      error: c.live,
    );
    final base = ThemeData(colorScheme: scheme, brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        toolbarHeight: 44,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        // 入れたときのつまみは、主要色の上の色（ダークは主要色が白に近いので、白のつまみが埋もれる）。
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.disabled,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // ライトはほぼ黒、ダークは一段明るい灰色の面。操作の文字は、紺色の明るい版（[AppColors.primaryLight]）。
        backgroundColor: brightness == Brightness.light
            ? c.textPrimary
            : c.tonal,
        contentTextStyle: TextStyle(
          color: brightness == Brightness.light ? c.background : c.textPrimary,
          fontSize: 14,
        ),
        actionTextColor: c.primaryLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: c.textTertiary, fontSize: 14),
      ),
    );
  }
}
