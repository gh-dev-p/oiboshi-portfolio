import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../themes/app_colors.dart';
import 'one_line_text.dart';
import 'settings_row.dart';

/// 「次の予定」「イベント」の面の見出し。出しきれない件数があれば、右に「ほか N 件」を出し、押すと一覧のある画面へ移る。
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    required this.more,
    required this.onMore,
  });

  final String title;
  final int more;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: OneLineText(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (more > 0)
              InkWell(
                onTap: onMore,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.commonMoreCount(more),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: c.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 「次の予定」「イベント」が1件もないときの行。面は出したまま、ないことを知らせる。
class PanelEmptyRow extends StatelessWidget {
  const PanelEmptyRow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Text(text, style: TextStyle(fontSize: 13, color: c.textTertiary)),
    );
  }
}

/// 見出しつきの面（「次の予定」「イベント」）。角丸の面に、見出し（[PanelHeader]）と行を縦に並べる。
/// 行が1つもなくても面は出し、[emptyText] でないことを知らせる（[PanelEmptyRow]）。
class ListPanel extends StatelessWidget {
  const ListPanel({
    super.key,
    required this.title,
    required this.more,
    required this.onMore,
    required this.emptyText,
    required this.padding,
    required this.children,
  });

  final String title;

  /// 出しきれない件数。1件以上なら、見出しの右に「ほか N 件」を出す。
  final int more;
  final VoidCallback onMore;
  final String emptyText;

  /// 面の外側の余白。
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SurfacePanel(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PanelHeader(title: title, more: more, onMore: onMore),
            if (children.isEmpty) PanelEmptyRow(emptyText),
            ...children,
          ],
        ),
      ),
    );
  }
}
