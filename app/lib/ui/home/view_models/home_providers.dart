import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/oshi.dart';
import '../../core/view_models/playback_provider.dart';

/// ホームの配信ビューアの、初期位置モードの状態（機能仕様書 4.3.4）。
class HomeLiveViewerState {
  const HomeLiveViewerState({this.creatorId});

  /// 初期位置モードで出している推し。null なら、配信中の推しの先頭。
  final String? creatorId;
}

class HomeLiveViewer extends Notifier<HomeLiveViewerState> {
  @override
  HomeLiveViewerState build() => const HomeLiveViewerState();

  /// 初期位置モードで出す推しを選ぶ（帯を払った・推しレーンで押した）。
  void select(String creatorId) {
    if (creatorId == state.creatorId) return;
    state = HomeLiveViewerState(creatorId: creatorId);
  }

  /// 固定ビューアから、初期位置モードに戻す。固定ビューアを閉じ、その推しを流す。
  void restore(String creatorId) {
    state = HomeLiveViewerState(creatorId: creatorId);
    ref.read(playbackProvider.notifier).close();
  }

  /// 配信ビューアを、その推しの配信に切り替える。固定ビューアで何か流していれば、固定ビューアのまま切り替える。
  void show(Oshi oshi, Live live) {
    if (ref.read(playbackProvider) != null) {
      ref
          .read(playbackProvider.notifier)
          .play(oshi.id, live, avatarUrl: oshi.creator.avatarUrl);
    }
    select(oshi.id);
  }
}

final homeLiveViewerProvider =
    NotifierProvider<HomeLiveViewer, HomeLiveViewerState>(HomeLiveViewer.new);

/// ホームを、いちばん上までスクロールする合図。値が変わるたびに、ホームがスクロールする。
class HomeScrollToTop extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final homeScrollToTopProvider = NotifierProvider<HomeScrollToTop, int>(
  HomeScrollToTop.new,
);

/// 配信ビューアで流している推しの ID（推しレーンの赤いリング）。
/// 固定ビューアで配信を流していればその推し、ほかは、初期位置モードで出している推し。
String? playingLiveCreatorId(
  List<Oshi> oshis,
  DateTime now,
  Playback? playback,
  HomeLiveViewerState viewer,
) {
  if (playback is LivePlayback) return playback.creatorId;
  if (playback != null) return null;
  final lives = [
    for (final o in oshis)
      if (o.creator.liveAt(now) != null) o.id,
  ];
  if (lives.isEmpty) return null;
  return lives.contains(viewer.creatorId) ? viewer.creatorId : lives.first;
}
