import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/sns_service.dart';
import '../../core/ui/live_player.dart';
import '../../core/ui/post_cards.dart';
import '../../core/ui/post_video.dart';
import '../../core/ui/swipe_direction.dart';
import '../../core/ui/viewer_control.dart';
import '../../post/widgets/post_viewer_screen.dart';
import '../../core/view_models/audio_focus_provider.dart';
import '../../core/view_models/playback_provider.dart';
import '../view_models/creator_providers.dart';
import 'fixed_viewer_strip.dart';

/// 固定ビューア（試作）。配信か投稿の動画を、画面のいちばん上に据え付けて流し、タブを移っても残す。
/// 推しの動画のランダム再生（[ShufflePlay]）では、動画が終わったら次の動画に進む。
/// 固定ビューアのボタンで入れた投稿の動画は、終わったらランダム再生に移る。帯の右のボタンで、配信とランダム再生を切り替える。
/// スイッチを入れたのに流すものがなければ、推しを探す案内を出す（[fixedViewerEmptyProvider]）。
/// 投稿ビューアは、固定ビューアを出している間は、その下の領域に出す（[fixedViewerInsetProvider]）。固定ビューアは隠れないので、
/// 止めずに流し続け、投稿ビューアで動画が流れている間だけ音を消す。帯の「投稿を開く」で、流している動画そのものを
/// ビューアで開いたときだけ、同じ動画を2つ流さないよう止め、閉じたら流し直す。
/// ながら見のためのもので、ユーザーは、流したまま好きな画面で好きなことをする。
/// アプリの画面は、固定ビューアの下から始める（重ねない）。出す・消すは、下部ナビのスイッチで行う（帯に×は置かない）。
/// ページの埋め込み（ホームの配信ビューア・発信者ページの配信）は、固定ビューアが出ている間は隠れる。
class LivePlayerHost extends ConsumerStatefulWidget {
  const LivePlayerHost({
    super.key,
    required this.onOpen,
    required this.onLiveEnded,
    required this.liveBeside,
    required this.livePosition,
    required this.hasLive,
    required this.onPlayLive,
    required this.onPlayShuffle,
    required this.onOpenPostViewer,
    required this.child,
  });

  /// 帯の推しのアイコン、投稿のビューアで発信者を押したとき。その発信者のページを開く。
  final void Function(String creatorId) onOpen;

  /// 流していた配信が終わって、固定ビューアを閉じたとき（「配信が終わりました」を出す）。
  final ValueChanged<LiveEnded> onLiveEnded;

  /// その発信者の前後（[step] が -1 なら前、1 なら次）の、配信中の推しの配信。なければ null。
  /// 帯の矢印・払いで、配信を切り替えるのに使う（ホームの推しレーンと同じ順。端の次は反対の端）。
  final ({String creatorId, Live live, String? avatarUrl})? Function(
    String creatorId,
    int step,
  )
  liveBeside;

  /// その発信者が、配信中の推しの何人目か（[liveBeside] と同じ順）。帯の点に出す。いなければ null。
  final ({int index, int count})? Function(String creatorId) livePosition;

  /// 配信中の推しがいるか。帯に、配信に切り替えるボタンを出すかに使う。
  final bool Function() hasLive;

  /// 配信中の推しの配信に切り替える。
  final VoidCallback onPlayLive;

  /// 推しの動画のランダム再生に切り替える。
  final VoidCallback onPlayShuffle;

  /// 投稿ビューアを開く直前。タブの中の画面に出ているスナックバーを消す（全画面のビューアに隠れるうえ、
  /// 残してあるタブの画面にも組み立てられていて、開くときの画面の切り替えで重なってしまうため）。
  final VoidCallback onOpenPostViewer;

  final Widget child;

  @override
  ConsumerState<LivePlayerHost> createState() => _LivePlayerHostState();
}

