import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/oshi.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/live_strip_layout.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/post_cards.dart';
import '../../core/view_models/playback_provider.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../core/ui/live_player.dart';
import '../view_models/home_providers.dart';
import '../view_models/home_shell_viewmodel.dart';

/// ホームの配信ビューアの、初期位置モード（機能仕様書 4.3.4、画面定義書（ファン）2.2.1）。ホームのスクロールの中に置く sliver。
/// 配信中の推しを1人ずつ、映像の下の帯を横に払うか、帯の矢印を押して切り替える（端の次は、反対の端に戻る）。
/// いま出している1人の配信を、音を出して流す。映像を押すと、プレイヤーを操作できる（発信者ページには移らない）。
/// 映像の上では払えない（YouTube の規約：プレイヤーへのタッチで、アプリの操作を起こさない）。
/// 映像の上には何も重ねず、映像の下の帯に「● LIVE」・配信元のアイコン・推しのアイコン・矢印・何人目かの点・固定ビューアのボタンを出す（YouTube の規約）。
/// 固定ビューアで何か流している間と、配信中の推しがいないときは、何も出さない。
class HomeLivePanel extends ConsumerStatefulWidget {
  const HomeLivePanel({
    super.key,
    required this.oshis,
    required this.now,
    required this.scrollController,
    required this.top,
  });

  /// 推しレーンと同じ順の推し。このうち配信中の推しを出す。
  final List<Oshi> oshis;
  final DateTime now;

  /// ホームの縦のスクロール。面が半分より多く隠れたら、流さない。
  final ScrollController scrollController;

  /// スクロールの中での、面の上端の位置。
  final double top;

  @override
  ConsumerState<HomeLivePanel> createState() => _HomeLivePanelState();
}

class _HomeLivePanelState extends ConsumerState<HomeLivePanel> {
  /// 周回させるため、ページは数を決めずに並べ、ページの番号を人数で割った余りで推しを決める。
  /// 最初のページは、どちらへも十分に払えるよう、遠くに置く。
  static const _farPage = 10000;

  late final _pages = PageController(initialPage: _farPage);

  /// いま並べている配信。ページを送ったときに、推しを決めるのに使う。
  List<({Oshi oshi, Live live})> _lives = const [];

  /// 推しを外から切り替えて（推しレーン・人数が変わった）、ページを合わせている間。振動させない。
  bool _jumping = false;

  /// 帯を払っている間の、ページ送りのドラッグ。映像は指について横に動く。
  Drag? _drag;

  void _onStripDragStart(DragStartDetails d) {
    if (!_pages.hasClients) return;
    _drag = _pages.position.drag(d, () => _drag = null);
  }

  void _step(int step) {
    if (!_pages.hasClients) return;
    const duration = Duration(milliseconds: 280);
    step > 0
        ? _pages.nextPage(duration: duration, curve: Curves.easeOutCubic)
        : _pages.previousPage(duration: duration, curve: Curves.easeOutCubic);
  }

  void _onPageChanged(int page) {
    if (_jumping || _lives.isEmpty) return;
    HapticFeedback.selectionClick();
    ref
        .read(homeLiveViewerProvider.notifier)
        .select(_lives[page % _lives.length].oshi.id);
  }

