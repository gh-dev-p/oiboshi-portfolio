import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/follow.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/report.dart';
import '../../../domain/models/schedule_item.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/guard.dart';
import '../../core/view_models/refresh.dart';
import '../../core/view_models/removed_posts_provider.dart';
import '../../oshi/view_models/oshi_providers.dart';
import '../../schedule/view_models/schedule_providers.dart';
import 'creator_providers.dart';
import '../../settings/view_models/settings_providers.dart';

/// 発信者ページに出すもの。
class CreatorPageState {
  const CreatorPageState({
    required this.creator,
    required this.follow,
    required this.posts,
    required this.next,
    this.events = const [],
    required this.seenBefore,
    this.showMenu = false,
  });

  final Creator creator;

  /// フォロー中なら、そのフォロー。
  final Follow? follow;

  /// 残してある投稿すべて（新しい順）。
  final List<Post> posts;

  /// 次の予定（イベントを除く）。
  final ScheduleItem? next;

  /// これからのイベント（日付順。開催中を含む）。「イベント」の面には [upcomingEventCount] 件まで出す。
  final List<ScheduleItem> events;

  /// このページを開く前に最後に見た時刻。「ここまで新着」の区切りに使う。
  final DateTime? seenBefore;

  /// メニュー（「通報する」「この発信者を表示しない」）を出すか。自分がオーナーの発信者には出さない。
  final bool showMenu;

  bool get following => follow != null;

  /// 月のカレンダーへのボタンに印を付けるか。次の予定かイベントがあれば付ける（画面定義書 2.4.1・2.4.2）。
  bool get hasUpcoming => next != null || events.isNotEmpty;

  /// ファンが選んだ自分の写真（カバーの裏）。なければ null。
  String? get ownCoverUrl => follow?.coverUrl;

  /// 自分の写真があり、カバーを裏返せるか（機能仕様書 4.2.4）。
  bool get hasOwnCover => ownCoverUrl != null;

  /// カバーで、自分の写真（裏）を出しているか。偽なら、発信者のカバー（表）。
  bool get showingOwnCover => hasOwnCover && follow!.showOwnCover;

  /// 出すカバー画像。自分の写真の面を出していなければ、発信者のカバー。
  String? get coverUrl => showingOwnCover ? ownCoverUrl : creator.coverUrl;

  Live? liveAt(DateTime now) => creator.liveAt(now);

  /// 「ここまで新着」の区切りを出す位置（この添字の投稿の直後）。出さなければ null。
  int? newDividerIndexAt(DateTime now) {
    final seen = seenBefore;
    if (seen == null) return null;
    var count = 0;
    for (final p in posts) {
      if (isNewSince(p.postedAt, seenAt: seen, now: now)) {
        count++;
      } else {
        break;
      }
    }
    return count > 0 && count < posts.length ? count - 1 : null;
  }

  CreatorPageState copyWith({Follow? follow, bool clearFollow = false}) =>
      CreatorPageState(
        creator: creator,
        follow: clearFollow ? null : follow ?? this.follow,
        posts: posts,
        next: next,
        events: events,
        seenBefore: seenBefore,
        showMenu: showMenu,
      );
}

/// カバーを自分の写真に変えた結果。
enum CoverChangeResult {
  /// 変えた。
  changed,

  /// 写真を選ばなかった。
  cancelled,

  /// 保存に失敗した。
  failed,
}

/// カメラのアイコンのメニュー（画面定義書 2.4.1）で選んだもの。
enum CoverMenuAction {
  /// 写真を選ぶ。
  pick,

  /// 推しが設定したカバーに戻す。
  reset,
}

/// 1人の発信者の投稿。1分ごとに読み直す。この画面だけで使う（テストが、1分ごとの読み直しを再現するために読む）。
@visibleForTesting
final creatorPostsProvider = FutureProvider.autoDispose
    .family<List<Post>, String>(
      (ref, creatorId) => withSession(ref, (_) {
        // 追星から投稿を消したら、読み直す（機能仕様書 4.4.4）。
        ref.watch(removedPostsProvider);
        refreshPeriodically(ref);
        return ref.watch(postRepositoryProvider).fetchByCreator(creatorId);
      }),
    );

/// 発信者ページ（画面定義書 2.4）。
class CreatorViewModel extends AsyncNotifier<CreatorPageState> {
  CreatorViewModel(this.creatorId);

  final String creatorId;
  DateTime? _seenBefore;
  bool _marked = false;

  /// このページで裏返して選んだ面。フォローの読み直しが届く前に戻らないよう、読んだ値より優先する。
  bool? _showOwnCover;

  /// 面の保存。押した順に送る。
  Future<void> _coverSideSave = Future.value();

  @override
  Future<CreatorPageState> build() async {
    final creator = await ref.watch(creatorProvider(creatorId).future);
    if (creator == null) throw StateError('creator not found');
    var follow = ref.watch(followOfProvider(creatorId));
    final side = _showOwnCover;
    if (follow != null && side != null) {
      follow = follow.copyWith(showOwnCover: side);
    }
    final posts = await ref.watch(creatorPostsProvider(creatorId).future);
    final next = await ref.watch(nextScheduleProvider(creatorId).future);
    final events = await ref.watch(
      eventsProvider(EventsKey([creatorId])).future,
    );
    if (follow != null && !_marked) {
      // 開いたときに既読にする。区切りは、開く前の時刻で判定する。
      // 手元のフォローも書き換えて、ホームの「NEW」をその場で消す（組み立ての途中では、ほかの Provider を変えられないので、後で）。
      _seenBefore = follow.seenAt;
      _marked = true;
      Future.microtask(() {
        if (ref.mounted) ref.read(followsProvider.notifier).markSeen(creatorId);
      });
    }
    // 自分の発信者かは、読めるまで分からないので、メニューを出さない（読めなかったときは出す）。
    final owned = ref.watch(ownedCreatorProvider);
    return CreatorPageState(
      creator: creator,
      follow: follow,
      posts: posts,
      next: next,
      events: events,
      seenBefore: _seenBefore,
      showMenu: owned.hasValue ? owned.value?.id != creatorId : owned.hasError,
    );
  }

