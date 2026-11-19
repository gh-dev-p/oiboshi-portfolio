import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/models/post.dart';
import '../../../l10n/app_localizations.dart';
import 'post_cards.dart';
import '../view_models/audio_focus_provider.dart';
import 'embed_player.dart';

/// 投稿の動画（YouTube の動画・ショート、Instagram と X の動画）。投稿ビューアと固定ビューアで使う。
/// [start] の位置から、音を出して再生する。いまの再生位置は [handle] で聞ける。
/// [autoplay] が偽なら、サムネイルと再生のマークを出して待ち、押したら流す（固定ビューアを開いている間の投稿ビューア）。
/// ビューア（[mini] が偽）では、流している間、固定ビューアを一時停止させ、埋め込みの配信の音を消す（機能仕様書 4.3.2・4.3.5）。
class PostVideo extends StatelessWidget {
  const PostVideo({
    super.key,
    required this.post,
    this.active = true,
    this.start = Duration.zero,
    this.handle,
    this.mini = false,
    this.autoplay = true,
    this.onStarted,
    this.onEnded,
    this.onFailed,
  });

  final Post post;

  /// 再生が始まったとき。YouTube だけ知らせる。
  final VoidCallback? onStarted;

  /// 最後まで再生したとき。YouTube だけ知らせる（Instagram と X の動画は繰り返す）。
  final VoidCallback? onEnded;

  /// 再生できないと分かったとき。YouTube だけ知らせる。
  final VoidCallback? onFailed;

  /// 表示中のページか。Instagram と X の動画は、表示中のページだけ再生する。
  final bool active;
  final Duration start;
  final PostVideoHandle? handle;
  final bool mini;

  /// 開いたら自動で流すか。偽なら、押すまで流さない（固定ビューアでの再生を優先する。2026-11-19 本人）。
  /// 押して流したあと、ほかの投稿に移ったら（[active] が偽）、また押すまで待つ。続きの位置は [handle] から取る。
  final bool autoplay;

  /// 再生できる動画か（YouTube の動画・ショート、動画が取れた Instagram と X の動画）。
  static bool canPlay(Post post) =>
      post.youtubeVideoId != null ||
      (post.isFileVideo && (post.videoUrl?.isNotEmpty ?? false));

  @override
  Widget build(BuildContext context) {
    if (autoplay || mini || !canPlay(post)) return _player(start);
    return _ManualStart(
      post: post,
      active: active,
      // 一度流した動画は、止めた位置から流す。
      player: () => _player(handle?.lastPosition ?? start),
    );
  }

  Widget _player(Duration start) => post.youtubeVideoId != null
      ? _YoutubeVideo(
          post: post,
          start: start,
          handle: handle,
          mini: mini,
          onStarted: onStarted,
          onEnded: onEnded,
          onFailed: onFailed,
        )
      : _FileVideo(
          post: post,
          active: active,
          start: start,
          handle: handle,
          mini: mini,
        );
}

/// 押すまで流さない動画。サムネイルに再生のマークを重ね、押したら [player] を作って流す。
/// 表示中でなくなったら（ほかの投稿に移ったら）、プレイヤーを外し、また押すまで待つ。
class _ManualStart extends StatefulWidget {
  const _ManualStart({
    required this.post,
    required this.active,
    required this.player,
  });

  final Post post;
  final bool active;
  final Widget Function() player;

  @override
  State<_ManualStart> createState() => _ManualStartState();
}

class _ManualStartState extends State<_ManualStart> {
  /// 再生のマークを押したか。
  bool _requested = false;

  @override
  void didUpdateWidget(covariant _ManualStart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active || widget.post.id != oldWidget.post.id) {
      _requested = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_requested && widget.active) return widget.player();
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.postVideoPlay,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _requested = true),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PostFullImage(post: widget.post),
            const Center(child: PlayMark()),
          ],
        ),
      ),
    );
  }
}

/// [PostVideo] に、いまの再生位置を聞く窓口。動画を出す側が持ち、[PostVideo.handle] に渡す。
class PostVideoHandle {
  Future<Duration?> Function()? _source;

  /// いまの再生位置。動画がない・分からなければ null。
  Future<Duration?> position() async => _source?.call();

  /// 最後に分かった再生位置（1秒ごとに控える）。動画を外すときにも、待たずに読める。
  Duration? lastPosition;

  /// プレイヤーで一時停止しているか（YouTube だけ。固定ビューアで、配信に切り替えて戻したとき、止めたままにする）。
  bool paused = false;

  /// 再生できないと分かったか（読み込めない、公式プレイヤーのエラーなど）。ビューアは、固定ビューアで流すボタンを隠す。
  final failed = ValueNotifier(false);

  EmbedPlayerHandle? _player;

  /// 動画の長さ（YouTube だけ。再生が始まったときに聞く）。分からなければ null。
  Duration? duration;

