import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_search.dart';
import '../../../domain/models/oshi.dart';
import '../../../domain/models/schedule_item.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import '../../core/view_models/playback_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../home/view_models/home_providers.dart';
import '../../schedule/view_models/schedule_providers.dart';
import 'oshi_providers.dart';

/// 推しリストの1行。
class OshiListEntry {
  const OshiListEntry({required this.oshi, required this.live, this.next});

  final Oshi oshi;
  final Live? live;

  /// 配信中でないときに出す、次の予定。
  final ScheduleItem? next;
}

/// 推しリストに出すもの（検索の言葉と、推し全員）。
class OshiListState {
  const OshiListState({
    this.query = '',
    this.entries = const AsyncLoading(),
    this.oshis,
    this.viewer = const HomeLiveViewerState(),
  });

  /// 検索の言葉。
  final String query;

  /// 配信中の推しを先に並べた、フォロー中の推し全員。読み込み中と失敗も、ここに入る。
  final AsyncValue<List<OshiListEntry>> entries;

  /// フォロー中の推し（推しレーンの順）。読めていなければ null。
  final List<Oshi>? oshis;

  /// ホームの配信ビューア（初期位置モードで出している推し）。
  final HomeLiveViewerState viewer;

  /// 検索の言葉で絞り込んだ一覧。まだ読めていなければ空。
  List<OshiListEntry> get filtered {
    final all = entries.value ?? const <OshiListEntry>[];
    final matched = filterCreators([
      for (final e in all) e.oshi.creator,
    ], query).map((c) => c.id).toSet();
    return all.where((e) => matched.contains(e.oshi.id)).toList();
  }

  /// フォロー中の推しが0人か（読めたときだけ真）。
  bool get empty => entries.value?.isEmpty ?? false;

  /// 配信ビューアで流している推しの ID（赤いリング）。ホームの推しレーンと同じく決める。
  String? playingCreatorId(DateTime now, Playback? playback) =>
      playingLiveCreatorId(
        oshis ?? [for (final e in filtered) e.oshi],
        now,
        playback,
        viewer,
      );

  /// 推しはいるが、検索の言葉に合う推しがいないか。
  bool get noMatch =>
      !empty && query.trim().isNotEmpty && entries.hasValue && filtered.isEmpty;

  OshiListState copyWith({
    String? query,
    AsyncValue<List<OshiListEntry>>? entries,
  }) => OshiListState(
    query: query ?? this.query,
    entries: entries ?? this.entries,
    oshis: oshis,
    viewer: viewer,
  );
}

/// 推しリストに出す推し。配信中を先に並べ、配信中でなければ次の予定を添える。
final _oshiListEntriesProvider = FutureProvider<List<OshiListEntry>>((
  ref,
) async {
  final now = ref.read(clockProvider)();
  final oshis = await ref.watch(oshisProvider.future);
  final upcoming = oshis.isEmpty
      ? const <ScheduleItem>[]
      : await ref.watch(upcomingSchedulesProvider.future);
  final nextOf = <String, ScheduleItem>{};
  for (final s in upcoming) {
    nextOf.putIfAbsent(s.creatorId, () => s);
  }
  return [
    for (final o in Oshi.liveFirst(oshis, now))
      OshiListEntry(oshi: o, live: o.creator.liveAt(now), next: nextOf[o.id]),
  ];
});

/// 推しリスト（画面定義書 2.3.1）。配信中の推しを先に並べ、検索で絞り込む。
class OshiListViewModel extends Notifier<OshiListState> {
  @override
  OshiListState build() => OshiListState(
    query: stateOrNull?.query ?? '',
    entries: ref.watch(_oshiListEntriesProvider),
    oshis: ref.watch(oshisProvider).value,
    viewer: ref.watch(homeLiveViewerProvider),
  );

  void setQuery(String query) => state = state.copyWith(query: query);

  /// フォローを外す。失敗したら false。
  Future<bool> unfollow(String creatorId) =>
      ref.read(followActionsProvider.notifier).toggle(creatorId);

  /// 引っ張って更新・「もう一度試す」。サインインからやり直し、フォローと一覧を読み直す。
  Future<void> refresh() => reloadFrom(ref, [
    authSessionProvider,
    followsProvider,
    _oshiListEntriesProvider,
  ], awaiting: () => ref.read(_oshiListEntriesProvider.future));
}

final oshiListViewModelProvider =
    NotifierProvider<OshiListViewModel, OshiListState>(OshiListViewModel.new);