class _LivePlayerHostState extends ConsumerState<LivePlayerHost>
    with TickerProviderStateMixin {
  /// 映像の幅の上限（画面の幅いっぱいで、これより広くしない）。
  static const _maxWidth = 400.0;

  /// 縦長の映像の幅（YouTube の Required Minimum Functionality。縦も横も 200 以上）。
  static const _portraitWidth = 200.0;

  /// 映像の下の帯の高さ（映像の上には重ねない。YouTube の規約）。
  static const _stripHeight = 32.0;

  /// 帯を払っている間に、指の当たっているあたりだけ、帯の下に出すふくらみの高さと幅。
  /// 帯そのものと、ビューアの枠は変えない（帯のアイコンにも重ねない）。下の画面に重ね、画面はずらさない。
  static const _bulgeHeight = 16.0;
  static const _bulgeWidth = 96.0;

  /// 投稿の動画のプレイヤーを組み立てる大きさの倍率（小さく組み立てると、操作が詰まる）。
  static const _postPlayerScale = 2.0;

  /// 投稿の動画の、いまの再生位置を聞く窓口。
  final _postHandle = PostVideoHandle();

  /// 流している動画の位置を、端末内に覚え直す間隔（次に開いたとき、続きから流すため。機能仕様書 4.3.5）。
  static const _recordInterval = Duration(seconds: 5);
  Timer? _recordTimer;

  /// アプリが裏に回るときに、動画の位置を覚える（そのままアプリを終えられても、続きから流せるように）。
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onInactive: _recordPosition,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _inset;
    _recordTimer = Timer.periodic(_recordInterval, (_) => _recordPosition());
  }

  /// 流している YouTube の動画の、最後に分かった位置を覚える。
  void _recordPosition() {
    final playback = ref.read(playbackProvider);
    final position = _postHandle.lastPosition;
    if (playback is! PostPlayback || position == null) return;
    ref
        .read(lastPlaybackProvider.notifier)
        .recordPosition(playback.post.id, position);
  }

  /// 映像の縦横比。配信は 16:9、投稿の動画は、その縦横比（横長・縦長・正方形）。
  double _ratio(Playback playback) => switch (playback) {
    PostPlayback(:final post) => post.thumbnailAspectRatio,
    LivePlayback() => 16 / 9,
  };

  /// いまのビューアの幅（映像と帯の幅）。払いの判定と、払っている間の不透明度に使う。
  double get _viewerWidth {
    final screen = MediaQuery.sizeOf(context);
    final playback = ref.read(playbackProvider);
    return playback == null
        ? (screen.width < _maxWidth ? screen.width : _maxWidth)
        : _videoSize(screen, playback).width;
  }

  /// 映像の大きさ。画面の幅いっぱい（最大 [_maxWidth]）。縦長は、幅 [_portraitWidth]。
  Size _videoSize(Size screen, Playback playback) {
    final ratio = _ratio(playback);
    final width = ratio >= 1
        ? (screen.width < _maxWidth ? screen.width : _maxWidth)
        : _portraitWidth;
    return Size(width, width / ratio);
  }

  /// 帯を横に払っている量。映像は、指について横に動く（帯は動かさない）。
  double _swipe = 0;
  double _swipeFrom = 0;

  /// 払って離したあと、元の位置へ戻す（または、切り替えた配信を反対側から入れる）アニメーション。
  late final AnimationController _swipeBack =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
      )..addListener(
        () => setState(
          () => _swipe =
              _swipeFrom *
              (1 - Curves.easeOutCubic.transform(_swipeBack.value)),
        ),
      );

  /// 払っているか。払っている間は、指の下で帯をふくらませる（帯が払える場所だと分かるように）。
  bool _swiping = false;

  /// 払っている指の、画面の上の横の位置。ふくらみは、ここについてくる。
  double _touchX = 0;

  /// [step] の向き（1 なら次、-1 なら前）に切り替えられるか。配信は前後の配信中の推し、ランダム再生は前後の動画。
  bool _canStep(int step) => switch (ref.read(playbackProvider)) {
    LivePlayback(:final creatorId) =>
      widget.liveBeside(creatorId, step) != null,
    PostPlayback(:final shuffle?) => step > 0 || shuffle.order.hasPrevious,
    _ => false,
  };

  /// [step] の向きに切り替える。
  void _stepTo(int step) {
    switch (ref.read(playbackProvider)) {
      case LivePlayback(:final creatorId):
        final beside = widget.liveBeside(creatorId, step);
        if (beside == null) return;
        ref
            .read(playbackProvider.notifier)
            .play(beside.creatorId, beside.live, avatarUrl: beside.avatarUrl);
      case PostPlayback(shuffle: _?):
        _shuffleFailures = 0;
        _stepShuffle(step);
      default:
        return;
    }
  }

  /// 左へ払うと次、右へ払うと前。
  static int _stepOf(double dx) => dx < 0 ? 1 : -1;

  void _onSwipeStart(DragStartDetails d) {
    _swipeBack.stop();
    setState(() {
      _swiping = true;
      _touchX = d.globalPosition.dx;
    });
  }

  /// 払った向きに切り替えられなければ、少しだけ動かす（端で戻る）。
  void _onSwipeUpdate(DragUpdateDetails d) {
    final next = _swipe + d.delta.dx;
    final damping = next == 0 || _canStep(_stepOf(next)) ? 1.0 : 0.3;
    setState(() {
      _swipe += d.delta.dx * damping;
      _touchX = d.globalPosition.dx;
    });
  }

  /// 払って離したら、払った向きに切り替え、反対側から入れる。止めてから離したときは、
  /// 帯の幅（ビューアの幅。画面の幅ではない）の 25% 動かしていれば切り替え、足りなければ戻す。
  void _onSwipeEnd(DragEndDetails d) {
    final width = _viewerWidth;
    final direction = swipeDirection(
      velocity: d.velocity.pixelsPerSecond.dx,
      offset: _swipe,
      width: width,
    );
    if (direction != 0 && _canStep(_stepOf(direction))) {
      HapticFeedback.selectionClick();
      _stepTo(_stepOf(direction));
      _swipe = -direction.sign * width * 0.35;
    }
    _swiping = false;
    _swipeFrom = _swipe;
    _swipeBack.forward(from: 0);
  }

  /// 帯の矢印を押したとき。前後に切り替え、押した向きから入れる。
  void _step(int step) {
    if (!_canStep(step)) return;
    HapticFeedback.selectionClick();
    _stepTo(step);
    _swipeBack.stop();
    _swipe = step * _viewerWidth * 0.35;
    _swipeFrom = _swipe;
    _swipeBack.forward(from: 0);
  }

  /// ランダム再生で、続けて再生できなかった回数。続けて [_maxShuffleFailures] 回できなければ、先へ進むのをやめる
  /// （通信が切れているときに、次々に読み込み続けない）。動画が流れ始めたとき、矢印・払いで替えたとき、
  /// ランダム再生を始め直したとき（新しい [ShufflePlay]）に、0に戻す。
  int _shuffleFailures = 0;
  static const _maxShuffleFailures = 5;
  Timer? _skipTimer;

  /// ランダム再生で、前後の動画に切り替える（帯の矢印、動画の終わり）。
  void _stepShuffle(int step) {
    _skipTimer?.cancel();
    ref.read(playbackProvider.notifier).stepShuffle(step);
  }

  /// ランダム再生で、動画が流れ始めた。続けて再生できなかった回数を0に戻す。
  void _onShuffleStarted() => _shuffleFailures = 0;

  /// ランダム再生で、動画が最後まで流れた。次の動画に進む。
  void _onShuffleEnded() {
    // コントローラーで早送りしている間は、終わりの近くに動かすと YouTube が「終わった」と知らせることがあるので、
    // 次の動画に進まず、動かす先の位置に戻す（離したら、そこから再生する）。
    final seeking = _seekTarget;
    if (seeking != null) {
      _postHandle.seek(seeking);
      return;
    }
    _shuffleFailures = 0;
    _stepShuffle(1);
  }

  /// ランダム再生で、動画を再生できなかった。少し見せてから、次の動画に進む。
  void _onShuffleFailed(PostPlayback playback) {
    if (++_shuffleFailures >= _maxShuffleFailures) return;
    _skipTimer?.cancel();
    _skipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && identical(ref.read(playbackProvider), playback)) {
        _stepShuffle(1);
      }
    });
  }

  /// 帯の「投稿を開く」で、流している動画をビューアで開いているか。開いている間は、固定ビューアを止める。
  bool _openedHere = false;

  /// 投稿の動画を、ビューアで続きから開く。固定ビューアは、同じ動画を2つ流さないよう、ビューアを開いている間は止まり、
  /// 閉じたら、ビューアで見ていた位置から続ける（ほかの投稿に移ってから閉じたら、止めた位置から）。
  Future<void> _openPost(PostPlayback playback) async {
    final position = await _postHandle.position() ?? playback.start;
    if (!mounted) return;
    widget.onOpenPostViewer();
    _onViewerOpened();
    setState(() => _openedHere = true);
    final author = playback.author;
    await PostViewerScreen.open(
      context,
      posts: [playback.post],
      initialIndex: 0,
      initialStart: position,
      authorOf: (_) => author,
      // 投稿者を押せるのは、固定ビューアに移したビューアで押せたとき（ホーム・タイムスケジュールから開いた）だけ。
      onOpenAuthor: playback.canOpenAuthor
          ? (author) => widget.onOpen(author.id)
          : null,
      onClosed: (post, position) {
        if (position != null) {
          ref.read(playbackProvider.notifier).seek(post.id, position);
        }
      },
    );
    if (mounted) setState(() => _openedHere = false);
  }

  /// 流している投稿の動画の位置を控える（止めたあと、そこから流し直す）。
  void _onViewerOpened() {
    final playback = ref.read(playbackProvider);
    final position = _postHandle.lastPosition;
    if (playback is PostPlayback && position != null) {
      ref.read(playbackProvider.notifier).seek(playback.post.id, position);
    }
  }

  /// 流しているものを見分ける値（配信なら推し、動画なら投稿）。再生位置の違いは見ない。
  static String? _playingKey(Playback? playback) => switch (playback) {
    LivePlayback(:final creatorId) => 'live:$creatorId',
    PostPlayback(:final post) => 'post:${post.id}',
    null => null,
  };

  /// コントローラーで止める・流し直す。止めるときは、投稿ビューアを開くときと同じく、再生位置を控える。
  /// 止めたら真を返す。流しているものがなければ、何もせずに null を返す。
  bool? _togglePause() {
    final playback = ref.read(playbackProvider);
    if (playback == null) return null;
    final paused = !ref.read(fixedViewerPausedProvider);
    if (paused) _onViewerOpened();
    ref.read(fixedViewerPausedProvider.notifier).set(paused);
    return paused;
  }

  /// コントローラーで、前後に切り替える（帯の矢印と同じ）。切り替えられなければ偽を返す。
  bool _stepFromController(int step) {
    if (!_canStep(step)) return false;
    _step(step);
    return true;
  }

  /// コントローラーで早送り・巻き戻ししている間の、動かす先の再生位置。していなければ null。
  Duration? _seekTarget;

  /// 早送り（1）・巻き戻し（-1）・指が右左から外れて止めている（0）。
  int _seekDirection = 0;

  /// 同じ向きで引っ張り続けている時間（速さを決める）。
  Duration _seekHeld = Duration.zero;

  /// 最後にプレイヤーへ位置を送ってからの時間（[ViewerSeek.sendInterval] ごとに間引いて送る）。
  Duration _seekSinceSend = Duration.zero;

  /// 最後にプレイヤーへ送った位置と、そこへ動き終えたか（動き終えるまで、次を送らない。最長 [ViewerSeek.maxWait]）。
  Duration? _seekSent;
  bool _seekLanded = false;

  /// 動き終えたかを、プレイヤーに聞いている途中か。
  bool _seekAsking = false;
  Timer? _seekTimer;
  final _seekClock = Stopwatch();

  /// 早送り・巻き戻しの位置を進める間隔。
  static const _seekTick = Duration(milliseconds: 100);

  /// コントローラーを左右に引っ張ったまま止めたとき（機能仕様書 4.3.5）。動画シャッフルで、YouTube の動画を流していて
  /// （止めていない）、位置を動かせるときだけ、早送り・巻き戻しを始めて真を返す。配信などでは偽（今までどおり次・前）。
  bool _seekStart(int direction) {
    final playback = ref.read(playbackProvider);
    if (playback is! PostPlayback || playback.shuffle == null) return false;
    if (playback.post.source != SnsService.youtube) return false;
    if (ref.read(fixedViewerPausedProvider) ||
        _openedHere ||
        ref.read(viewerVideoPlayingProvider)) {
      return false;
    }
    if (!_postHandle.seekable) return false;
    final base = _postHandle.lastPosition ?? playback.start;
    _seekTarget = base;
    _seekDirection = direction;
    _seekHeld = Duration.zero;
    _seekSinceSend = Duration.zero;
    _seekSent = null;
    _seekClock
      ..reset()
      ..start();
    _seekTimer?.cancel();
    _seekTimer = Timer.periodic(_seekTick, (_) => _seekAdvance());
    // 控えた位置は1秒ごとなので、今の位置を聞き直して合わせる（聞いている間に動かした分は、そのまま足す）。
    _postHandle.position().then((now) {
      final target = _seekTarget;
      if (now == null || target == null) return;
      _seekTarget = target + (now - base);
    });
    return true;
  }

  /// 引っ張っている向きが変わった。変わったら、速さを最初に戻す。
  void _seekSetDirection(int direction) {
    if (_seekTarget == null || direction == _seekDirection) return;
    _seekDirection = direction;
    _seekHeld = Duration.zero;
  }

  /// 位置を進め、間引いてプレイヤーへ送る。送るのは、前に送ってから [ViewerSeek.sendInterval] たち、前の位置へ
  /// 動き終えたとき（読み込みが追いつかないまま次々に送ると、映像が止まったままになるため）。
  /// 動き終えなくても、[ViewerSeek.maxWait] たてば送る。
  void _seekAdvance() {
    final target = _seekTarget;
    final duration = _postHandle.duration;
    if (target == null || duration == null) return;
    final dt = _seekClock.elapsed;
    _seekClock
      ..reset()
      ..start();
    if (_seekDirection == 0) {
      // 右左から外れている間は、動画はそのまま流れているので、位置だけ合わせておく。
      _seekTarget = ViewerSeek.clamp(target + dt, duration);
      _seekSinceSend = Duration.zero;
      return;
    }
    _seekHeld += dt;
    final speed = ViewerSeek.speedAt(_seekHeld);
    _seekTarget = ViewerSeek.clamp(
      target + dt * (speed * _seekDirection),
      duration,
    );
    _seekSinceSend += dt;
    if (_seekSinceSend < ViewerSeek.sendInterval) return;
    final sent = _seekSent;
    if (sent == null || _seekLanded || _seekSinceSend >= ViewerSeek.maxWait) {
      _seekSinceSend = Duration.zero;
      _seekSent = _seekTarget;
      _seekLanded = false;
      _postHandle.seek(_seekTarget!);
      return;
    }
    if (_seekAsking) return;
    _seekAsking = true;
    _postHandle.position().then((now) {
      _seekAsking = false;
      if (now == null || _seekSent != sent) return;
      if ((now - sent).abs() <= ViewerSeek.landedWithin) _seekLanded = true;
    });
  }

  /// 指を離した。そこから再生する。
  void _seekEnd() {
    final target = _seekTarget;
    _seekStop();
    if (target != null) _postHandle.seek(target, play: true);
  }

  /// 早送り・巻き戻しをやめる（位置は送らない）。
  void _seekStop() {
    _seekTimer?.cancel();
    _seekTimer = null;
    _seekClock.stop();
    _seekTarget = null;
    _seekSent = null;
    _seekDirection = 0;
  }

  /// 投稿ビューアに、固定ビューアの占める高さを知らせる窓口。
  late final FixedViewerInset _inset = ref.read(
    fixedViewerInsetProvider.notifier,
  );

  @override
  void dispose() {
    // 固定ビューアがなくなったら、投稿ビューアを画面全体に戻す（組み立ての途中には変えられないので、次のフレームで）。
    final inset = _inset;
    WidgetsBinding.instance.addPostFrameCallback((_) => inset.set(0));
    _recordTimer?.cancel();
    _lifecycle.dispose();
    _skipTimer?.cancel();
    _postHandle.failed.dispose();
    _swipeBack.dispose();
    _seekStop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 流している配信の終わりを確かめ、終わったら閉じて知らせる（機能仕様書 4.3.2）。
    ref.listen(liveEndWatcherProvider, (_, ended) {
      if (ended != null) widget.onLiveEnded(ended);
    });
    // ランダム再生を始め直したら（スイッチの入れ直し・帯のボタン）、続けて再生できなかった回数を0に戻す。
    ref.listen(playbackProvider, (previous, next) {
      final shuffle = next is PostPlayback ? next.shuffle : null;
      final before = previous is PostPlayback ? previous.shuffle : null;
      if (shuffle != null && !identical(shuffle, before)) _shuffleFailures = 0;
    });
    // 投稿ビューアで動画が流れ始めたら、固定ビューアの動画の位置を控える（止めたあと、続きから流す）。
    ref.listen(viewerVideoPlayingProvider, (previous, playing) {
      if (!(previous ?? false) && playing) _onViewerOpened();
    });
    // 流し始めたものを覚える（次に開いたとき、続きから流す）。閉じたときは、閉じる前の動画の位置を覚える。
    ref.listen(playbackProvider, (previous, next) {
      if (next != null) {
        ref.read(lastPlaybackProvider.notifier).recordPlayback(next);
      } else if (previous is PostPlayback) {
        final position = _postHandle.lastPosition;
        if (position != null) {
          ref
              .read(lastPlaybackProvider.notifier)
              .recordPosition(previous.post.id, position);
        }
      }
      // ランダム再生から配信に切り替えたら、切り替える直前の位置と、止めていたかを控える（戻したとき、そこから続ける）。
      if (previous is PostPlayback &&
          previous.shuffle != null &&
          next is LivePlayback) {
        ref
            .read(playbackProvider.notifier)
            .updateSuspended(
              previous.post.id,
              position: _postHandle.lastPosition ?? previous.start,
              paused: ref.read(fixedViewerPausedProvider) || _postHandle.paused,
            );
      }
      // 流すものが替わったら、前の動画の位置を、次の動画の位置として覚えないよう、忘れる。
      // 早送り・巻き戻しの途中なら、やめる（次の動画の位置を動かさない）。
      if (_playingKey(previous) != _playingKey(next)) {
        _seekStop();
        _postHandle.lastPosition = null;
        _postHandle.paused = false;
      }
    });
    // 流すもの（配信の推し・動画）が変わったら、コントローラーで止めていたのをやめる。
    ref.listen(playbackProvider, (previous, next) {
      if (_playingKey(previous) != _playingKey(next)) {
        ref.read(fixedViewerPausedProvider.notifier).set(false);
      }
    });
    final playback = ref.watch(playbackProvider);
    // コントローラーで止めている間と、流している動画そのものをビューアで開いている間は、映像を止める。
    // 投稿ビューアで動画を流している間も止める（固定ビューアでの再生を優先し、投稿ビューアの動画は、ファンが
    // 再生ボタンを押したときだけ流す。止めた・閉じた・ほかの投稿に移ったら、続きから流し直す。2026-11-19 本人）。
    // 動画のない投稿を開いても止めない（投稿ビューアは固定ビューアの下に出て、固定ビューアは隠れない）。
    final paused =
        ref.watch(fixedViewerPausedProvider) ||
        _openedHere ||
        ref.watch(viewerVideoPlayingProvider);
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final video = playback == null ? null : _videoSize(screen, playback);
    // 流すものがないときの案内は、配信と同じ大きさの枠に出す（帯は出さない）。
    final empty = playback == null && ref.watch(fixedViewerEmptyProvider);
    final emptySize = Size(
      screen.width < _maxWidth ? screen.width : _maxWidth,
      (screen.width < _maxWidth ? screen.width : _maxWidth) * 9 / 16,
    );
    // 固定ビューアは、いちばん上に据え付け、アプリの画面を、その下から始める（重ねない）。
    final inset = video != null
        ? padding.top + video.height + _stripHeight
        : empty
        ? padding.top + emptySize.height
        : 0.0;
    // 投稿ビューアに、固定ビューアの占める高さを知らせる（組み立ての途中には変えられないので、次のフレームで）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inset.set(inset);
    });
    return LivePlayerHostScope._(
      state: this,
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: inset),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, top, child) {
              final media = MediaQuery.of(context);
              // ステータスバーのぶんは、固定ビューアが受け持つので、下の画面からは外す。
              final statusBar = (padding.top - top).clamp(0.0, padding.top);
              return Padding(
                padding: EdgeInsets.only(top: top),
                child: MediaQuery(
                  data: media.copyWith(
                    padding: media.padding.copyWith(top: statusBar),
                    viewPadding: media.viewPadding.copyWith(top: statusBar),
                  ),
                  child: child!,
                ),
              );
            },
            child: widget.child,
          ),
          if (playback != null && video != null)
            Positioned(
              top: padding.top,
              left: (screen.width - video.width) / 2,
              width: video.width,
              height: video.height + _stripHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: [
                      // 払っている間は、映像だけが指について横に動く（帯は動かさない）。
                      // はみ出したところは、枠の中で切る。
                      Expanded(
                        child: ColoredBox(
                          color: Colors.black,
                          child: Transform.translate(
                            offset: Offset(_swipe, 0),
                            child: Opacity(
                              opacity: (1 - _swipe.abs() / video.width * 0.6)
                                  .clamp(0.0, 1.0),
                              child: paused
                                  ? _pausedVideo(playback)
                                  : _video(playback, video),
                            ),
                          ),
                        ),
                      ),
                      FixedViewerStrip(
                        playback: playback,
                        height: _stripHeight,
                        position: playback is LivePlayback
                            ? widget.livePosition(playback.creatorId)
                            : null,
                        onOpenCreator: widget.onOpen,
                        avatarUrl: switch (playback) {
                          PostPlayback(:final author?, shuffle: _?) =>
                            author.avatarUrl,
                          _ => null,
                        },
                        onOpenPost: playback is PostPlayback
                            ? () => _openPost(playback)
                            : null,
                        onStep: switch (playback) {
                          LivePlayback(:final creatorId)
                              when widget.liveBeside(creatorId, 1) != null =>
                            _step,
                          PostPlayback(shuffle: _?) => _step,
                          _ => null,
                        },
                        // 配信とランダム再生は、帯を横に払って前後に切り替える。
                        onSwipeStart: switch (playback) {
                          LivePlayback() ||
                          PostPlayback(shuffle: _?) => _onSwipeStart,
                          _ => null,
                        },
                        onSwipeUpdate: _onSwipeUpdate,
                        onSwipeEnd: _onSwipeEnd,
                        // 配信からはランダム再生へ。動画からは配信へ（配信中の推しがいるとき）。
                        // 固定ビューアのボタンで入れた動画からは、ランダム再生へも。
                        onPlayShuffle: switch (playback) {
                          LivePlayback() ||
                          PostPlayback(shuffle: null) => widget.onPlayShuffle,
                          _ => null,
                        },
                        onPlayLive: playback is PostPlayback && widget.hasLive()
                            ? widget.onPlayLive
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 払っている間だけ、指の当たっているあたりの帯の下に、ふくらみを出す。
          if (playback != null && video != null)
            TweenAnimationBuilder<double>(
              tween: Tween(end: _swiping ? 1 : 0),
              duration: const Duration(milliseconds: 120),
              builder: (context, t, _) {
                final left = (screen.width - video.width) / 2;
                return Positioned(
                  key: const ValueKey('strip-bulge'),
                  // 帯の下の端に1だけ重ね、つなぎ目を見せない。
                  top: padding.top + video.height + _stripHeight - 1,
                  left: (_touchX - _bulgeWidth / 2).clamp(
                    left,
                    left + video.width - _bulgeWidth,
                  ),
                  width: _bulgeWidth,
                  height: _bulgeHeight * t,
                  child: const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: FixedViewerStrip.background,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (empty)
            Positioned(
              top: padding.top,
              left: (screen.width - emptySize.width) / 2,
              width: emptySize.width,
              height: emptySize.height,
              child: const FixedViewerEmptyPanel(),
            ),
        ],
      ),
    );
  }

  /// 止めている間の、映像の場所。プレイヤーを外して止める。投稿の動画は、サムネイルを出す。
  Widget _pausedVideo(Playback playback) => ColoredBox(
    color: Colors.black,
    child: switch (playback) {
      PostPlayback(:final post) => PostThumbnail(
        url: post.thumbnailUrl,
        aspectRatio: post.thumbnailAspectRatio,
      ),
      LivePlayback() => const SizedBox.expand(),
    },
  );

  /// 映像。配信と YouTube の動画は、公式（ツイキャスは自前）のプレイヤーを、そのまま操作できる
  /// （字幕・音量・一時停止など。上に何も重ねず、タッチも塞がない。YouTube の規約）。
  /// YouTube 以外の投稿の動画は、大きく組み立てて縮めて見せ、押すとビューアで開く。
  Widget _video(Playback playback, Size video) => switch (playback) {
    LivePlayback(:final live) => LivePlayer(
      key: ValueKey(live.playbackUrl),
      live: live,
      mini: true,
    ),
    PostPlayback(:final post, :final start, :final shuffle)
        when post.source == SnsService.youtube =>
      ColoredBox(
        color: Colors.black,
        child: PostVideo(
          key: ObjectKey(playback),
          post: post,
          start: start,
          handle: _postHandle,
          mini: true,
          // 固定ビューアのボタンで入れた動画は、終わったらランダム再生に移る。
          onStarted: shuffle == null ? null : _onShuffleStarted,
          onEnded: shuffle == null ? widget.onPlayShuffle : _onShuffleEnded,
          onFailed: shuffle == null ? null : () => _onShuffleFailed(playback),
        ),
      ),
    PostPlayback(:final post, :final start) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPost(playback),
      child: AbsorbPointer(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox.fromSize(
            size: video * _postPlayerScale,
            child: ColoredBox(
              color: Colors.black,
              child: PostVideo(
                key: ObjectKey(playback),
                post: post,
                start: start,
                handle: _postHandle,
                mini: true,
              ),
            ),
          ),
        ),
      ),
    ),
  };
}

