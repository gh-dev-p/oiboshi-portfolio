import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/last_playback.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/sns_service.dart';
import 'post_shuffle_provider.dart';
import '../../../config/service_providers.dart';

/// いま固定ビューアで流しているもの（画面定義書 2.4.3）。1つだけ。
sealed class Playback {
  const Playback();
}

/// 配信。発信者ページの「固定ビューアで見る」などで入り、固定ビューアを閉じると空になる。
class LivePlayback extends Playback {
  const LivePlayback({
    required this.creatorId,
    required this.live,
    this.avatarUrl,
  });

  final String creatorId;
  final Live live;

  /// 推しのアイコン。配信ビューアの帯に出す。
  final String? avatarUrl;
}

/// 投稿の動画。投稿ビューアの「固定ビューアで流す」で入る。[start] の位置から流す。
class PostPlayback extends Playback {
  const PostPlayback({
    required this.post,
    required this.author,
    required this.start,
    this.canOpenAuthor = false,
    this.shuffle,
  });

  final Post post;
  final Creator? author;
  final Duration start;

  /// 固定ビューアを押して開くビューアで、投稿者を押せるか。固定ビューアで流す前のビューアと同じにする（画面定義書（ファン）2.5.1）。
  final bool canOpenAuthor;

  /// ランダム再生のとき、その順番。ランダム再生でなければ null。
  final ShufflePlay? shuffle;
}

/// ランダム再生（試作）。フォロー中の推しの動画を、[order] の順に流す。
class ShufflePlay {
  const ShufflePlay({required this.order, required this.authors});

  final PostShuffle order;

  /// 推し（発信者 ID ごと）。帯のアイコンと、投稿のビューアの投稿者に使う。
  final Map<String, Creator> authors;
}

/// 配信に切り替える前のランダム再生（[PlaybackNotifier.suspendedShuffle]）。
class SuspendedShuffle {
  const SuspendedShuffle({required this.playback, required this.paused});

  /// 流していた動画と、切り替える直前の位置（[PostPlayback.start]）、シャッフルの順番。
  final PostPlayback playback;

  /// 止めていたか（コントローラーで止めた、またはプレイヤーで一時停止した）。
  final bool paused;
}

class PlaybackNotifier extends Notifier<Playback?> {
  @override
  Playback? build() => null;

  /// ランダム再生から配信に切り替えたときの、ランダム再生の状態（機能仕様書 4.3.5）。
  /// ランダム再生に戻したとき、新しくシャッフルし直さず、同じ順番の同じ動画を、同じ位置から続ける。
  /// 端末内には覚えない（アプリを開き直したときは、[LastPlaybackRecorder] で続きから流す）。
  SuspendedShuffle? _suspended;

  /// 配信に切り替える前のランダム再生。なければ null。
  SuspendedShuffle? get suspendedShuffle => _suspended;

  /// 配信を流す（または、配信の情報が新しくなった）。流していたものは、配信に切り替える。
  /// ランダム再生を流していたら、その状態を控える（[resumeSuspendedShuffle] で戻す）。
  void play(String creatorId, Live live, {String? avatarUrl}) {
    final current = state;
    if (current is LivePlayback &&
        current.creatorId == creatorId &&
        identical(current.live, live) &&
        (avatarUrl == null || current.avatarUrl == avatarUrl)) {
      return;
    }
    if (current is PostPlayback && current.shuffle != null) {
      _suspended = SuspendedShuffle(
        playback: current,
        paused: ref.read(fixedViewerPausedProvider),
      );
    }
    state = LivePlayback(
      creatorId: creatorId,
      live: live,
      avatarUrl:
          avatarUrl ??
          (current is LivePlayback && current.creatorId == creatorId
              ? current.avatarUrl
              : null),
    );
  }

  /// 投稿の動画を、固定ビューアで流す。流していたものは、この動画に切り替える。
  void playPost(
    Post post,
    Creator? author,
    Duration start, {
    bool canOpenAuthor = false,
  }) => state = PostPlayback(
    post: post,
    author: author,
    start: start,
    canOpenAuthor: canOpenAuthor,
  );

  /// 流している投稿の動画を、[start] の位置から流し直すようにする（投稿ビューアで見ていた位置から続けるとき）。
  /// その投稿を流していなければ、何もしない。
  void seek(String postId, Duration start) {
    final current = state;
    if (current is! PostPlayback || current.post.id != postId) return;
    state = PostPlayback(
      post: current.post,
      author: current.author,
      start: start,
      canOpenAuthor: current.canOpenAuthor,
      shuffle: current.shuffle,
    );
  }

