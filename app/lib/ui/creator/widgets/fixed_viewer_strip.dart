import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/ui/live_strip_layout.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/sns_style.dart';
import '../../core/view_models/playback_provider.dart';
import '../../oshi/widgets/find_creators_screen.dart';

/// 固定ビューアの映像の下の帯。並びは、ホームの配信ビューアの帯と同じ決まり（[LiveStripMetrics.regular]）。
/// 配信のときは、左から「LIVE」と配信元の印・推しのアイコン、真ん中に矢印と何人目かの点（2人以上のとき）。
/// 投稿の動画のときは、左に配信元のアイコン（押すと、ビューアで開く）。
/// ランダム再生のときは、左に推しのアイコンも出し、真ん中に前後の動画の矢印を出す。
class FixedViewerStrip extends StatelessWidget {
  const FixedViewerStrip({
    super.key,
    required this.playback,
    required this.position,
    required this.onOpenCreator,
    required this.avatarUrl,
    required this.onOpenPost,
    required this.onStep,
    required this.onSwipeStart,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
    required this.height,
    required this.onPlayShuffle,
    required this.onPlayLive,
  });

  /// 帯の色。払っている間に指の下に出すふくらみも、この色にする。
  static const background = Color(0xFF1F1F1F);

  /// 帯の高さ。
  final double height;

  final Playback playback;

  /// 何人目か（矢印の間の点）。配信のときだけ。
  final ({int index, int count})? position;
  final void Function(String creatorId) onOpenCreator;

  /// ランダム再生で流している動画の、推しのアイコン。ランダム再生でなければ null。
  final String? avatarUrl;

  /// 投稿の動画を、ビューアで開く。配信なら null。
  final VoidCallback? onOpenPost;

  /// 矢印を押したとき（-1 なら前、1 なら次）。出さないなら null。
  final void Function(int step)? onStep;

  /// 帯を横に払ったとき（配信とランダム再生だけ。投稿ビューアから入れた動画は null）。
  final GestureDragStartCallback? onSwipeStart;
  final GestureDragUpdateCallback onSwipeUpdate;
  final GestureDragEndCallback onSwipeEnd;

  /// ランダム再生に切り替える。ボタンを出さないなら null。
  final VoidCallback? onPlayShuffle;

  /// 配信に切り替える。ボタンを出さないなら null。
  final VoidCallback? onPlayLive;

  static const _metrics = LiveStripMetrics.regular;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final playback = this.playback;
    final onStep = this.onStep;
    final height = this.height;
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
    final swipe = onSwipeStart != null;
    return GestureDetector(
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: swipe ? onSwipeUpdate : null,
      onHorizontalDragEnd: swipe ? onSwipeEnd : null,
      child: ColoredBox(
        color: background,
        child: LiveStripLayout(
          metrics: _metrics,
          height: height,
          foreground: Colors.white,
          leading: switch (playback) {
            LivePlayback(:final live, :final creatorId, :final avatarUrl) =>
              Row(
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
                    onPressed: () => onOpenCreator(creatorId),
                    child: AvatarImage(url: avatarUrl, size: _metrics.size),
                  ),
                ],
              ),
            PostPlayback(:final post) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                button(
                  tooltip: l10n.commonOpenPost,
                  onPressed: onOpenPost ?? () {},
                  child: PlatformIcon(post.source, size: _metrics.size),
                ),
                if (playback.shuffle != null)
                  button(
                    tooltip: l10n.commonLiveOpenCreator,
                    onPressed: () => onOpenCreator(post.creatorId),
                    child: AvatarImage(url: avatarUrl, size: _metrics.size),
                  ),
              ],
            ),
          },
          center: onStep == null
              ? null
              : LiveStripStepper(
                  metrics: _metrics,
                  height: height,
                  previousTooltip: playback is PostPlayback
                      ? l10n.commonVideoPrevious
                      : l10n.commonLivePrevious,
                  nextTooltip: playback is PostPlayback
                      ? l10n.commonVideoNext
                      : l10n.commonLiveNext,
                  onStep: onStep,
                  position: position,
                ),
          trailing: [
            if (onPlayLive case final playLive?)
              button(
                tooltip: l10n.commonFixedViewerPlayLive,
                onPressed: playLive,
                child: const Icon(Icons.sensors),
              ),
            if (onPlayShuffle case final playShuffle?)
              button(
                tooltip: l10n.fixedViewerShufflePlay,
                onPressed: playShuffle,
                child: const Icon(Icons.video_library),
              ),
          ],
        ),
      ),
    );
  }
}

/// スイッチを入れたのに、流すもの（配信中の推し・推しの動画）がないときの案内。押すと、推しを探す画面を開く。
class FixedViewerEmptyPanel extends StatelessWidget {
  const FixedViewerEmptyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: FixedViewerStrip.background,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.smart_display_outlined, color: Colors.white70),
              const SizedBox(height: 8),
              Text(
                l10n.fixedViewerEmptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => FindCreatorsScreen.open(context),
                child: Text(l10n.commonFindCreatorsTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
