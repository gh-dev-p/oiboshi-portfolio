import 'creator.dart';
import 'follow.dart';

/// 推しのアイコンのリングで表す状態。
enum OshiRing { live, hasNew, read }

/// フォロー中の推し。フォローの情報と、発信者の情報の組。
class Oshi {
  const Oshi({required this.follow, required this.creator});

  final Follow follow;
  final Creator creator;

  String get id => creator.id;

  /// 最後に見てから、新しい投稿があるか。
  bool hasNewAt(DateTime now) {
    final latest = creator.latestPostAt;
    return latest != null && follow.isNew(latest, now: now);
  }

  OshiRing ringAt(DateTime now) {
    if (creator.liveAt(now) != null) return OshiRing.live;
    if (hasNewAt(now)) return OshiRing.hasNew;
    return OshiRing.read;
  }

  /// 配信中、新着あり、それ以外の順に並べる。同じ中では、フォローした順のまま（ホームの推しレーン）。
  static List<Oshi> byStatus(List<Oshi> oshis, DateTime now) => [
    for (final ring in OshiRing.values)
      ...oshis.where((o) => o.ringAt(now) == ring),
  ];

  /// 配信中を先に、それ以外はフォローした順のまま並べる。
  static List<Oshi> liveFirst(List<Oshi> oshis, DateTime now) => [
    ...oshis.where((o) => o.creator.liveAt(now) != null),
    ...oshis.where((o) => o.creator.liveAt(now) == null),
  ];
}