  /// 再生位置を動かせるか（YouTube の動画が流れ始めて、長さが分かった）。
  /// 固定ビューアのコントローラーの早送り・巻き戻しに使う（機能仕様書 4.3.5）。
  bool get seekable => _player != null && duration != null && !failed.value;

  /// 再生位置を [position] に動かす。[play] なら、止まっていても再生する。動かせなければ何もしない。
  void seek(Duration position, {bool play = false}) {
    final player = _player;
    if (player == null) return;
    player.seek(position, play: play);
    lastPosition = position;
  }
}

/// ビューアでは、[playing] の間だけ音を取る（固定ビューアを一時停止させる）。固定ビューアでは、音を取らない。
mixin _AudioFocusMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final AudioFocus _focus = ref.read(audioFocusProvider.notifier);

  bool get mini;
  bool get playing;

  /// ビルドの途中でも呼ばれるので、次のフレームで反映する。
  void syncFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      !mini && playing ? _focus.acquire(this) : _focus.release(this);
    });
  }

  void releaseFocus() {
    final focus = _focus;
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.release(this));
  }
}

/// YouTube の動画・ショート。公式プレイヤーを埋め込み、音を出して自動で再生する（画面定義書 2.5.1）。
/// プレイヤーは読み込むまで黒いので、再生が始まるまでは、サムネイルと読み込み中の印を出す。
class _YoutubeVideo extends ConsumerStatefulWidget {
  const _YoutubeVideo({
    required this.post,
    required this.start,
    required this.handle,
    required this.mini,
    required this.onStarted,
    required this.onEnded,
    required this.onFailed,
  });

  final Post post;
  final Duration start;
  final PostVideoHandle? handle;
  final bool mini;
  final VoidCallback? onStarted;
  final VoidCallback? onEnded;
  final VoidCallback? onFailed;

  @override
  ConsumerState<_YoutubeVideo> createState() => _YoutubeVideoState();
}

