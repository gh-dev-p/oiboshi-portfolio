import 'package:flutter/material.dart';

/// 追星の色（2026-11-09 の案）。画面の枠は白と黒の中立の色（YouTube・Instagram・X に合わせる）に寄せ、色は中身（サムネイル・SNS のアイコン）に任せる。
/// 追星らしさは、紺色（[accentNavy]。前の主要色）と、キャラクターの3色（[accentGreen]・[accentBlue]・[accentRed]）を、決めた少ない場所だけに差して出す。
/// Figma の変数「追星の色」は、本人が配色を決めてから合わせる（まだ藍色のまま）。
/// テーマ（[ThemeData.extensions]）に載せ、画面側では `context.colors.textPrimary` のように取り出す。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.fieldFill,
    required this.tonal,
    required this.primary,
    required this.primaryLight,
    required this.onPrimary,
    required this.avatarFill,
    required this.placeholder,
    required this.border,
    required this.divider,
    required this.outline,
    required this.handle,
    required this.unselected,
    required this.live,
    required this.livePink,
    required this.verifiedFill,
    required this.verifiedText,
    required this.upcomingFill,
    required this.upcomingIcon,
    required this.now,
    required this.gridMajor,
    required this.gridMinor,
    required this.disabled,
    required this.shadow,
    required this.accentGreen,
    required this.accentNavy,
    required this.accentNavyFill,
    required this.accentBlue,
    required this.accentRed,
    required this.onAccent,
    required this.link,
  });

  /// 画面の背景。
  final Color background;

  /// 角丸の面（次の予定のカード、設定のプロフィールカード、通知の注意カード）。
  final Color surface;

  /// 画像のプレースホルダー、終了したチップの背景。
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// @ID・時刻などの補助の文字。
  final Color textMuted;

  /// 検索フィールドの塗り。
  final Color fieldFill;

  /// 「フォロー中」ボタンなど、薄い塗りのボタン。
  final Color tonal;

  /// ボタン・選ばれている印など。ライトはほぼ黒、ダークはほぼ白。
  final Color primary;

  /// スナックバーの操作の文字。紺色の明るい版。
  final Color primaryLight;
  final Color onPrimary;

  /// アイコンのプレースホルダーの塗り、丸いアイコンボタンの背景。
  final Color avatarFill;

  /// プレースホルダーの中の人型アイコン。
  final Color placeholder;

  /// 下部ナビの上の線。
  final Color border;

  /// 行の区切り。
  final Color divider;

  /// チップの枠線、カードの区切り。
  final Color outline;

  /// シートの引き手。
  final Color handle;

  /// 選んでいないラジオの枠、既読のリング。
  final Color unselected;
  final Color live;
  final Color livePink;
  final Color verifiedFill;
  final Color verifiedText;

  /// これからの予定があるときのカレンダーのボタン。
  final Color upcomingFill;
  final Color upcomingIcon;

  /// 現在時刻の線、土曜の文字。
  final Color now;
  final Color gridMajor;
  final Color gridMinor;
  final Color disabled;
  final Color shadow;

  /// 差し色。紺色（前の主要色）と、キャラクターの緑・青・赤（ホームのロゴの絵から取った）。決めた場所だけに使う。
  /// 使う場所：新着の推しの輪（紺・緑・青）、「NEW」の印（紺）、何もないときの絵（紺の輪と緑・青・赤の粒）。
  /// 赤は配信中の [live] と取り違えるので、粒にだけ使う。
  final Color accentGreen;

  /// 紺色（藍色）。ライトは前の主要色 `#525CA5`、ダークは前の明るい主要色 `#A0A7E8`。
  final Color accentNavy;

  /// 紺色の薄い塗り（何もないときの絵の内側の丸）。
  final Color accentNavyFill;
  final Color accentBlue;
  final Color accentRed;

  /// 紺色（[accentNavy]）の上の文字。
  final Color onAccent;

  /// 本文の中のリンク。キャラクターの青を、本文の 4.5:1 に届く濃さにした。
  final Color link;

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF2F2F2),
    surfaceVariant: Color(0xFFE5E5E5),
    textPrimary: Color(0xFF0F0F0F),
    textSecondary: Color(0xFF606060),
    textTertiary: Color(0xFF666666),
    textMuted: Color(0xFF666666),
    fieldFill: Color(0xFFF2F2F2),
    tonal: Color(0xFFEDEDED),
    primary: Color(0xFF0F0F0F),
    primaryLight: Color(0xFFA0A7E8),
    onPrimary: Color(0xFFFFFFFF),
    avatarFill: Color(0xFFEDEDED),
    placeholder: Color(0xFF808080),
    border: Color(0xFFE5E5E5),
    divider: Color(0xFFE5E5E5),
    outline: Color(0xFFCCCCCC),
    handle: Color(0xFFD0D0D0),
    unselected: Color(0xFFA8A8A8),
    live: Color(0xFFE53935),
    livePink: Color(0xFFF06292),
    verifiedFill: Color(0xFFE4F1DA),
    verifiedText: Color(0xFF2F7A1F),
    upcomingFill: Color(0xFFE1E0F9),
    upcomingIcon: Color(0xFF525CA5),
    now: Color(0xFF0A6FD6),
    gridMajor: Color(0xFFEBEBEB),
    gridMinor: Color(0xFFF5F5F5),
    disabled: Color(0xFFD6D6D6),
    shadow: Color(0x2E000000),
    accentGreen: Color(0xFF50A22F),
    accentNavy: Color(0xFF525CA5),
    accentNavyFill: Color(0xFFE1E0F9),
    accentBlue: Color(0xFF017EFB),
    accentRed: Color(0xFFF61E15),
    onAccent: Color(0xFFFFFFFF),
    link: Color(0xFF0A6FD6),
  );

  static const dark = AppColors(
    background: Color(0xFF0F0F0F),
    surface: Color(0xFF212121),
    surfaceVariant: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFF1F1F1),
    textSecondary: Color(0xFFC8C8C8),
    textTertiary: Color(0xFFAAAAAA),
    textMuted: Color(0xFFAAAAAA),
    fieldFill: Color(0xFF222222),
    tonal: Color(0xFF303030),
    primary: Color(0xFFF1F1F1),
    primaryLight: Color(0xFFB8BEF0),
    onPrimary: Color(0xFF0F0F0F),
    avatarFill: Color(0xFF303030),
    placeholder: Color(0xFFAAAAAA),
    border: Color(0xFF272727),
    divider: Color(0xFF272727),
    outline: Color(0xFF3F3F3F),
    handle: Color(0xFF3F3F3F),
    unselected: Color(0xFF717171),
    live: Color(0xFFE53935),
    livePink: Color(0xFFF06292),
    verifiedFill: Color(0xFF23361C),
    verifiedText: Color(0xFF8FD07A),
    upcomingFill: Color(0xFF35344A),
    upcomingIcon: Color(0xFFA0A7E8),
    now: Color(0xFF5AA9FF),
    gridMajor: Color(0xFF272727),
    gridMinor: Color(0xFF1A1A1A),
    disabled: Color(0xFF3F3F3F),
    shadow: Color(0x66000000),
    accentGreen: Color(0xFF50A22F),
    accentNavy: Color(0xFFA0A7E8),
    accentNavyFill: Color(0xFF35344A),
    accentBlue: Color(0xFF017EFB),
    accentRed: Color(0xFFF61E15),
    onAccent: Color(0xFF0F0F0F),
    link: Color(0xFF5AA9FF),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