/// 固定ビューアの下に置いた画面に、固定ビューアを伝える。下部ナビのコントローラーが、止める・流し直す・前後に切り替えるのに使う。
class LivePlayerHostScope extends InheritedWidget {
  const LivePlayerHostScope._({
    required _LivePlayerHostState state,
    required super.child,
  }) : _state = state;

  final _LivePlayerHostState _state;

  /// 下部ナビのコントローラー（上へはじく）で、止める・流し直す。止めたら真、流し直したら偽、
  /// 流しているものがなければ null。
  bool? togglePause() => _state._togglePause();

  /// 下部ナビのコントローラー（左右へはじく）で、前後に切り替える。切り替えられなければ偽。
  bool step(int step) => _state._stepFromController(step);

  /// 下部ナビのコントローラー（左右に引っ張ったまま止める）で、早送り（1）・巻き戻し（-1）を始める。
  /// 動画シャッフルで、位置を動かせるときだけ真。偽なら、今までどおり次・前にする。
  bool seekStart(int direction) => _state._seekStart(direction);

  /// 引っ張っている向き（1：早送り、-1：巻き戻し、0：右左から外れた）。
  void seekDirection(int direction) => _state._seekSetDirection(direction);

  /// 指を離した。そこから再生する。
  void seekEnd() => _state._seekEnd();

  /// 固定ビューアの下でなければ null。
  static LivePlayerHostScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LivePlayerHostScope>();

  @override
  bool updateShouldNotify(LivePlayerHostScope oldWidget) =>
      _state != oldWidget._state;
}
