import 'package:flutter/material.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/schedule_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/sns_style.dart';
import 'time_grid_items.dart';
import 'time_grid_labels.dart';

/// 1つの推しの列に出すもの。
class TimeGridColumn {
  const TimeGridColumn({
    required this.creator,
    required this.blocks,
    required this.clusters,
  });

  final Creator creator;
  final List<ScheduleBlock> blocks;
  final List<PostCluster> clusters;
}

/// 24時間の時間軸と、予定のブロック・投稿チップ（画面定義書 2.1.1）。
class TimeGrid extends StatelessWidget {
  const TimeGrid({
    super.key,
    required this.hourHeight,
    required this.columnWidth,
    required this.expanded,
    required this.day,
    required this.now,
    required this.columns,
    required this.onBlockTap,
    required this.onClusterTap,
    required this.emptyHint,
    this.selectedKey,
  });

  /// 時刻のラベルの列の幅。
  static const labelWidth = 40.0;

  final double hourHeight;
  final double columnWidth;

  /// 詳しい表示（予定のタイトル・時刻、投稿の本文を出す）。
  final bool expanded;

  /// 選んだ日。位置は、この日の0時から数える。
  final DateTime day;

  /// 現在時刻。終わった予定・投稿を薄くするのに使う。現在時刻の線は、今日を選んでいるときだけ出す。
  final DateTime now;
  final List<TimeGridColumn> columns;
  final void Function(ScheduleBlock block, Creator creator) onBlockTap;
  final void Function(PostCluster cluster, Creator creator) onClusterTap;

  /// その日に予定も投稿もないとき、小さなカードを重ねる。
  final bool emptyHint;

  /// 詳細のパネルで選んでいる要素（[ScheduleBlock.key]・[PostCluster.key]）。枠を付ける。
  final String? selectedKey;

  /// [time] の、[day] の時間軸の上での位置。その日より前は 0、後は 24時の位置に寄せる。
  static double offsetOf(DateTime time, DateTime day, double hourHeight) {
    final dayStart = DateTime(day.year, day.month, day.day);
    return (time.difference(dayStart).inMinutes / 60).clamp(0, 24) * hourHeight;
  }

  double _y(DateTime t) => offsetOf(t, day, hourHeight);

  bool get _showNowLine =>
      now.year == day.year && now.month == day.month && now.day == day.day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = hourHeight * 24;
    final totalWidth = columnWidth * columns.length;
    return SizedBox(
      height: height,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: TimeGridLinesPainter(
                hourHeight: hourHeight,
                major: c.gridMajor,
                minor: c.gridMinor,
              ),
            ),
          ),
          for (var i = 0; i < columns.length; i++)
            ..._columnChildren(context, columns[i], i * columnWidth),
          if (_showNowLine)
            Positioned(
              left: 0,
              right: 0,
              top: _y(now) - 0.75,
              child: Container(height: 1.5, color: c.now),
            ),
          if (emptyHint)
            Positioned(
              left: 0,
              right: 0,
              top: 150,
              child: Center(child: _EmptyHintCard()),
            ),
        ],
      ),
    );
  }

  List<Widget> _columnChildren(
    BuildContext context,
    TimeGridColumn column,
    double left,
  ) {
    final blocks = column.blocks;
    final clusters = column.clusters;
    final usable = columnWidth - 6;
    // ブロックとチップの、画面の上の縦の範囲。重なりは、時刻ではなく、この範囲で決める。
    final items = <ColumnItem>[
      for (final b in blocks)
        () {
          final top = _y(b.start);
          final height = (_y(b.end) - top).clamp(
            expanded ? 24.0 : 12.0,
            double.infinity,
          );
          return ColumnItem(top: top, bottom: top + height, isChip: false);
        }(),
      for (final cl in clusters)
        () {
          final height = _chipHeight(cl);
          // 投稿した時刻から下へ伸ばす。24時を越えないように、上へずらす。
          final top = _y(cl.time).clamp(0.0, hourHeight * 24 - height);
          return ColumnItem(top: top, bottom: top + height, isChip: true);
        }(),
    ];
    final slots = layoutColumn(items, usable);
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final item = items[i];
      final slot = slots[i];
      children.add(
        Positioned(
          left: left + 3 + slot.left,
          top: item.top,
          width: slot.width,
          height: item.bottom - item.top,
          child: FocusEffect(
            selectedKey: selectedKey,
            itemKey: b.key,
            color: SnsStyle.colorOf(context, b.service),
            child: TimeGridBlock(
              block: b,
              expanded: expanded,
              half: slot.width < usable,
              now: now,
              onTap: () => onBlockTap(b, column.creator),
            ),
          ),
        ),
      );
    }
    for (var i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      final item = items[blocks.length + i];
      final slot = slots[blocks.length + i];
      children.add(
        Positioned(
          left: left + 3 + slot.left,
          top: item.top,
          width: slot.width,
          height: item.bottom - item.top,
          child: FocusEffect(
            selectedKey: selectedKey,
            itemKey: cluster.key,
            color: SnsStyle.colorOf(context, cluster.posts.first.source),
            child: TimeGridClusterChip(
              cluster: cluster,
              expanded: expanded,
              past: cluster.time.isBefore(now),
              onTap: () => onClusterTap(cluster, column.creator),
            ),
          ),
        ),
      );
    }
    return children;
  }

  /// チップの高さ。縮小しているとき（1時間の高さが [compactHourHeight] 未満。24時間を1画面に収めているときを含む）は
  /// 2時間ぶん、それ以外は1時間ぶん。
  /// 詳しい表示は、「+N」は 30、投稿1件は本文2行ぶんの 36 より、そのほかは 26 より小さくしない。
  double _chipHeight(PostCluster cluster) {
    final hours = hourHeight < compactHourHeight ? 2 : 1;
    final min = !expanded ? 26.0 : (cluster.isGroup ? 30.0 : 36.0);
    return (hourHeight * hours).clamp(min, double.infinity);
  }

  /// これより1時間が低いと、縮小しているとみなす。
  static const compactHourHeight = 40.0;
}

/// その日の予定がないときのカード。
class _EmptyHintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 243,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A33).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.avatarFill,
            ),
            child: Icon(Icons.event, size: 22, color: c.primary),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.scheduleDayEmpty,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.scheduleDayEmptyHint, style: context.textStyles.caption),
        ],
      ),
    );
  }
}