  /// 控えたランダム再生の、切り替える直前の再生位置と、止めていたかを書き直す（固定ビューアが、配信に切り替わったときに知らせる）。
  /// 控えた動画と違えば、何もしない。
  void updateSuspended(
    String postId, {
    required Duration position,
    required bool paused,
  }) {
    final suspended = _suspended;
    if (suspended == null || suspended.playback.post.id != postId) return;
    final p = suspended.playback;
    _suspended = SuspendedShuffle(
      playback: PostPlayback(
        post: p.post,
        author: p.author,
        start: position,
        canOpenAuthor: p.canOpenAuthor,
        shuffle: p.shuffle,
      ),
      paused: paused,
    );
  }

  /// 配信に切り替える前のランダム再生に戻す（同じ順番の同じ動画を、同じ位置から。止めていたら、止めたまま）。
  /// 控えたものがない、または [canPlay] がその動画を流せないとしたら（追星から消した・推しでなくなったなど）、
  /// 控えたものを捨てて、偽を返す。
  bool resumeSuspendedShuffle({bool Function(Post post)? canPlay}) {
    final suspended = _suspended;
    _suspended = null;
    if (suspended == null) return false;
    if (canPlay != null && !canPlay(suspended.playback.post)) return false;
    state = suspended.playback;
    // 流すものが替わると止めていたのをやめるので、そのあとで止め直す。
    ref.read(fixedViewerPausedProvider.notifier).set(suspended.paused);
    return true;
  }

  /// ランダム再生を始める。流していたものは、[order] の最初の動画に切り替える。
  void playShuffle(PostShuffle order, Map<String, Creator> authors) {
    _suspended = null;
    _playShuffled(ShufflePlay(order: order, authors: authors), order.next());
  }

  /// ランダム再生を、[postId] の動画の [start] の位置から始める（固定ビューアを開き直して、続きから流すとき）。
  /// [order] にその動画がなければ、何もせずに偽を返す。
  bool resumeShuffle(
    PostShuffle order,
    Map<String, Creator> authors,
    String postId,
    Duration start,
  ) {
    final post = order.startAt(postId);
    if (post == null) return false;
    _suspended = null;
    _playShuffled(
      ShufflePlay(order: order, authors: authors),
      post,
      start: start,
    );
    return true;
  }

  /// ランダム再生で、次（[step] が 1）か前（-1）の動画に切り替える。前がなければ、何もしない。
  void stepShuffle(int step) {
    final shuffle = switch (state) {
      PostPlayback(:final shuffle?) => shuffle,
      _ => null,
    };
    if (shuffle == null) return;
    _playShuffled(
      shuffle,
      step < 0 ? shuffle.order.previous() : shuffle.order.next(),
    );
  }

  void _playShuffled(
    ShufflePlay shuffle,
    Post? post, {
    Duration start = Duration.zero,
  }) {
    if (post == null) return;
    state = PostPlayback(
      post: post,
      author: shuffle.authors[post.creatorId],
      start: start,
      canOpenAuthor: true,
      shuffle: shuffle,
    );
  }

  /// 固定ビューアを閉じる。
  void close() => state = null;

  /// その投稿の動画を流していたら、閉じる（追星から消したとき）。
  void endPost(String postId) {
    if (_suspended?.playback.post.id == postId) _suspended = null;
    final current = state;
    if (current is PostPlayback && current.post.id == postId) state = null;
  }

  /// その発信者の配信が終わったと分かったら、閉じる。
  void endFor(String creatorId) {
    final current = state;
    if (current is LivePlayback && current.creatorId == creatorId) {
      state = null;
    }
  }
}

final playbackProvider = NotifierProvider<PlaybackNotifier, Playback?>(
  PlaybackNotifier.new,
);

extension PlaybackService on Playback {
  /// 流しているもののサービス。
  SnsService get service => switch (this) {
    LivePlayback(:final live) => live.service,
    PostPlayback(:final post) => post.source,
  };
}

/// 固定ビューアのスイッチ（機能仕様書 4.3.5）。入れている間は、固定ビューアに配信か推しの動画を流し続ける。
/// 切ると、流しているものを閉じる。
///
/// 初めの状態：推しが0人なら切、1人以上なら入（[applyDefault]。起動したときと、ホームを開いたときに当てる）。
/// ユーザーが切ったら、そのことを端末内に覚え、開き直しても切ったままにする（[set]）。
class FixedViewerSwitch extends Notifier<bool> {
  @override
  bool build() => false;

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  /// ユーザーがスイッチを入れた・切った（固定ビューアのボタンで流し始めたときも、入れたとみなす）。
  /// 切ったら覚え、入れたら記録を消す。
  Future<void> set(bool on) async {
    if (on == state) return;
    state = on;
    if (_repo.fixedViewerUserOff != !on) await _repo.setFixedViewerUserOff(!on);
  }

