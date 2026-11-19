import 'package:flutter/material.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../themes/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'l10n_labels.dart';
import 'one_line_text.dart';
import 'oshi_avatar.dart';
import 'panel_header.dart';

/// 「イベント」の面。角丸の面に、これからのイベントを日付順に縦に並べる（ホームと発信者ページ。画面定義書（ファン）2.2.1・2.4.1）。
/// 1件もなくても面は出し、ないことを知らせる。行は、イベント一覧と同じ形（[EventRow]）。
class EventPanel extends StatelessWidget {
  const EventPanel({
    super.key,
    required this.items,
    required this.creatorOf,
    required this.more,
    required this.onMore,
    required this.onTap,
    this.showCreator = true,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 12),
  });

  final List<ScheduleItem> items;

  /// 行の発信者。
  final Creator? Function(ScheduleItem item) creatorOf;

  /// 出しきれない件数。1件以上なら、見出しの右に「ほか N 件」を出す。
  final int more;
  final VoidCallback onMore;

  /// 行を押したとき。
  final void Function(ScheduleItem item, Creator creator) onTap;

  /// 行に、推しのアイコンと名前を出すか。発信者ページでは出さない（その発信者のページのため）。
  final bool showCreator;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListPanel(
      title: l10n.commonEventsTitle,
      more: more,
      onMore: onMore,
      emptyText: l10n.commonEventsEmpty,
      padding: padding,
      children: [
        for (var i = 0; i < items.length; i++)
          _panelRow(items[i], creatorOf(items[i]), i == items.length - 1),
      ],
    );
  }

  Widget _panelRow(ScheduleItem item, Creator? creator, bool last) => EventRow(
    item: item,
    creator: creator,
    showCreator: showCreator,
    divider: !last,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    onTap: creator == null ? null : () => onTap(item, creator),
  );
}

/// イベントの1行（「イベント」の面とイベント一覧で共通）。左に日付のブロック（月と日）、右にタイトル、
/// 「{曜日} {時刻}・{会場}」。[showCreator] なら、その下に推しのアイコンと名前も出す。
class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.item,
    required this.creator,
    required this.showCreator,
    required this.onTap,
    this.divider = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final ScheduleItem item;
  final Creator? creator;
  final bool showCreator;
  final VoidCallback? onTap;

  /// 下に区切りの線を引くか（面の中で、最後の行でないとき）。
  final bool divider;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final start = item.startsAt.toLocal();
    final when = '${weekdayLabel(start, l10n)} ${l10n.scheduleStartTime(item)}';
    final venue = item.venue?.trim() ?? '';
    final creator = this.creator;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: c.divider)) : null,
        ),
        child: Row(
          children: [
            EventDateTile(start: start),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineText(
                    l10n.scheduleTitle(item),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  OneLineText(
                    venue.isEmpty ? when : l10n.commonWhenVenue(when, venue),
                    style: context.textStyles.caption,
                  ),
                  if (showCreator && creator != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AvatarImage(url: creator.avatarUrl, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OneLineText(
                            creator.name,
                            style: context.textStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 日付のブロック。上の段に月（「11月」）、下の段に日（「12」）を大きく。
class EventDateTile extends StatelessWidget {
  const EventDateTile({super.key, required this.start});

  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 52,
      height: 56,
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FittedBox(
        // 文字を大きくする設定でも、ブロックの大きさは変えずに縮める。
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              monthLabel(start, l10n),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
            Text(
              '${start.day}',
              style: TextStyle(
                fontSize: 22,
                height: 26 / 22,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
