import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/models/creator.dart';
import '../../../l10n/app_localizations.dart';
import '../view_models/audio_focus_provider.dart';
import 'app_buttons.dart';
import 'embed_player.dart';

/// 配信の映像（画面定義書 2.4.2・2.4.3）。音を出して自動再生する。映像の上には何も重ねない（YouTube の規約）。
/// 「LIVE」・視聴者数・経過時間などは、映像の外（帯・タイトルの下）に出す。
/// ツイキャスは HLS を直接再生し、YouTube・Twitch は公式プレイヤーを埋め込む。
/// 親の大きさいっぱいに出す。ミュートのボタンは、プレイヤーの操作がないツイキャスだけに置く。
/// 固定ビューアと、ホームの初期位置モード（[mini] が真）のツイキャスは、映像を押すとミュートを切り替え、右下に音の印を出す（機能仕様書 4.3.4）。
/// 前で別の動画が音を出している間は、音を消す（機能仕様書 4.3.2）。
class LivePlayer extends ConsumerStatefulWidget {
  const LivePlayer({super.key, required this.live, this.mini = false});

  final Live live;

  /// 固定ビューアか、ホームの初期位置モードか。映像だけを出す（重ねる印は、使う側で出す）。
  final bool mini;

  @override
  ConsumerState<LivePlayer> createState() => _LivePlayerState();
}

class _LivePlayerState extends ConsumerState<LivePlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;

  /// 映像を再生できなかったか（ツイキャス・YouTube・Twitch）。「もう一度試す」で戻す。
  bool _failed = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.live.usesEmbed) _start();
  }

  @override
  void didUpdateWidget(LivePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.live.playbackUrl != widget.live.playbackUrl) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      if (!widget.live.usesEmbed) _start();
    }
  }

  /// 「もう一度試す」。ツイキャスは再生し直す。YouTube・Twitch は、失敗の表示を外すと、
  /// プレイヤー（WebView）が作り直される（画面定義書 2.4.2）。
  void _retry() {
    setState(() => _failed = false);
    if (widget.live.usesEmbed) return;
    _controller?.dispose();
    _controller = null;
    _start();
  }

  /// アプリが前面に戻ったときは、再生し直す（機能仕様書 4.3.2）。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller?.play();
  }

  Future<void> _start() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.live.playbackUrl),
      formatHint: VideoFormat.hls,
    );
    _controller = controller;
    _failed = false;
    try {
      await controller.initialize();
      await controller.setVolume(_volume);
      await controller.play();
    } catch (_) {
      if (_controller == controller) _failed = true;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// ツイキャスの音量。ミュートか、前で別の動画が音を出していれば 0。
  double get _volume => _muted || ref.read(liveAudioSuppressedProvider) ? 0 : 1;

  /// 前の動画（YouTube）が音を出すと、iOS は後ろの映像を止めることがあるので、音を戻すときに確かめる。
  /// 止まっていたら、読み直して、いちばん新しい位置から流す（そのまま再開すると、リアルタイムから遅れる）。
  void _resumeIfStopped() {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isPlaying) {
      return;
    }
    controller.dispose();
    _controller = null;
    _start();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_volume);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(liveAudioSuppressedProvider, (_, suppressed) {
      _controller?.setVolume(_volume);
      if (!suppressed) _resumeIfStopped();
    });
    final audioSuppressed = ref.watch(liveAudioSuppressedProvider);
    final live = widget.live;
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final Widget video;
    if (_failed) {
      video = _FailedView(mini: widget.mini, onRetry: _retry);
    } else if (live.usesEmbed) {
      video = EmbedPlayer(
        url: live.playbackUrl,
        audioSuppressed: audioSuppressed,
        onFailed: () {
          if (mounted) setState(() => _failed = true);
        },
      );
    } else if (controller != null && controller.value.isInitialized) {
      video = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    } else {
      video = const Center(
        child: Icon(Icons.play_circle, size: 48, color: Colors.white70),
      );
    }
    final mini = widget.mini;
    // 固定ビューア・初期位置モードのツイキャスは、映像を押してミュートを切り替える（プレイヤーの操作がないため）。
    final tapToMute = mini && !live.usesEmbed && !_failed;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (tapToMute)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleMute,
              child: video,
            )
          else
            video,
          if (tapToMute)
            Positioned(
              right: 6,
              bottom: 6,
              child: IgnorePointer(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.54),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _muted ? Icons.volume_off : Icons.volume_up,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // YouTube・Twitch は、公式プレイヤーの音量の操作を使う。
          if (!mini && !live.usesEmbed)
            Positioned(
              right: 4,
              bottom: 4,
              child: CircleIconButton(
                icon: _muted ? Icons.volume_off : Icons.volume_up,
                size: 40,
                iconSize: 24,
                tooltip: _muted ? l10n.commonLiveUnmute : l10n.commonLiveMute,
                onPressed: _toggleMute,
              ),
            ),
        ],
      ),
    );
  }
}

/// 映像を再生できなかったときに、映像の場所に出す。
/// 固定ビューアと、ホームの初期位置モード（[mini] が真）では、文言とボタンを出さず、印だけを出す。
class _FailedView extends StatelessWidget {
  const _FailedView({required this.mini, required this.onRetry});

  final bool mini;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (mini) {
      return const Center(
        child: Icon(Icons.error_outline, size: 32, color: Colors.white70),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.commonLiveVideoFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          AppTextButton(
            label: l10n.commonTryAgain,
            color: Colors.white,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
