import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../themes/app_colors.dart';

/// 押して入る画面のヘッダー（画面定義書 5.1.2）。左に戻る、中央に太字のタイトル。
class ScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScreenAppBar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 48,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.chevron_left, size: 24, color: c.textPrimary),
        tooltip: AppLocalizations.of(context)!.commonBack,
      ),
      title: Text(title),
      actions: actions.isEmpty ? [const SizedBox(width: 48)] : actions,
    );
  }
}

/// タブの本体のヘッダー。左に太字のタイトル（ホームは中央に「追星」）。
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.centered = false,
    this.actions = const [],
    this.titleSize = 16,
    this.height = 44,
  });

  final String title;

  /// タイトルの文字の代わりに出すもの（ホームのロゴなど）。読み上げは [title] にする。
  final Widget? titleWidget;
  final bool centered;
  final List<Widget> actions;
  final double titleSize;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final logo = titleWidget;
    final text = logo != null
        ? Semantics(
            label: title,
            header: true,
            excludeSemantics: true,
            child: Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: logo,
            ),
          )
        : Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          );
    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (centered) const SizedBox(width: 48),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: centered ? 0 : 20),
              child: text,
            ),
          ),
          if (actions.isEmpty && centered) const SizedBox(width: 48),
          ...actions,
          if (actions.isNotEmpty) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// ヘッダーの右に置く 48×48 のアイコンボタン。
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.selected,
  });

  final IconData icon;

  /// 押したとき。null なら、押せない見た目にする。
  final VoidCallback? onPressed;
  final String tooltip;

  /// オン・オフを切り替えるボタンのとき、いまオンか。オンは、アイコンの後ろに主の色の丸を敷き、
  /// アイコンを丸の上の色にする（オンとオフがひと目で分かるように。2026-11-19 本人）。
  final bool? selected;

  /// オンのときの丸の大きさ。
  static const double onMarkSize = 36;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = (selected ?? false) && onPressed != null;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        isSelected: selected,
        icon: Container(
          width: onMarkSize,
          height: onMarkSize,
          alignment: Alignment.center,
          decoration: on
              ? BoxDecoration(color: c.primary, shape: BoxShape.circle)
              : null,
          child: Icon(
            icon,
            size: on ? 20 : 24,
            color: onPressed == null
                ? c.disabled
                : on
                ? c.onPrimary
                : c.textPrimary,
          ),
        ),
      ),
    );
  }
}