  /// ホームを開いた（起動したときを含む）。ユーザーが切っていなければ、推しがいるときに入れる。
  /// 入れているときは、そのままにする（推しが0人でも、ユーザーが入れたなら切らない）。
  void applyDefault({required int oshiCount}) {
    if (state || oshiCount == 0 || _repo.fixedViewerUserOff) return;
    state = true;
  }

  /// 推しが0人になった。切る（ユーザーが切ったとは記録しない。推しができたら、また入れる）。
  void onOshisEmpty() => state = false;
}

final fixedViewerOnProvider = NotifierProvider<FixedViewerSwitch, bool>(
  FixedViewerSwitch.new,
);

/// 固定ビューアのスイッチを入れたのに、流すもの（配信中の推し・推しの動画）がない（試作）。
/// 固定ビューアの場所に、推しを探す案内を出す。何か流し始めるか、スイッチを切ると、偽に戻る。
class FixedViewerEmpty extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool empty) => state = empty;
}

final fixedViewerEmptyProvider = NotifierProvider<FixedViewerEmpty, bool>(
  FixedViewerEmpty.new,
);

/// 固定ビューアを、下部ナビのコントローラー（上へはじく）で止めているか（機能仕様書 4.3.5）。
/// 止めている間は、投稿ビューアに隠れている間と同じく、プレイヤーを外して止める。
/// 流すものが変わるか、スイッチを切ると、偽に戻る。
class FixedViewerPaused extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool paused) => state = paused;
}

final fixedViewerPausedProvider = NotifierProvider<FixedViewerPaused, bool>(
  FixedViewerPaused.new,
);

/// 固定ビューアを画面の上に出しているか（何か流しているか、流すものがないときの案内）。
/// 出している間は、画面に使える縦が狭いので、タイムスケジュール以外の画面のヘッダーを固定しない（画面定義書 5.1.2。[ViewerAwareHeader]）。
final fixedViewerShownProvider = Provider<bool>(
  (ref) =>
      ref.watch(playbackProvider) != null ||
      ref.watch(fixedViewerEmptyProvider),
);

/// 固定ビューアが画面の上から占めている高さ（ステータスバーを含む。出していなければ 0）。
/// 投稿ビューアは、固定ビューアを出している間は、この下の領域に出す（固定ビューアを隠さない。機能仕様書 4.3.5）。
/// 固定ビューア（LivePlayerHost）が、組み立てるたびに知らせる。
class FixedViewerInset extends Notifier<double> {
  @override
  double build() => 0;

  void set(double inset) {
    if (ref.mounted && inset != state) state = inset;
  }
}

final fixedViewerInsetProvider = NotifierProvider<FixedViewerInset, double>(
  FixedViewerInset.new,
);

/// 固定ビューアで最後に流していたものを、端末内に覚える（機能仕様書 4.3.5）。
/// 次に固定ビューアを開いたとき、動画はその位置から、配信はまだ配信中ならその配信を流す。
/// 覚えるのは、推しの配信と YouTube の動画だけ。ほかの動画を流したら、忘れる。
/// 固定ビューアを閉じても、忘れない（次に開いたときに使うため）。
class LastPlaybackRecorder extends Notifier<LastPlayback?> {
  @override
  LastPlayback? build() => _repo.lastPlayback;

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  /// [value] を覚える。同じなら書かない。
  Future<void> record(LastPlayback? value) async {
    if (value == state) return;
    state = value;
    await _repo.setLastPlayback(value);
  }

  /// 流し始めたものを覚える。動画は [Playback] の始める位置で覚え、流している間に位置を書き直す（[recordPosition]）。
  Future<void> recordPlayback(Playback playback) => record(switch (playback) {
    LivePlayback(:final creatorId) => LastLive(creatorId),
    PostPlayback(:final post, :final start) when post.youtubeVideoId != null =>
      LastVideo(postId: post.id, position: start),
    PostPlayback() => null,
  });

  /// 流している YouTube の動画の、いまの位置を覚える。覚えている動画と違えば、何もしない。
  Future<void> recordPosition(String postId, Duration position) async {
    final current = state;
    if (current is! LastVideo || current.postId != postId) return;
    await record(LastVideo(postId: postId, position: position));
  }
}

final lastPlaybackProvider =
    NotifierProvider<LastPlaybackRecorder, LastPlayback?>(
      LastPlaybackRecorder.new,
    );