class _YoutubeVideoState extends ConsumerState<_YoutubeVideo>
    with _AudioFocusMixin {
  /// サムネイルを外すまでの、最長の時間。自動再生が止められても、プレイヤーの再生ボタンを押せるようにする。
  static const _coverTimeout = Duration(seconds: 8);

  final _player = EmbedPlayerHandle();

  /// 再生が始まった（サムネイルを外した）か。
  bool _started = false;

  /// 公式プレイヤーが再生できないと知らせた（エラー、読み込みの失敗、準備ができないまま時間が過ぎた）。
  bool _failed = false;
  Timer? _coverTimer;

  /// 再生位置を、1秒ごとに [PostVideoHandle.lastPosition] に控える。
  Timer? _positionTimer;

  /// 公式プレイヤーが流している（一時停止・終わりで偽）。
  bool _playingNow = false;

  @override
  bool get mini => widget.mini;
  @override
  bool get playing => _playingNow && !_failed;

  void _setPlaying(bool value) {
    if (_playingNow == value) return;
    _playingNow = value;
    syncFocus();
  }

  @override
  void initState() {
    super.initState();
    _coverTimer = Timer(_coverTimeout, _onStarted);
    widget.handle?._source = _player.position;
    final handle = widget.handle;
    if (handle != null) {
      handle._player = _player;
      handle.duration = null;
      handle.lastPosition = widget.start;
      handle.paused = false;
      _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final position = await _player.position();
        if (mounted && position != null) handle.lastPosition = position;
        // 長さは、流れ始めた直後は 0 のことがあるので、分かるまで聞き直す。
        if (mounted && handle.duration == null) await _readDuration();
      });
    }
    syncFocus();
  }

  @override
  void dispose() {
    _coverTimer?.cancel();
    _positionTimer?.cancel();
    if (widget.handle?._source == _player.position) {
      widget.handle?._source = null;
    }
    if (widget.handle?._player == _player) {
      widget.handle?._player = null;
      widget.handle?.duration = null;
    }
    releaseFocus();
    super.dispose();
  }

  void _onStarted() {
    _coverTimer?.cancel();
    if (mounted && !_started) setState(() => _started = true);
  }

  /// 動画の長さを聞いて控える（早送り・巻き戻しで、終わりを越えないように）。
  Future<void> _readDuration() async {
    final handle = widget.handle;
    if (handle == null || handle.duration != null) return;
    final duration = await _player.duration();
    if (mounted && handle._player == _player) handle.duration = duration;
  }

  void _onFailed() {
    _coverTimer?.cancel();
    if (!mounted || _failed) return;
    setState(() => _failed = true);
    widget.handle?.failed.value = true;
    widget.onFailed?.call();
    syncFocus();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    // 再生できなければ、プレイヤーを外し、Instagram・X と同じ表示にする。
    if (_failed) return _UnplayableVideo(post: post, mini: widget.mini);
    return Stack(
      fit: StackFit.expand,
      children: [
        EmbedPlayer(
          // 始める位置は、秒の単位で渡す。
          url:
              'https://www.youtube.com/embed/${post.youtubeVideoId}'
              '?start=${widget.start.inSeconds}',
          onStarted: _onStarted,
          onPlaying: () {
            widget.handle?.paused = false;
            _setPlaying(true);
            widget.onStarted?.call();
          },
          onPaused: () {
            widget.handle?.paused = true;
            _setPlaying(false);
          },
          onFailed: _onFailed,
          onEnded: () {
            _setPlaying(false);
            widget.onEnded?.call();
          },
          handle: _player,
        ),
        if (!_started)
          IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PostThumbnail(
                  url: post.thumbnailUrl,
                  aspectRatio: post.thumbnailAspectRatio,
                ),
                const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Instagram と X の動画。動画本体を自動で再生して繰り返し、押すと一時停止・再開する（ビューアだけ）。
/// 動画が取れない（Instagram が返さない、期限が切れた）ときは、サムネイルに再生のマークを重ね、押すと元の SNS を開く。
class _FileVideo extends ConsumerStatefulWidget {
  const _FileVideo({
    required this.post,
    required this.active,
    required this.start,
    required this.handle,
    required this.mini,
  });

  final Post post;
  final bool active;
  final Duration start;
  final PostVideoHandle? handle;
  final bool mini;

  @override
  ConsumerState<_FileVideo> createState() => _FileVideoState();
}

class _FileVideoState extends ConsumerState<_FileVideo>
    with WidgetsBindingObserver, _AudioFocusMixin {
  VideoPlayerController? _controller;
  bool _failed = false;

  /// 押して止めた。前面に戻ったときも、止めたままにする。
  bool _paused = false;

  @override
  bool get mini => widget.mini;
  @override
  bool get playing =>
      widget.active &&
      !_paused &&
      !_failed &&
      (widget.post.videoUrl?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.handle?._source = _position;
    widget.handle?.lastPosition = widget.start;
    if (widget.active) _start();
    syncFocus();
  }

  Future<Duration?> _position() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    return controller.value.position;
  }

  @override
  void didUpdateWidget(covariant _FileVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _paused = false;
      if (_controller == null) {
        _start();
      } else {
        _controller!.play();
      }
    } else {
      _controller?.pause();
    }
    syncFocus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active && !_paused) {
      _controller?.play();
    }
  }

  Future<void> _start() async {
    final url = widget.post.videoUrl;
    if (url == null || url.isEmpty) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    // 再生位置を、[PostVideoHandle.lastPosition] に控える。
    controller.addListener(() {
      if (controller.value.isInitialized) {
        widget.handle?.lastPosition = controller.value.position;
      }
    });
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (widget.start > Duration.zero) await controller.seekTo(widget.start);
      if (mounted && widget.active && !_paused) await controller.play();
    } catch (_) {
      if (_controller == controller) {
        _failed = true;
        widget.handle?.failed.value = true;
      }
    }
    if (mounted) {
      setState(() {});
      syncFocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.handle?._source == _position) widget.handle?._source = null;
    _controller?.dispose();
    releaseFocus();
    super.dispose();
  }

  void _togglePause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() => _paused = !_paused);
    _paused ? controller.pause() : controller.play();
    syncFocus();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final controller = _controller;
    final playable = (post.videoUrl?.isNotEmpty ?? false) && !_failed;
    final thumbnail = PostFullImage(post: post);
    if (!playable) return _UnplayableVideo(post: post, mini: widget.mini);
    if (controller == null || !controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          thumbnail,
          const Center(child: CircularProgressIndicator(color: Colors.white70)),
        ],
      );
    }
    return GestureDetector(
      onTap: _togglePause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          if (_paused) const Center(child: PlayMark()),
        ],
      ),
    );
  }
}

/// アプリで再生できない動画。SNS を問わず、サムネイルに再生のマークと文言を重ね、押すと元の SNS で開く（画面定義書 2.5.1）。
/// 固定ビューアでは、文言を出さず、再生のマークだけにする。
class _UnplayableVideo extends StatelessWidget {
  const _UnplayableVideo({required this.post, required this.mini});

  final Post post;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openPermalink(post),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PostFullImage(post: post),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PlayMark(),
                if (!mini) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.commonVideoUnplayable,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 動画の上に重ねる、再生のマーク。
class PlayMark extends StatelessWidget {
  const PlayMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }
}

/// 投稿の画像を、切らずに元の縦横比のまま、画面に収まる大きさで出す（画面定義書 2.5.1）。
/// 読み込むまでと、読み込めないときは、SNS の縦横比の灰色の面を出す。
class PostFullImage extends StatelessWidget {
  const PostFullImage({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: PostThumbnail(
        url: null,
        aspectRatio: post.thumbnailAspectRatio,
        iconSize: 48,
      ),
    );
    final url = post.thumbnailUrl;
    if (url == null || url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => placeholder,
      // 最初の絵が届くまでは、灰色の面を出す（loadingBuilder は、読み込みが始まる前は空になる）。
      frameBuilder: (_, child, frame, sync) =>
          frame == null && !sync ? placeholder : child,
    );
  }
}