  /// いまのページが、選んでいる推しと違えば（推しレーンで選んだ・人数が変わった）、近いページに移る。
  void _syncPage(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients || _lives.isEmpty) return;
      final count = _lives.length;
      final page = _pages.page?.round() ?? _farPage;
      if (page % count == index) return;
      _jumping = true;
      _pages.jumpToPage(page - page % count + index);
      _jumping = false;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);
    final viewer = ref.watch(homeLiveViewerProvider);
    // 固定ビューアで何か流している間は、映像が上下に2つ並ばないよう、埋め込みを出さない。
    final pinned = playback != null;
    final lives = _lives = [
      for (final oshi in widget.oshis)
        if (oshi.creator.liveAt(widget.now) case final live?)
          (oshi: oshi, live: live),
    ];
    if (pinned || lives.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final count = lives.length;
    final index = lives
        .indexWhere((l) => l.oshi.id == viewer.creatorId)
        .clamp(0, count - 1);
    _syncPage(index);
    final videoHeight = MediaQuery.sizeOf(context).width * 9 / 16;
    // 流すのは、ホームのタブを出していて、上に別の画面がなく、固定ビューアで何も流していないときだけ。
    final canPlay =
        ref.watch(homeShellViewModelProvider.select((s) => s.tab)) ==
            HomeTab.home &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        playback == null;
    final current = lives[index];
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(
            height: videoHeight,
            child: ListenableBuilder(
              listenable: widget.scrollController,
              builder: (context, _) {
                final controller = widget.scrollController;
                // 読み直しの間などは、同じスクロールが2つの画面に付くことがあるので、最初のものを見る。
                final offset = controller.positions.isEmpty
                    ? 0.0
                    : controller.positions.first.pixels;
                // 映像の半分以上が見えている間だけ流す（YouTube の規約）。
                final visible = offset <= widget.top + videoHeight / 2;
                // 映像の上では払えない。帯の払い（[_drag]）と矢印で、ページを送る。
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(dragDevices: const {}),
                  child: PageView.builder(
                    controller: _pages,
                    // 数を決めずに並べる（1人だけのときは、払えず、矢印も出さない）。
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, page) {
                      final i = page % count;
                      return _LiveVideo(
                        oshi: lives[i].oshi,
                        live: lives[i].live,
                        playing: canPlay && visible && i == index,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _LiveStrip(
            oshi: current.oshi,
            live: current.live,
            count: count,
            index: index,
            onStep: count >= 2 ? _step : null,
            onDragStart: count >= 2 ? _onStripDragStart : null,
            onDragUpdate: (d) => _drag?.update(d),
            onDragEnd: (d) => _drag?.end(d),
            onDragCancel: () => _drag?.cancel(),
          ),
        ],
      ),
    );
  }
}

/// 配信中の推し1人ぶんの映像（流さないときはサムネイル）。
/// 映像は、押すとプレイヤーを操作できる（YouTube・Twitch は公式プレイヤー、ツイキャスはミュートの切り替え）。
class _LiveVideo extends ConsumerWidget {
  const _LiveVideo({
    required this.oshi,
    required this.live,
    required this.playing,
  });

  final Oshi oshi;
  final Live live;
  final bool playing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (playing) {
      return LivePlayer(
        key: ValueKey(live.playbackUrl),
        live: live,
        mini: true,
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: live.thumbnailUrl == null
          ? const SizedBox.expand()
          : PostThumbnail(
              url: live.thumbnailUrl,
              aspectRatio: 16 / 9,
              iconSize: 32,
            ),
    );
  }
}

/// 映像の下の帯。左から「● LIVE」・配信元のアイコン・推しのアイコン、真ん中に矢印と何人目かの点（2人以上）、
/// 右端に固定ビューアのボタン。横に払うと、前後の推しへ。並びは、固定ビューアの帯と同じ決まり（[LiveStripMetrics]）。
class _LiveStrip extends ConsumerWidget {
  const _LiveStrip({
    required this.oshi,
    required this.live,
    required this.count,
    required this.index,
    required this.onStep,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final Oshi oshi;
  final Live live;
  final int count;
  final int index;

  /// 矢印を押したとき（-1 なら前、1 なら次）。1人だけなら null。
  final void Function(int step)? onStep;

  /// 帯を横に払ったとき（前後の推しに移る）。1人だけなら null。
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final GestureDragCancelCallback onDragCancel;

  static const height = 44.0;

  static const _metrics = LiveStripMetrics.regular;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final onStep = this.onStep;
    Widget button({
      required String tooltip,
      required VoidCallback onPressed,
      required Widget child,
    }) => LiveStripButton(
      metrics: _metrics,
      height: height,
      tooltip: tooltip,
      onPressed: onPressed,
      child: child,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: onDragStart,
      onHorizontalDragUpdate: onDragStart == null ? null : onDragUpdate,
      onHorizontalDragEnd: onDragStart == null ? null : onDragEnd,
      onHorizontalDragCancel: onDragStart == null ? null : onDragCancel,
      child: LiveStripLayout(
        metrics: _metrics,
        height: height,
        foreground: c.textSecondary,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 「LIVE」と配信元を1つにした印。押すと配信元を開く（tech-risks.md 2.22・2.23）。
            LiveSourceBadge(
              metrics: _metrics,
              service: live.service,
              tooltip: l10n.commonLiveOpenSource,
              onPressed: () => openLiveSource(live),
            ),
            button(
              tooltip: l10n.commonLiveOpenCreator,
              onPressed: () => CreatorScreen.open(context, oshi.id),
              child: AvatarImage(
                url: oshi.creator.avatarUrl,
                size: _metrics.size,
              ),
            ),
          ],
        ),
        center: onStep == null
            ? null
            : LiveStripStepper(
                metrics: _metrics,
                height: height,
                previousTooltip: l10n.commonLivePrevious,
                nextTooltip: l10n.commonLiveNext,
                onStep: onStep,
                position: (index: index, count: count),
                dotsColor: c.textPrimary,
              ),
        trailing: [
          LiveStripPinButton(
            metrics: _metrics,
            height: height,
            // この配信を、固定ビューアで開く。固定ビューアの間は、埋め込みを出さない。
            onPressed: () {
              ref
                  .read(playbackProvider.notifier)
                  .play(oshi.id, live, avatarUrl: oshi.creator.avatarUrl);
            },
          ),
        ],
      ),
    );
  }
}
