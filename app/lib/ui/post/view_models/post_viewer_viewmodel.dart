import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/post.dart';
import '../../core/view_models/playback_provider.dart';

/// 投稿ビューアで見るもの。Provider のキーに使うので、値で等しさを決める（アーキテクチャ設計書 4.2）。
class PostViewerArgs {
  const PostViewerArgs({
    required this.posts,
    required this.initialIndex,
    this.initialStart = Duration.zero,
  });

  /// 見る投稿（上下のスワイプで前後に移る）。
  final List<Post> posts;

  /// 最初に見る投稿の位置。
  final int initialIndex;

  /// 最初の投稿の動画を、始める位置（固定ビューアから開いたときの続き）。
  final Duration initialStart;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PostViewerArgs ||
        other.initialIndex != initialIndex ||
        other.initialStart != initialStart ||
        other.posts.length != posts.length) {
      return false;
    }
    for (var i = 0; i < posts.length; i++) {
      if (!identical(other.posts[i], posts[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(initialIndex, initialStart, Object.hashAll(posts));
}

/// 投稿ビューアの状態。
class PostViewerState {
  const PostViewerState({required this.index});

  /// いま見ている投稿の位置。
  final int index;
}

/// 投稿ビューア（画面定義書 2.5.1）。いま見ている投稿と、「固定ビューアで流す」の操作。
/// PageController・動画の再生位置を聞く窓口・カルーセルの見ている枚数は、表示用の状態なので View が持つ。
class PostViewerViewModel extends Notifier<PostViewerState> {
  PostViewerViewModel(this.args);

  final PostViewerArgs args;

  @override
  PostViewerState build() => PostViewerState(index: args.initialIndex);

  List<Post> get posts => args.posts;

  /// いま見ている投稿。
  Post get current => posts[state.index];

  /// 上下のスワイプで、[index] の投稿に移った。
  void showPost(int index) => state = PostViewerState(index: index);

  /// [index] の投稿の動画を始める位置。最初の投稿だけ、固定ビューアから開いたときの続き。
  Duration startOf(int index) =>
      index == args.initialIndex ? args.initialStart : Duration.zero;

  /// いまの投稿の動画を、見ていた位置から固定ビューアで流す（画面定義書 2.4.3）。
  /// [position] は、動画のいまの再生位置（分からなければ、最初から流す）。
  /// [canOpenAuthor] は、このビューアで投稿者を押せるか（固定ビューアから開き直すビューアでも同じにする）。
  /// 固定ビューアで流したあと、ビューアを閉じるのは View が行う。
  Future<void> minimize({
    required Creator? author,
    required Future<Duration?> Function() position,
    bool canOpenAuthor = false,
  }) async {
    final post = current;
    final start = await position() ?? Duration.zero;
    if (!ref.mounted) return;
    final playback = ref.read(playbackProvider.notifier);
    // ランダム再生で流している動画なら、位置だけ渡して、ランダム再生を続ける（機能仕様書 4.3.5.1）。
    if (ref.read(playbackProvider) case PostPlayback(
      shuffle: _?,
      post: Post(:final id),
    ) when id == post.id) {
      playback.seek(post.id, start);
      return;
    }
    playback.playPost(post, author, start, canOpenAuthor: canOpenAuthor);
  }
}

final postViewerViewModelProvider = NotifierProvider.autoDispose
    .family<PostViewerViewModel, PostViewerState, PostViewerArgs>(
      PostViewerViewModel.new,
    );
