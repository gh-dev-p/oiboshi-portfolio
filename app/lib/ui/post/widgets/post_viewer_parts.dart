import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/glass_surface.dart';
import '../../core/ui/link_text.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/page_dots.dart';
import '../../core/ui/post_cards.dart';
import '../../core/ui/post_video.dart';
import '../../core/ui/sns_style.dart';
import 'zoomable_media.dart';

/// 投稿ビューアの、投稿1件ぶんのページ。画像・動画・カルーセル・文章と、下の投稿者の行と本文。
/// YouTube のプレイヤーの、縦と横の最小の大きさ（Required Minimum Functionality。200×200 以上）。
const youtubePlayerMinSide = 200.0;

/// 投稿ビューアで、[space] に置く YouTube のプレイヤーの大きさ。縦横比 [ratio] で入るだけ大きくし、
/// 縦か横が [youtubePlayerMinSide] に足りなければ、その向きだけ広げる（はみ出た所は、映像の左右・上下を黒にする）。
/// 広げても [space] に入らなければ null（流さない）。
Size? youtubePlayerSize(Size space, double ratio) {
  var width = space.width;
  var height = width / ratio;
  if (height > space.height) {
    height = space.height;
    width = height * ratio;
  }
  if (width < youtubePlayerMinSide) width = youtubePlayerMinSide;
  if (height < youtubePlayerMinSide) height = youtubePlayerMinSide;
  if (width > space.width || height > space.height) return null;
  return Size(width, height);
}

class PostViewerPage extends StatefulWidget {
  const PostViewerPage({
    super.key,
    required this.post,
    required this.author,
    required this.now,
    required this.active,
    required this.start,
    required this.videoHandle,
    required this.carouselPage,
    required this.onOpenAuthor,
    this.pinButton,
    required this.zoomed,
    required this.locked,
    this.belowFixedViewer = false,
  });

  final Post post;
  final Creator? author;
  final DateTime now;
  final void Function(Creator author)? onOpenAuthor;

  /// 表示中のページ。動画は、表示中のページだけ再生する。
  final bool active;

  /// 動画を始める位置。
  final Duration start;
  final PostVideoHandle videoHandle;

  /// カルーセルの、見ている枚数。
  final ValueNotifier<int> carouselPage;

  /// 投稿者の行のすぐ上に出す、固定ビューアに入れるボタン（[PostViewerPinButton]）。出さないなら null。
  final Widget? pinButton;

  /// 画像・動画ファイルを拡大しているか（[ZoomableMedia]）。拡大している間は、ビューアが投稿・画像を送らない。
  final ValueNotifier<bool> zoomed;

  /// 送りを止めているか（拡大しているか、2本以上の指が触れている）。止めている間は、カルーセルも送らない。
  final ValueListenable<bool> locked;

  /// 固定ビューアの下の領域に出しているか。出しているときは、画像・動画・文章を、上の閉じるボタンと、
  /// 下の投稿者の行・本文・右の操作を避けた残りの高さの、上下の真ん中に置く（画面定義書 2.5.1）。
  /// 画面全体のときは、今までどおり、ページ全体の真ん中に置く。
  final bool belowFixedViewer;

  /// 上の閉じるボタンを避ける高さ（ステータスバーの下から）。
  static const double topReserve = 64;

  /// 右下の操作（[PostViewerSideActions]）を避ける高さ（下の余白から）。ビューアが置く下の空き 48 と、
  /// 視聴数（あるときだけ）・「開く」の高さ（1つ 54 ほど、間に 4）。
  static double sideActionsReserve(Post post) =>
      48 + (post.viewCount != null ? 112 : 58);

  @override
  State<PostViewerPage> createState() => _PostViewerPageState();
}

class _PostViewerPageState extends State<PostViewerPage> {
  /// 下の投稿者の行・本文の高さ（組み立てたあとに測る）。
  final _panelHeight = ValueNotifier<double?>(null);

  @override
  void dispose() {
    _panelHeight.dispose();
    super.dispose();
  }

