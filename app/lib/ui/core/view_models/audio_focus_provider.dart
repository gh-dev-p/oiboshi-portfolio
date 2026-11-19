import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 音を出してよい映像を、いちばん前の1つにする（機能仕様書 4.3.2）。
/// 状態は、いま前で流している映像（投稿ビューアで流している動画）の集まり。空でなければ、
/// 固定ビューアを一時停止し、ホームの埋め込みの配信は、流したまま音を消す。
class AudioFocus extends Notifier<Set<Object>> {
  @override
  Set<Object> build() => const {};

  // 画面を閉じたあと（次のフレーム）に呼ぶので、アプリごと閉じたあとなら何もしない。
  void acquire(Object owner) {
    if (!ref.mounted || state.contains(owner)) return;
    state = {...state, owner};
  }

  void release(Object owner) {
    if (!ref.mounted || !state.contains(owner)) return;
    state = {...state}..remove(owner);
  }
}

final audioFocusProvider = NotifierProvider<AudioFocus, Set<Object>>(
  AudioFocus.new,
);

/// 投稿ビューアで、動画を流しているか（ファンが止めている間は流していない）。
/// 流している間は、固定ビューアを一時停止する（機能仕様書 4.3.5。2026-11-19 本人）。
final viewerVideoPlayingProvider = Provider<bool>(
  (ref) => ref.watch(audioFocusProvider).isNotEmpty,
);

/// ホームの埋め込みの配信の音を消すか。投稿ビューアで動画を流している間は消す。
/// 固定ビューアは、その間は一時停止しているので、音を消す必要はない。
final liveAudioSuppressedProvider = Provider<bool>(
  (ref) => ref.watch(viewerVideoPlayingProvider),
);
