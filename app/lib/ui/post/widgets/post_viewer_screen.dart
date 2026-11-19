import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/post.dart';
import '../../core/ui/swipe_direction.dart';
import '../view_models/post_view_tracker.dart';
import '../view_models/post_viewer_viewmodel.dart';
import '../../core/ui/post_video.dart';
import 'post_viewer_parts.dart';
import '../../core/view_models/playback_provider.dart';
import '../../../l10n/app_localizations.dart';

/// 投稿ビューア（画面定義書 2.5.1）。黒の背景に、投稿を1件ずつ見る。
/// 固定ビューアを出している間は、固定ビューアの下の領域に出す（固定ビューアは隠さず、流し続ける。機能仕様書 4.3.5）。
/// 出していなければ、画面全体に出す。
/// 上下のスワイプで前後の投稿へ、右へのスワイプまたは閉じるボタンで閉じる。左へのスワイプは、再生できる動画なら固定ビューアで流す。
/// カルーセルは、左右のスワイプで中の画像を送り、端でさらにスワイプすると閉じる。
/// 再生できる動画は、左下（投稿者の行の上）の固定ビューアのボタンで、見ていた位置から固定ビューアで流し続けられる（画面定義書 2.4.3）。
/// 投稿の動画が流れている間は、固定ビューアの音を消す（音の取り合い）。
class PostViewerScreen extends ConsumerStatefulWidget {
  const PostViewerScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.authorOf,
    this.onOpenAuthor,
    this.initialStart = Duration.zero,
    this.onClosed,
  });

  final List<Post> posts;
  final int initialIndex;

  /// 閉じたとき。閉じたときに見ていた投稿と、その動画の最後に分かった再生位置（動画でなければ null）を渡す。
  /// 固定ビューアの動画をビューアで開いたとき、閉じたら、ビューアで見ていた位置から続けるのに使う。
  final void Function(Post post, Duration? position)? onClosed;

  /// 最初の投稿の動画を、始める位置（固定ビューアから開いたときの続き）。
  final Duration initialStart;
  final Creator? Function(Post post) authorOf;

  /// 下のアイコン・名前を押したとき（ビューアを閉じたあとに呼ぶ）。null なら押せない。
  final void Function(Creator author)? onOpenAuthor;

  /// 下部ナビの外（アプリの根元の Navigator）に開く。固定ビューアを出している間は、その下の領域に出す。
  static Future<void> open(
    BuildContext context, {
    required List<Post> posts,
    required int initialIndex,
    required Creator? Function(Post post) authorOf,
    void Function(Creator author)? onOpenAuthor,
    Duration initialStart = Duration.zero,
    void Function(Post post, Duration? position)? onClosed,
  }) {
    // 出ているスナックバーは先に消す（全画面のビューアに隠れるうえ、残してあるタブの画面にも組み立てられていて、
    // 開くときの画面の切り替えで重なってしまうため）。
    ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
    return Navigator.of(context, rootNavigator: true).push(
      _PostViewerRoute(
        pageBuilder: (_, _, _) => PostViewerScreen(
          posts: posts,
          initialIndex: initialIndex,
          authorOf: authorOf,
          onOpenAuthor: onOpenAuthor,
          initialStart: initialStart,
          onClosed: onClosed,
        ),
      ),
    );
  }

  @override
  ConsumerState<PostViewerScreen> createState() => _PostViewerScreenState();
}

