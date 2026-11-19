import 'package:flutter/material.dart';

import '../../../domain/models/oshi.dart';
import '../../../domain/models/schedule_filter.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../domain/models/schedule_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/sns_style.dart';
import '../../creator/widgets/creator_screen.dart';
import '../view_models/time_schedule_viewmodel.dart';
import 'schedule_detail_panel.dart';
import 'time_grid.dart';
import 'time_grid_items.dart';

/// 列ヘッダー。名前は出さず、アイコンだけにする。読み上げでは名前を読む。押すと発信者ページへ。
class ScheduleColumnHeader extends StatelessWidget {
  const ScheduleColumnHeader({super.key, required this.oshi});

  final Oshi oshi;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Semantics(
          label: oshi.creator.name,
          button: true,
          excludeSemantics: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => CreatorScreen.open(context, oshi.id),
            child: AvatarImage(url: oshi.creator.avatarUrl, size: 30),
          ),
        ),
      ),
    );
  }
}

/// 時間軸の上端（0:00 の上）と下端（24:00 の下）の帯。ここが端だと分かるように、地の色を変える。
/// 時刻のラベルにかからないように、表の部分にだけ敷く。
class ScheduleEdgeBand extends StatelessWidget {
  const ScheduleEdgeBand({super.key, required this.top});

  final bool top;

  /// 帯の高さ。
  static const height = 16.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [c.surfaceVariant, c.background],
        ),
      ),
    );
  }
}

/// 「終日」の帯のピル。
class ScheduleAllDayPills extends StatelessWidget {
  const ScheduleAllDayPills({
    super.key,
    required this.items,
    required this.expanded,
    required this.selectedKey,
    required this.onTap,
  });

  final List<ScheduleItem> items;
  final bool expanded;

  /// 詳細のパネルで選んでいる要素。選んだピルを目立たせ、ほかを薄くする（画面定義書 2.1.3）。
  final String? selectedKey;
  final ValueChanged<ScheduleItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final item = items.first;
    final title = l10n.scheduleTitle(item);
    final color = SnsStyle.colorOf(context, item.service);
    return FocusEffect(
      selectedKey: selectedKey,
      itemKey: AllDayFocus.keyOf(item),
      color: color,
      child: InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(11),
        // 時刻未定の公演は、終日の予定と見分けられるよう、読み上げでも「時刻未定」と伝える（画面定義書（スケジュール）2.1.1）。
        child: Semantics(
          label: item.timeTbd ? l10n.commonTimeTbd : null,
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlatformIcon(item.service, size: 14),
                if (expanded && item.timeTbd) ...[
                  const SizedBox(width: 5),
                  // 読み上げは、外の Semantics で伝える。
                  ExcludeSemantics(
                    child: Text(
                      l10n.commonTimeTbd,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (expanded) ...[
                  const SizedBox(width: 5),
                  Flexible(
                    child: OneLineText(
                      items.length > 1
                          ? l10n.scheduleAllDayMore(title, items.length - 1)
                          : title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 表の列1つぶん。推しと、その「終日」の予定と、時間軸の列。
typedef ScheduleTableEntry = ({
  Oshi oshi,
  List<ScheduleItem> allDay,
  TimeGridColumn column,
});

/// 表の列を組み立てる。[allDay] は、その日の「終日」の予定。
/// [isEmpty] は、どの列にも、ブロックも投稿も終日の予定もないか（終日の予定しかない日も、予定なしにしない。画面定義書 2.1.2）。
/// 予定のない列を隠す絞り込みでは、予定のある列だけを返す（全員にないときは、列を隠さず、予定なしのカードを出す）。
({List<ScheduleTableEntry> entries, bool isEmpty}) scheduleTableEntries(
  TimeScheduleData data, {
  required List<ScheduleItem> allDay,
  required ScheduleFilter filter,
  required DateTime now,
}) {
  // 選んだ日ではなく、データの日で並べる。
  final day = data.day;
  var entries = [
    for (final o in data.oshis)
      (
        oshi: o,
        allDay: allDay.where((s) => s.creatorId == o.id).toList(),
        column: TimeGridColumn(
          creator: o.creator,
          blocks: blocksFor(o, data.schedules, day, now, filter: filter),
          clusters: clusterPosts(data.posts.where((p) => p.creatorId == o.id)),
        ),
      ),
  ];
  final isEmpty = entries.every(
    (e) =>
        e.allDay.isEmpty &&
        e.column.blocks.isEmpty &&
        e.column.clusters.isEmpty,
  );
  if (filter.hideEmpty) {
    final withItems = entries
        .where(
          (e) =>
              e.allDay.isNotEmpty ||
              e.column.blocks.isNotEmpty ||
              e.column.clusters.isNotEmpty,
        )
        .toList();
    if (withItems.isNotEmpty) entries = withItems;
  }
  return (entries: entries, isEmpty: isEmpty);
}

/// 詳細のパネルを左右のスワイプで送る順（画面定義書（スケジュール）2.1.3）。
/// 列を左から、列の中は「終日」のピル、時刻の順（同じ時刻ならブロックを先）に並べる。
/// [column] は、その要素の列（[entries] の何番目か）。
List<({ScheduleFocus focus, int column})> scheduleFocusOrder(
  List<ScheduleTableEntry> entries,
) => [
  for (final (i, e) in entries.indexed) ...[
    // 「終日」の帯には、最初の予定だけをピルで出す。
    if (e.allDay.isNotEmpty)
      (focus: AllDayFocus(e.allDay.first, e.oshi.creator), column: i),
    for (final focus in <ScheduleFocus>[
      for (final b in e.column.blocks) BlockFocus(b, e.oshi.creator),
      for (final cl in e.column.clusters) ClusterFocus(cl, e.oshi.creator),
    ]..sort(_byTime))
      (focus: focus, column: i),
  ],
];

int _byTime(ScheduleFocus a, ScheduleFocus b) {
  final byTime = a.time!.compareTo(b.time!);
  if (byTime != 0) return byTime;
  // List.sort は並びを保たないので、同じ時刻はブロックを先にし、そのあとキーで決める。
  final byKind = (a is BlockFocus ? 0 : 1) - (b is BlockFocus ? 0 : 1);
  return byKind != 0 ? byKind : a.key.compareTo(b.key);
}
