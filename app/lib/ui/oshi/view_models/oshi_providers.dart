import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_type.dart';
import '../../../domain/models/follow.dart';
import '../../../domain/models/oshi.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import '../../core/view_models/guard.dart';
import '../../core/view_models/refresh.dart';

/// おすすめの発信者（機能仕様書 4.2.2.2）。サーバーがランダムに選ぶので、読むたびに変わる。
/// 画面を開いている間は同じ一覧にするため、定期的には読み直さず、フォローを変えても読み直さない。
/// 画面の ViewModel が聞いている間だけ持ち、閉じたら捨てる（次に開いたときに選び直す）。
final recommendedCreatorsProvider = FutureProvider.autoDispose<List<Creator>>(
  (ref) =>
      withSession(ref, (_) => ref.watch(creatorRepositoryProvider).recommend()),
);

/// 発信者のタイプの一覧（機能仕様書 4.6.4）。画面を開くたびに読む（運営が SQL で直すため）。
final creatorTypesProvider = FutureProvider.autoDispose<List<CreatorType>>(
  (ref) => withSession(
    ref,
    (_) => ref.watch(creatorRepositoryProvider).fetchTypes(),
  ),
);

/// 推しを探す・推しを選ぶに出す発信者（機能仕様書 4.2.2）。
/// 言葉が空なら、おすすめ。言葉があれば、打ち終わって [searchDebounce] 待ってから、サーバーで探す。
/// 待つ間に言葉が変わったら、問い合わせない。古い言葉の結果は、Riverpod が捨てる。
Future<List<Creator>> findCreators(Ref ref, String query) async {
  final q = query.trim();
  if (q.isEmpty) return ref.watch(recommendedCreatorsProvider.future);
  await Future<void>.delayed(searchDebounce);
  if (!ref.mounted) return const [];
  return withSession(
    ref,
    (_) => ref.watch(creatorRepositoryProvider).search(q),
  );
}

/// 推しを探す・推しを選ぶに出す発信者を、言葉ごとに持つ（[findCreators]）。
/// 言葉が変わると、前の言葉の分は捨てる（待っている間なら、問い合わせない）。
/// 画面の ViewModel が、いまの言葉の分だけを聞く。
final searchedCreatorsProvider = FutureProvider.autoDispose
    .family<List<Creator>, String>(findCreators);

/// 1人の発信者。1分ごとに読み直す。
final creatorProvider = FutureProvider.autoDispose.family<Creator?, String>(
  (ref, id) => withSession(ref, (_) {
    refreshPeriodically(ref);
    return ref.watch(creatorRepositoryProvider).fetchById(id);
  }),
);

/// フォロー（フォローした順）。フォローを変えたときは、`ref.invalidate` で読み直す。
final followsProvider = AsyncNotifierProvider<Follows, List<Follow>>(
  Follows.new,
);

class Follows extends AsyncNotifier<List<Follow>> {
  @override
  Future<List<Follow>> build() => withSession(ref, (_) {
    refreshPeriodically(ref);
    return ref.watch(followRepositoryProvider).fetchAll();
  });

  /// 発信者ページを開いたとき、その推しを既読にする（機能仕様書 4.2.3）。
  /// サーバーへの書き込みを待たず、手元のフォローを先に変えるので、ホームの「NEW」がその場で消える。
  /// 書き込みに失敗しても、次の読み直しで、サーバーの状態に戻るだけ。
  void markSeen(String creatorId) {
    _applySeen(creatorId, ref.read(clockProvider)());
    ref.read(followRepositoryProvider).markSeen(creatorId).catchError((_) {});
  }

  /// 手元のフォローに、既読の時刻を入れる。読み直しの途中なら、終わってから入れる
  /// （途中で入れると、読み直す前の一覧で上書きして、読み直した結果を消してしまう）。
  void _applySeen(String creatorId, DateTime at) {
    if (state.isLoading) {
      future.then((_) {
        if (ref.mounted) _applySeen(creatorId, at);
      }, onError: (_) {});
      return;
    }
    final follows = state.value;
    if (follows == null) return;
    state = AsyncData([
      for (final f in follows)
        f.creatorId == creatorId ? f.copyWith(lastSeenAt: at) : f,
    ]);
  }
}

/// フォロー中の推し（フォローの情報と、発信者の情報の組）。フォローした順。
final oshisProvider = FutureProvider<List<Oshi>>((ref) async {
  final follows = await ref.watch(followsProvider.future);
  final ids = [for (final f in follows) f.creatorId];
  final creators = await ref.watch(creatorRepositoryProvider).fetchMany(ids);
  final byId = {for (final c in creators) c.id: c};
  return [
    for (final f in follows)
      if (byId[f.creatorId] case final creator?)
        Oshi(follow: f, creator: creator),
  ];
});

/// フォロー中の発信者 ID。
final followedIdsProvider = Provider<Set<String>>(
  (ref) => {
    for (final f in ref.watch(followsProvider).value ?? const <Follow>[])
      f.creatorId,
  },
);

/// 指定の発信者のフォロー（フォローしていなければ null）。
final followOfProvider = Provider.family<Follow?, String>(
  (ref, creatorId) => ref
      .watch(followsProvider)
      .value
      ?.where((f) => f.creatorId == creatorId)
      .firstOrNull,
);

/// フォロー・解除の操作。推しリスト、推しを探す、推しを選ぶ、発信者ページで共有する。
class FollowActions extends Notifier<void> {
  @override
  void build() {}

  /// フォロー・解除を送っている発信者 ID。続けて押しても、2回送らない（機能仕様書 4.2.1）。
  final _inFlight = <String>{};

  /// フォローを切り替える。失敗したら false。送っている間に押されたら、何もせず true。
  Future<bool> toggle(String creatorId) async {
    if (!_inFlight.add(creatorId)) return true;
    try {
      final repo = ref.read(followRepositoryProvider);
      final following = ref.read(followedIdsProvider).contains(creatorId);
      if (following) {
        await repo.unfollow(creatorId);
      } else {
        await repo.follow(creatorId);
      }
      ref.invalidate(followsProvider);
      // 読み直すまでは、ボタンが前の状態のままなので、次の押下を弾き続ける。
      try {
        await ref.read(followsProvider.future);
      } catch (_) {
        // 送るのはできた。読み直しの失敗は、各画面が出す。
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _inFlight.remove(creatorId);
    }
  }

  Future<bool> setNotify(String creatorId, bool notify) => succeeded(() async {
    await ref.read(followRepositoryProvider).setNotify(creatorId, notify);
    ref.invalidate(followsProvider);
  });
}

final followActionsProvider = NotifierProvider<FollowActions, void>(
  FollowActions.new,
);