  Post get post => widget.post;
  Creator? get author => widget.author;
  DateTime get now => widget.now;
  void Function(Creator author)? get onOpenAuthor => widget.onOpenAuthor;
  bool get active => widget.active;
  Duration get start => widget.start;
  PostVideoHandle get videoHandle => widget.videoHandle;
  ValueNotifier<int> get carouselPage => widget.carouselPage;
  Widget? get pinButton => widget.pinButton;
  ValueNotifier<bool> get zoomed => widget.zoomed;
  ValueListenable<bool> get locked => widget.locked;

  @override
  Widget build(BuildContext context) {
    final hasImage = post.thumbnailUrl != null || post.isFileVideo;
    final isX = post.source == SnsService.x;
    final padding = MediaQuery.paddingOf(context);
    final authorButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: author == null || onOpenAuthor == null
          ? null
          : () => onOpenAuthor!(author!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarImage(url: author?.avatarUrl, size: 32),
          const SizedBox(width: 8),
          Flexible(
            child: OneLineText(
              author?.name ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    return ColoredBox(
      color: const Color(0xFF3A3A44),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!widget.belowFixedViewer)
            _media(null)
          else
            // 下の投稿者の行・本文を測るまでは出さない（一瞬ずれた所に出さない）。
            ValueListenableBuilder(
              valueListenable: _panelHeight,
              builder: (context, panel, _) {
                if (panel == null) return const SizedBox.shrink();
                final side =
                    padding.bottom + PostViewerPage.sideActionsReserve(post);
                final bottom = panel > side ? panel : side;
                return _media(
                  EdgeInsets.only(
                    top: padding.top + PostViewerPage.topReserve,
                    bottom: bottom,
                  ),
                );
              },
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _HeightReporter(
              onHeight: (h) => _panelHeight.value = h,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  24,
                  80,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0, 0.3, 1],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (post.isCarousel) ...[
                      Center(
                        child: ValueListenableBuilder(
                          valueListenable: carouselPage,
                          builder: (_, page, _) =>
                              PageDots(count: post.media.length, index: page),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (pinButton case final pin?) ...[
                      pin,
                      const SizedBox(height: 12),
                    ],
                    // アイコン・名前を押すと、発信者ページへ。右に、投稿元のバッジ（X は、X の投稿者と X のロゴ）。
                    if (isX)
                      WithXAuthorLine(
                        leading: authorButton,
                        author: author,
                        onDark: true,
                      )
                    else
                      Row(
                        children: [
                          Flexible(child: authorButton),
                          const SizedBox(width: 8),
                          SourceBadge(post.source),
                        ],
                      ),
                    if (hasImage && post.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      LinkText(
                        post.text,
                        fallbackUrl: Uri.tryParse(post.permalink),
                        xEntities: isX,
                        // 投稿ビューアは黒の背景なので、ダークのリンクの色。
                        linkColor: AppColors.dark.link,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // 時間（X は「Xで見る」も）を押すと、元の投稿を開く。
                    PostTimeLink(
                      post: post,
                      text: relativeTime(
                        post.postedAt,
                        now: now,
                        l10n: AppLocalizations.of(context)!,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      strongColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 画像・動画・カルーセル・文章。[area] は、固定ビューアの下で中身を置く範囲（ページの端からの空き）。
  /// null なら画面全体のときの置き方。画像・動画ファイルは、拡大の範囲をページ全体のまま、中身だけを [area] に置く。
  Widget _media(EdgeInsets? area) {
    final hasImage = post.thumbnailUrl != null || post.isFileVideo;
    final isX = post.source == SnsService.x;
    final padding = MediaQuery.paddingOf(context);
    Widget inArea(Widget child) =>
        area == null ? child : Padding(padding: area, child: child);
    // 画像と動画ファイルは、拡大できる。YouTube の埋め込みは、拡大しない。
    if (post.isFileVideo) {
      return ZoomableMedia(
        active: active,
        zoomed: zoomed,
        child: inArea(
          PostVideo(
            post: post,
            active: active,
            start: start,
            handle: videoHandle,
            autoplay: !widget.belowFixedViewer,
          ),
        ),
      );
    }
    // YouTube は、表示中のページだけプレイヤーを作り、ほかはサムネイルを出す（WebView をいくつも動かさない）。
    // プレイヤーは、閉じるボタンと下の本文・右の数を避けた範囲に置き、何も重ねない（YouTube の規約）。
    if (post.youtubeVideoId != null && active) {
      return Padding(
        padding:
            area ??
            EdgeInsets.fromLTRB(0, padding.top + 64, 0, padding.bottom + 190),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = youtubePlayerSize(
              constraints.biggest,
              post.thumbnailAspectRatio,
            );
            // 固定ビューアの下の狭い領域で、規約の最小の大きさが取れなければ、流さずにサムネイルだけ出す
            // （2026-11-19 本人）。
            if (size == null) return PostFullImage(post: post);
            // プレイヤーそのもの（公式の埋め込み）を、この大きさにする。縦横比の違う所は、プレイヤーが黒で埋める。
            return Center(
              child: SizedBox.fromSize(
                size: size,
                child: PostVideo(
                  post: post,
                  start: start,
                  handle: videoHandle,
                  autoplay: !widget.belowFixedViewer,
                ),
              ),
            );
          },
        ),
      );
    }
    if (post.isCarousel) {
      return _Carousel(
        post: post,
        active: active,
        page: carouselPage,
        zoomed: zoomed,
        locked: locked,
        area: area,
        autoplay: !widget.belowFixedViewer,
      );
    }
    if (hasImage) {
      return ZoomableMedia(
        active: active,
        zoomed: zoomed,
        child: inArea(PostFullImage(post: post)),
      );
    }
    return _TextBody(
      text: post.text,
      fallbackUrl: Uri.tryParse(post.permalink),
      xEntities: isX,
      area: area,
    );
  }
}

/// 子の高さを測って [onHeight] で知らせる（組み立てのあと、変わったときだけ）。
class _HeightReporter extends SingleChildRenderObjectWidget {
  const _HeightReporter({required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeightReporter(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightReporter renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderHeightReporter extends RenderProxyBox {
  _RenderHeightReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(height);
    });
  }
}

/// カルーセル（Instagram のカルーセルと、画像・動画が2つ以上ある X の投稿）。画像と動画を横に並べ、左右のスワイプで送る（画面定義書 2.5.1）。
/// 最初の枚で右へ、最後の枚で左へ、さらにスワイプするとビューアを閉じる。
class _Carousel extends StatefulWidget {
  const _Carousel({
    required this.post,
    required this.active,
    required this.page,
    required this.zoomed,
    required this.locked,
    this.area,
    this.autoplay = true,
  });

  final Post post;

  /// 中の動画を、開いたら自動で流すか（固定ビューアを開いている間は、押すまで流さない）。
  final bool autoplay;

  /// 固定ビューアの下で、中の画像・動画を置く範囲（[PostViewerPage] の `_media`）。null なら画面全体のとき。
  final EdgeInsets? area;

  /// 表示中の投稿か。中の動画は、表示中の投稿の、表示中の枚だけ再生する。
  final bool active;
  final ValueNotifier<int> page;

  /// 中の画像・動画を拡大しているか。
  final ValueNotifier<bool> zoomed;

  /// 送りを止めているか（拡大しているか、2本以上の指が触れている）。止めている間は、左右に送らない。
  final ValueListenable<bool> locked;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  /// 端から、この長さを超えてスワイプしたら閉じる。
  static const _closeDistance = 48.0;

  late final PageController _controller = PageController(
    initialPage: widget.page.value,
  );
  double _overscroll = 0;
  bool _closing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      _overscroll += notification.overscroll;
      if (!_closing && _overscroll.abs() > _closeDistance) {
        _closing = true;
        Navigator.of(context).pop();
      }
    } else if (notification is ScrollStartNotification ||
        notification is ScrollEndNotification) {
      _overscroll = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ValueListenableBuilder(
            valueListenable: widget.page,
            builder: (context, page, _) => ValueListenableBuilder(
              valueListenable: widget.locked,
              builder: (context, zoomed, _) => PageView.builder(
                controller: _controller,
                // 端の、さらに先へのスワイプを知るため、端で跳ね返らせない。拡大している間は、送らない。
                physics: zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                // 前後の枚も組み立てておき、画像を移る前から読み込む。
                allowImplicitScrolling: true,
                itemCount: post.media.length,
                onPageChanged: (i) => widget.page.value = i,
                itemBuilder: (context, i) {
                  final item = post.mediaAt(i);
                  final shown = widget.active && i == page;
                  return ZoomableMedia(
                    active: shown,
                    zoomed: widget.zoomed,
                    child: Padding(
                      padding: widget.area ?? EdgeInsets.zero,
                      child: item.isFileVideo
                          ? PostVideo(
                              post: item,
                              active: shown,
                              autoplay: widget.autoplay,
                            )
                          : PostFullImage(post: item),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // 右上に、何枚目か（Instagram と同じ）。
        Positioned(
          right: 16,
          top: MediaQuery.paddingOf(context).top + 20,
          child: ValueListenableBuilder(
            valueListenable: widget.page,
            builder: (_, page, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${page + 1}/${post.media.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// サムネイルのない文章だけの投稿。本文を中央に大きく出す（文字数が多いほど小さくし、長文はスクロールする）。
class _TextBody extends StatelessWidget {
  const _TextBody({
    required this.text,
    required this.fallbackUrl,
    this.xEntities = false,
    this.area,
  });

  final String text;
  final Uri? fallbackUrl;
  final bool xEntities;

  /// 固定ビューアの下で、本文を置く範囲。null なら画面全体のとき。
  final EdgeInsets? area;

  @override
  Widget build(BuildContext context) {
    final length = text.length;
    final size = length < 40
        ? 28.0
        : length < 120
        ? 22.0
        : length < 280
        ? 18.0
        : 16.0;
    final body = Center(
      child: SingleChildScrollView(
        child: LinkText(
          text,
          fallbackUrl: fallbackUrl,
          xEntities: xEntities,
          // 投稿ビューアは黒の背景なので、ダークのリンクの色。
          linkColor: AppColors.dark.link,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size, height: 1.5, color: Colors.white),
        ),
      ),
    );
    final area = this.area;
    if (area != null) {
      return Padding(padding: area.copyWith(left: 24, right: 24), child: body);
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 200),
        child: body,
      ),
    );
  }
}

/// 投稿ビューアの右の操作（再生回数、元の投稿を開く）。
/// 固定ビューアに入れるボタン。見た目は、下部ナビの固定ビューアのコントローラー（すりガラスの丸と、中のアイコン）に寄せる。
class PostViewerPinButton extends StatelessWidget {
  const PostViewerPinButton({super.key, required this.onPressed});

  /// 丸の大きさ。
  static const double size = 44;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: AppLocalizations.of(context)!.commonLivePin,
      child: GlassSurface(
        width: size,
        height: size,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(
                Icons.smart_display_outlined,
                size: 22,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 投稿ビューアの右下の操作（視聴数・開く）。本文や映像のじゃまにならないよう、小さく薄く出す。
class PostViewerSideActions extends StatelessWidget {
  const PostViewerSideActions({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (post.viewCount != null)
          _SideAction(
            icon: Icons.visibility,
            label: compactCount(post.viewCount!, l10n),
          ),
        const SizedBox(height: 4),
        _SideAction(
          icon: Icons.open_in_new,
          label: l10n.postOpen,
          onTap: () => openPermalink(post),
        ),
      ],
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({required this.icon, required this.label, this.onTap});

  /// 色。白を薄くして、目立たせない。
  static final color = Colors.white.withValues(alpha: 0.6);

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      // 小さくしても、押せる範囲は 48 四方より狭くしない。
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