  /// 通報の対象（この発信者）。
  ReportTarget? get reportTarget => switch (state.value?.creator) {
    final creator? => CreatorReportTarget(
      creatorId: creator.id,
      name: creator.name,
    ),
    null => null,
  };

  /// この発信者を表示しないにする（機能仕様書 4.2.6）。先に表示しない発信者に足し、そのあとフォローを外す
  /// （ファンのカバー画像は、フォローを外す処理で消す）。足せなければ、何も外さずに false。
  /// 足したあと、フォローを外せなくても、表示しないにはできているので true。
  Future<bool> hide() async {
    final ok = await succeeded(
      () => ref.read(hiddenCreatorRepositoryProvider).hide(creatorId),
    );
    if (!ok) return false;
    if (ref.read(followedIdsProvider).contains(creatorId)) {
      await succeeded(
        () => ref.read(followRepositoryProvider).unfollow(creatorId),
      );
    }
    // 推しを探す・推しを選ぶは、表示しない発信者を手元でも除く（おすすめは選び直さない）。
    if (ref.mounted) {
      ref
        ..invalidate(followsProvider)
        ..invalidate(hiddenCreatorsProvider)
        ..invalidate(searchedCreatorsProvider);
    }
    return true;
  }

  Future<bool> toggleFollow() =>
      ref.read(followActionsProvider.notifier).toggle(creatorId);

  Future<bool> toggleNotify() async {
    final follow = state.value?.follow;
    if (follow == null) return false;
    return ref
        .read(followActionsProvider.notifier)
        .setNotify(creatorId, !follow.notify);
  }

  /// 端末の写真を選んで、カバーを自分の写真に変える。
  Future<CoverChangeResult> pickAndSetCover() async {
    final jpeg = await ref
        .read(imagePickerServiceProvider)
        .pickImage(maxSide: 1600);
    if (jpeg == null) return CoverChangeResult.cancelled;
    if (!ref.mounted) return CoverChangeResult.cancelled;
    try {
      await ref.read(followRepositoryProvider).setCover(creatorId, jpeg);
      // 選んだ直後は、裏（自分の写真）を出す。サーバーにも、裏を出すと書いた。
      _showOwnCover = null;
      if (ref.mounted) ref.invalidate(followsProvider);
      return CoverChangeResult.changed;
    } catch (_) {
      return CoverChangeResult.failed;
    }
  }

  /// カバーを裏返す（自分の写真と、発信者のカバーを切り替える）。どちらを出すかは、サーバーに覚える。
  /// 覚えられなくても、知らせない（次に読み直したときに、覚えていた面に戻る）。
  Future<void> flipCover() {
    final current = state.value;
    final follow = current?.follow;
    if (current == null || follow == null || !current.hasOwnCover) {
      return _coverSideSave;
    }
    final next = !follow.showOwnCover;
    _showOwnCover = next;
    state = AsyncData(
      current.copyWith(follow: follow.copyWith(showOwnCover: next)),
    );
    final repo = ref.read(followRepositoryProvider);
    return _coverSideSave = _coverSideSave.then((_) async {
      try {
        await repo.setShowOwnCover(creatorId, next);
        // 次にページを開いたときも、この面を出すように、フォローを読み直す。
        if (ref.mounted && _showOwnCover == next) {
          ref.invalidate(followsProvider);
        }
      } catch (_) {}
    });
  }

  /// 「推しが設定したカバーに戻す」。自分の写真を消す。
  Future<CoverChangeResult> resetCover() async {
    try {
      await ref.read(followRepositoryProvider).resetCover(creatorId);
      _showOwnCover = null;
      if (!ref.mounted) return CoverChangeResult.changed;
      // フォローの読み直しを待たずに、発信者のカバーに戻す。
      final current = state.value;
      final follow = current?.follow;
      if (current != null && follow != null) {
        state = AsyncData(
          current.copyWith(follow: follow.copyWith(clearCover: true)),
        );
      }
      ref.invalidate(followsProvider);
      return CoverChangeResult.changed;
    } catch (_) {
      return CoverChangeResult.failed;
    }
  }

  /// 配信が終わったと分かった。その配信を固定ビューアで流していたら、知らせて閉じる（画面定義書 2.4.3）。
  /// 終わりの判定は [LiveEndWatcher] にまとめる（知らせと、終わったばかりの配信を選ばない扱いを揃える）。
  void endLive() => ref.read(liveEndWatcherProvider.notifier).end(creatorId);

  /// 読み直す。読み込めなかったときの「もう一度試す」と、引いて更新で使う。
  Future<void> refresh() => reloadFrom(
    ref,
    [
      authSessionProvider,
      creatorProvider(creatorId),
      creatorPostsProvider(creatorId),
    ],
    awaiting: () {
      ref.invalidateSelf();
      return future;
    },
  );
}

final creatorViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CreatorViewModel, CreatorPageState, String>(CreatorViewModel.new);
