import '../../config/app_constants.dart';
import '../../utils/formatters.dart';
import 'oshi.dart';
import 'post.dart';
import 'schedule_filter.dart';
import 'schedule_item.dart';
import 'sns_service.dart';

/// タイムスケジュールの列に出す予定のブロック。配信中の配信（予定にないもの）も含める。
class ScheduleBlock {
  const ScheduleBlock({
    required this.creatorId,
    required this.title,
    required this.start,
    required this.end,
    required this.openEnded,
    required this.service,
    required this.isLiveNow,
    this.item,
  });

  final String creatorId;
  final String title;
  final DateTime start;
  final DateTime end;

  /// 終了時刻がない（終端をフェードさせる）。
  final bool openEnded;
  final SnsService? service;

  /// 配信中。
  final bool isLiveNow;

  /// 元の予定。配信中の配信で予定がなければ null。
  final ScheduleItem? item;

  bool isPastAt(DateTime now) => !isLiveNow && !end.isAfter(now);

  /// 詳細のパネルで、どの要素を選んでいるかを見分ける。データを読み直しても変わらない。
  String get key => item != null ? 'schedule:${item!.id}' : 'live:$creatorId';
}

/// 推しの列に出すブロックを作る。[schedules] は絞り込んだあとの予定。
/// 配信中の配信も、[filter] の「配信」とプラットフォームに従う（機能仕様書 4.5.5）。
List<ScheduleBlock> blocksFor(
  Oshi oshi,
  List<ScheduleItem> schedules,
  DateTime day,
  DateTime now, {
  ScheduleFilter filter = const ScheduleFilter(),
}) {
  final creator = oshi.creator;
  final current = creator.liveAt(now);
  final live =
      current != null &&
          filter.showLive &&
          filter.includesService(current.service)
      ? current
      : null;
  final blocks = <ScheduleBlock>[];
  var liveMatched = false;
  for (final s in schedules.where((s) => s.creatorId == oshi.id && !s.allDay)) {
    final end = s.displayEnd;
    final isLiveNow =
        live != null &&
        s.service == live.service &&
        !s.startsAt.isAfter(now) &&
        end.isAfter(now);
    if (isLiveNow) liveMatched = true;
    blocks.add(
      ScheduleBlock(
        creatorId: oshi.id,
        title: s.title,
        start: s.startsAt,
        // 終了未定の配信中は、今の時刻まで伸ばし、その先をフェードさせる。
        end: isLiveNow && s.endsAt == null ? now : end,
        openEnded: s.endsAt == null,
        service: s.service,
        isLiveNow: isLiveNow,
        item: s,
      ),
    );
  }
  if (live != null && !liveMatched && isSameDay(live.startedAt, day)) {
    blocks.add(
      ScheduleBlock(
        creatorId: oshi.id,
        title: live.title,
        start: live.startedAt,
        end: now,
        openEnded: true,
        service: live.service,
        isLiveNow: true,
      ),
    );
  }
  blocks.sort((a, b) => a.start.compareTo(b.start));
  return blocks;
}

/// 近接した投稿のまとまり（「+N」）。
class PostCluster {
  const PostCluster(this.posts);

  final List<Post> posts;

  DateTime get time => posts.first.postedAt;
  bool get isGroup => posts.length > 1;

  /// 含まれる SNS（重なりを除く。並びは [SnsService] の順で、新着が足されても入れ替わらない）。
  List<SnsService> get services {
    final found = {for (final p in posts) p.source};
    return [
      for (final s in SnsService.values)
        if (found.contains(s)) s,
    ];
  }

  /// 詳細のパネルで、どの要素を選んでいるかを見分ける。いちばん古い投稿で決める（新着が足されても変わらない）。
  String get key => 'posts:${posts.last.id}';
}

/// 投稿を、[postClusterGap] 以内のものでまとめる（決定事項 5）。
List<PostCluster> clusterPosts(Iterable<Post> posts) {
  final sorted = posts.toList()
    ..sort((a, b) => a.postedAt.compareTo(b.postedAt));
  final clusters = <List<Post>>[];
  for (final p in sorted) {
    if (clusters.isNotEmpty &&
        p.postedAt.difference(clusters.last.last.postedAt) <= postClusterGap) {
      clusters.last.add(p);
    } else {
      clusters.add([p]);
    }
  }
  return [for (final c in clusters) PostCluster(sortNewestFirst(c))];
}

/// 列の中の要素（予定のブロック・投稿チップ）の、画面の上の縦の範囲。
class ColumnItem {
  const ColumnItem({
    required this.top,
    required this.bottom,
    required this.isChip,
  });

  final double top;
  final double bottom;
  final bool isChip;
}

/// 列の中の位置。列の左端（余白の内側）からの距離と、幅。
typedef ColumnSlot = ({double left, double width});

/// 列の中の要素を並べる（画面定義書 2.1.1）。
/// 画面の上で重なる要素だけを横に分け、ほかと重ならない要素は幅 [usable] いっぱいにする。
/// 重なるまとまりの中では、ブロックを左、チップを右に分ける。ブロック同士は等分し、チップ同士は重ならない列に並べる。
List<ColumnSlot> layoutColumn(List<ColumnItem> items, double usable) {
  const gap = 2.0;
  final slots = List<ColumnSlot>.filled(items.length, (left: 0, width: usable));
  final order = List.generate(items.length, (i) => i)
    ..sort((a, b) => items[a].top.compareTo(items[b].top));

  void place(List<int> group) {
    if (group.length < 2) return;
    final blocks = [
      for (final i in group)
        if (!items[i].isChip) i,
    ];
    final chips = [
      for (final i in group)
        if (items[i].isChip) i,
    ];
    final blockArea = chips.isEmpty
        ? usable
        : (blocks.isEmpty ? 0.0 : (usable - gap) / 2);
    final chipLeft = blocks.isEmpty ? 0.0 : blockArea + gap;
    final chipArea = usable - chipLeft;
    if (blocks.isNotEmpty) {
      final w = (blockArea - gap * (blocks.length - 1)) / blocks.length;
      for (var k = 0; k < blocks.length; k++) {
        slots[blocks[k]] = (left: k * (w + gap), width: w);
      }
    }
    if (chips.isNotEmpty) {
      // 前のチップと重ならない、いちばん左の列に入れる。
      final laneBottoms = <double>[];
      final lanes = <int, int>{};
      for (final i in chips) {
        var lane = laneBottoms.indexWhere((b) => b <= items[i].top);
        if (lane < 0) {
          laneBottoms.add(items[i].bottom);
          lane = laneBottoms.length - 1;
        } else {
          laneBottoms[lane] = items[i].bottom;
        }
        lanes[i] = lane;
      }
      final n = laneBottoms.length;
      final w = (chipArea - gap * (n - 1)) / n;
      for (final i in chips) {
        slots[i] = (left: chipLeft + lanes[i]! * (w + gap), width: w);
      }
    }
  }

  var group = <int>[];
  var groupBottom = double.negativeInfinity;
  for (final i in order) {
    if (group.isNotEmpty && items[i].top < groupBottom) {
      group.add(i);
      if (items[i].bottom > groupBottom) groupBottom = items[i].bottom;
    } else {
      place(group);
      group = [i];
      groupBottom = items[i].bottom;
    }
  }
  place(group);
  return slots;
}
