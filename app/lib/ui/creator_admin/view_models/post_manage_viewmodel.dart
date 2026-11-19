import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/post.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/guard.dart';
import '../../core/view_models/playback_provider.dart';
import '../../core/view_models/removed_posts_provider.dart';
import 'creator_admin_providers.dart';

/// 投稿の管理に出すもの（自分の投稿と、自分の発信者）。
class PostManageState {
  const PostManageState({
    required this.posts,
    this.hiddenIds = const {},
    this.creator,
  });

  /// 自分の投稿（隠した投稿も含めて、新しい順）。読み込み中と失敗も、ここに入る。
  final AsyncValue<List<Post>> posts;

  /// [posts] のうち、隠している投稿の ID。
  final Set<String> hiddenIds;

  /// 自分の発信者。X の投稿の行（X の投稿者の行）に、アイコン・名前を出す。読めていなければ null。
  final Creator? creator;

  PostManageState copyWith({Set<String>? hiddenIds}) => PostManageState(
    posts: posts,
    hiddenIds: hiddenIds ?? this.hiddenIds,
    creator: creator,
  );
}

/// 自分の投稿（ファンに見えている投稿と、隠した投稿）。
final _postManagePostsProvider = FutureProvider.autoDispose
    .family<({List<Post> posts, Set<String> hiddenIds}), String>(
      (ref, creatorId) => withSession(ref, (_) async {
        final repository = ref.watch(postRepositoryProvider);
        final (shown, hidden) = await (
          repository.fetchByCreator(creatorId),
          repository.fetchHiddenByCreator(creatorId),
        ).wait;
        return (
          posts: sortNewestFirst([...shown, ...hidden]),
          hiddenIds: {for (final p in hidden) p.id},
        );
      }),
    );

/// 投稿の管理（画面定義書（設定・発信者向け）2.3.8）。自分の投稿を新しい順に並べ、隠す・また出す（機能仕様書 4.4.4）。
/// 出すのは、ファンに見えている投稿と、隠している投稿。
class PostManageViewModel extends Notifier<PostManageState> {
  PostManageViewModel(this.creatorId);

  final String creatorId;

  @override
  PostManageState build() {
    // 発信者は、投稿を読み直さないよう、build し直さずに写す。
    final creator = creatorAdminDataProvider(creatorId);
    ref.listen(
      creator,
      (_, data) => state = PostManageState(
        posts: state.posts,
        hiddenIds: state.hiddenIds,
        creator: data.value?.creator,
      ),
    );
    final loaded = ref.watch(_postManagePostsProvider(creatorId));
    return PostManageState(
      posts: loaded.whenData((l) => l.posts),
      hiddenIds: loaded.value?.hiddenIds ?? const {},
      creator: ref.read(creator).value?.creator,
    );
  }

  /// [post] を隠す（[hidden] が真）・また出す。できたら true。
  /// 一覧の見た目を変え、投稿を出している画面（ホーム・発信者ページ・スケジュール）を読み直す。
  /// 隠した投稿を固定ビューアで流していたら、閉じる。
  Future<bool> setHidden(Post post, {required bool hidden}) async {
    // 画面を閉じても届くように、先に取っておく（どちらも、この画面より長く生きる）。
    final removed = ref.read(removedPostsProvider.notifier);
    final playback = ref.read(playbackProvider.notifier);
    if (!await succeeded(
      () => ref.read(postRepositoryProvider).setHidden(post.id, hidden: hidden),
    )) {
      return false;
    }
    if (hidden) {
      removed.add(post.id);
      playback.endPost(post.id);
    } else {
      removed.restore(post.id);
    }
    if (ref.mounted) {
      state = state.copyWith(
        hiddenIds: hidden
            ? {...state.hiddenIds, post.id}
            : ({...state.hiddenIds}..remove(post.id)),
      );
    }
    return true;
  }

  /// 読み込めなかったときに、読み直す。
  void retry() {
    retryCreatorAdmin(ref, creatorId);
    ref.invalidate(_postManagePostsProvider(creatorId));
  }
}

final postManageViewModelProvider = NotifierProvider.autoDispose
    .family<PostManageViewModel, PostManageState, String>(
      PostManageViewModel.new,
    );