class _PostViewerScreenState extends ConsumerState<PostViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late final _args = PostViewerArgs(
    posts: widget.posts,
    initialIndex: widget.initialIndex,
    initialStart: widget.initialStart,
  );

  /// 投稿ごとの、動画の再生位置を聞く窓口（キーは投稿の ID）。
  final _videoHandles = <String, PostVideoHandle>{};

  PostVideoHandle _handleOf(Post post) =>
      _videoHandles.putIfAbsent(post.id, PostVideoHandle.new);

  /// カルーセルごとの、見ている枚数（キーは投稿の ID）。前後の投稿から戻っても、同じ枚を出す。
  final _carouselPages = <String, ValueNotifier<int>>{};

  ValueNotifier<int> _carouselPageOf(Post post) =>
      _carouselPages.putIfAbsent(post.id, () => ValueNotifier(0));

  /// 画像・動画ファイルを拡大しているか。拡大している間は、上下・左右のスワイプで投稿・画像を送らず、閉じもしない。
  final _zoomed = ValueNotifier(false);

  /// 2本以上の指が触れているか。触れている間は、2本の指の拡大に渡すため、投稿・画像を送らない。
  final _pinching = ValueNotifier(false);

  /// 投稿・画像の送りと、左右の払いを止めているか（拡大しているか、2本以上の指が触れている）。
  final _locked = ValueNotifier(false);

  /// 触れている指の数。
  int _pointers = 0;

  void _updateLocked() => _locked.value = _zoomed.value || _pinching.value;

  void _onPointerDown(PointerDownEvent _) {
    _pointers++;
    if (_pointers >= 2) _pinching.value = true;
  }

  void _onPointerUp(PointerEvent _) {
    if (_pointers > 0) _pointers--;
    if (_pointers == 0) _pinching.value = false;
  }

  /// いま見ている投稿。閉じたときに、[PostViewerScreen.onClosed] に渡す。
  late Post _current = widget.posts[widget.initialIndex];

  /// 開いた数（届ける・広める仕様書 4.2.3）に数えた投稿。このビューアの中では、同じ投稿を1回だけ数える。
  final _countedOpened = <String>{};

  /// 投稿が出たことを、開いた数に数える（押して開いた投稿と、スワイプで出た投稿）。
  void _countOpened(Post post) {
    if (_countedOpened.add(post.id)) {
      ref.read(postViewTrackerProvider).opened(post);
    }
  }

  @override
  void initState() {
    super.initState();
    _zoomed.addListener(_updateLocked);
    _pinching.addListener(_updateLocked);
    _countOpened(widget.posts[widget.initialIndex]);
  }

  @override
  void dispose() {
    final post = _current;
    final position = post.isFileVideo || post.youtubeVideoId != null
        ? _videoHandles[post.id]?.lastPosition
        : null;
    final onClosed = widget.onClosed;
    // 画面を閉じたあと（次のフレーム）に、続きの位置を渡す。
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onClosed?.call(post, position),
    );
    for (final page in _carouselPages.values) {
      page.dispose();
    }
    for (final handle in _videoHandles.values) {
      handle.failed.dispose();
    }
    _controller.dispose();
    _swipeBack.dispose();
    _zoomed.dispose();
    _pinching.dispose();
    _locked.dispose();
    super.dispose();
  }

  /// 左右に払っている量。投稿は、指について横に動く。
  double _swipe = 0;
  double _swipeFrom = 0;

  /// 払いが決まらずに離したとき、元の位置へ戻すアニメーション。
  late final AnimationController _swipeBack =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      )..addListener(
        () => setState(
          () => _swipe =
              _swipeFrom *
              (1 - Curves.easeOutCubic.transform(_swipeBack.value)),
        ),
      );

  /// いまの投稿を、固定ビューアに入れられるか（再生できる動画で、再生できないと分かっていない）。
  bool _canMinimize(Post post) =>
      PostVideo.canPlay(post) && !_handleOf(post).failed.value;

  void _onSwipeStart(DragStartDetails _) => _swipeBack.stop();

  /// 左へ払っても固定ビューアに入れられない投稿では、少しだけ動かす（離すと戻る）。
  void _onSwipeUpdate(DragUpdateDetails d) {
    final next = _swipe + d.delta.dx;
    final damping = next < 0 && !_canMinimize(_current) ? 0.3 : 1.0;
    setState(() => _swipe += d.delta.dx * damping);
  }

  /// 速く払うか、画面の幅の 30% より多く動かしたら決める。右は閉じる。左は、再生できる動画なら、
  /// 固定ビューアで流す（固定ビューアのボタンと同じ）。決まらなければ、元の位置へ戻す。
  void _onSwipeEnd(DragEndDetails d) {
    final direction = swipeDirection(
      velocity: d.primaryVelocity ?? 0,
      offset: _swipe,
      width: MediaQuery.sizeOf(context).width,
      minVelocity: 300,
      ratio: 0.3,
    ).sign;
    if (direction > 0) {
      Navigator.of(context).pop();
      return;
    }
    if (direction < 0 && _canMinimize(_current)) {
      _minimize();
      return;
    }
    _swipeFrom = _swipe;
    _swipeBack.forward(from: 0);
  }

  /// ビューアを閉じてから、いま見ているタブに発信者ページを開く。
  void Function(Creator author)? get _openAuthor {
    final open = widget.onOpenAuthor;
    if (open == null) return null;
    return (author) {
      Navigator.of(context).pop();
      open(author);
    };
  }

  /// いまの動画を、見ていた位置から固定ビューアで流し、ビューアを閉じる。
  Future<void> _minimize() async {
    final vm = ref.read(postViewerViewModelProvider(_args).notifier);
    final post = vm.current;
    await vm.minimize(
      author: widget.authorOf(post),
      position: _handleOf(post).position,
      canOpenAuthor: widget.onOpenAuthor != null,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// 固定ビューアに入れるボタン。再生できる動画のときだけ出し、再生できないと分かったら隠す。
  /// 投稿者の行のすぐ上（左下）に出す（画面定義書 2.5.1）。
  Widget? _pinButton(Post post) {
    if (!PostVideo.canPlay(post)) return null;
    return ValueListenableBuilder(
      valueListenable: _handleOf(post).failed,
      builder: (context, failed, _) => failed
          ? const SizedBox.shrink()
          : PostViewerPinButton(onPressed: _minimize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final vm = ref.read(postViewerViewModelProvider(_args).notifier);
    final index = ref.watch(postViewerViewModelProvider(_args)).index;
    final current = widget.posts[index];
    _current = current;
    // 固定ビューアの占める高さ（出していなければ 0）。
    final inset = ref.watch(fixedViewerInsetProvider);
    final viewer = Scaffold(
      backgroundColor: Colors.black,
      // 触れている指の数を数える（2本目が触れたら、送りを止めて、2本の指の拡大に渡す）。
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: ValueListenableBuilder(
          valueListenable: _locked,
          builder: (context, zoomed, _) => GestureDetector(
            // 右へ払うと閉じ、左へ払うと、再生できる動画を固定ビューアで流す。払っている間は、指について横に動く。
            // 拡大している間は、1本の指の動きを拡大した画面の移動に使うので、払いを受けない。
            onHorizontalDragStart: zoomed ? null : _onSwipeStart,
            onHorizontalDragUpdate: zoomed ? null : _onSwipeUpdate,
            onHorizontalDragEnd: zoomed ? null : _onSwipeEnd,
            child: Transform.translate(
              offset: Offset(_swipe, 0),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    scrollDirection: Axis.vertical,
                    // 拡大している間は、前後の投稿へ送らない。
                    physics: zoomed
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    // 前後の投稿も組み立てておき、画像を移る前から読み込む。
                    allowImplicitScrolling: true,
                    itemCount: widget.posts.length,
                    onPageChanged: (i) {
                      // 次の投稿へ移ったら、拡大は元に戻す（前の投稿の拡大は、表示中でなくなった所で戻る）。
                      _zoomed.value = false;
                      vm.showPost(i);
                      _countOpened(widget.posts[i]);
                    },
                    itemBuilder: (context, i) => PostViewerPage(
                      post: widget.posts[i],
                      author: widget.authorOf(widget.posts[i]),
                      now: now,
                      active: i == index,
                      start: vm.startOf(i),
                      videoHandle: _handleOf(widget.posts[i]),
                      carouselPage: _carouselPageOf(widget.posts[i]),
                      onOpenAuthor: _openAuthor,
                      pinButton: i == index
                          ? _pinButton(widget.posts[i])
                          : null,
                      zoomed: _zoomed,
                      locked: _locked,
                      belowFixedViewer: inset > 0,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: MediaQuery.paddingOf(context).top + 12,
                    child: IconButton(
                      tooltip: AppLocalizations.of(context)!.commonClose,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: MediaQuery.paddingOf(context).bottom + 48,
                    child: PostViewerSideActions(post: current),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // 固定ビューアを出している間は、その下の領域に出す（固定ビューアの出し消し・大きさの変化にも合わせる）。
    // 上の余白（ステータスバー）は、固定ビューアが受け持つので、ビューアの中では 0 にする。
    return TweenAnimationBuilder<double>(
      tween: Tween(end: inset),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, top, child) {
        final media = MediaQuery.of(context);
        final statusBar = (media.padding.top - top).clamp(
          0.0,
          media.padding.top,
        );
        final content = Padding(
          padding: EdgeInsets.only(top: top),
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(top: statusBar),
              viewPadding: media.viewPadding.copyWith(top: statusBar),
            ),
            child: child!,
          ),
        );
        // 画面全体に出しているときは、後ろの画面を読み上げない（幕を張らない代わり）。
        return top == 0 ? BlockSemantics(child: content) : content;
      },
      child: viewer,
    );
  }
}

/// 投稿ビューアの画面の切り替え（ふわっと出す）。後ろを塞ぐ幕を張らない。
/// 固定ビューアを出している間は、ビューアをその下の領域にだけ出し、固定ビューアは触れるまま残すため。
/// 画面全体に出しているときは、ビューアの黒の背景が、後ろへの操作を受け止める。
class _PostViewerRoute extends PageRouteBuilder<void> {
  _PostViewerRoute({required super.pageBuilder})
    : super(
        opaque: false,
        fullscreenDialog: true,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  @override
  Widget buildModalBarrier() => const SizedBox.shrink();
}
