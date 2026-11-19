import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../core/view_models/clock_provider.dart';
import '../../core/view_models/playback_provider.dart';
import '../../oshi/view_models/oshi_providers.dart';

/// 固定ビューアで流していた配信が終わった、という知らせ。知らせるたびに、別のものを作る。
class LiveEnded {
  LiveEnded(this.creatorId);

  final String creatorId;
}

/// 配信を流しているあいだ、その発信者が配信中かを確かめ続ける（機能仕様書 4.3.2）。
/// 発信者ページを閉じたあとも、発信者の情報（1分ごとに読み直す）を聞き続ける。
/// 配信が終わったと分かったら、[LiveEnded] を知らせてから、流しているものを閉じる。
/// 終わりの判定は、ここにまとめる（発信者ページが先に気づいたときも、[end] を通す）。
/// 同じ発信者のまま配信元が替わったら（ツイキャスが終わって YouTube が続いているなど）、新しい配信で流し直す。
/// 投稿の動画は、確かめない。
class LiveEndWatcher extends Notifier<LiveEnded?> {
  @override
  LiveEnded? build() {
    final playback = ref.watch(playbackProvider);
    if (playback is LivePlayback) {
      final creatorId = playback.creatorId;
      ref.listen<AsyncValue<Creator?>>(
        creatorProvider(creatorId),
        (_, next) => _check(creatorId, next),
      );
    }
    return null;
  }

  void _check(String creatorId, AsyncValue<Creator?> next) {
    // 読み直しの途中と、読めなかったときは、決めない（次の読み直しを待つ）。
    if (next is! AsyncData<Creator?>) return;
    final live = next.value?.liveAt(ref.read(clockProvider)());
    if (live == null) {
      end(creatorId);
      return;
    }
    // 発信者ごとの配信中は1つだけなので、配信元が替わると、同じ発信者のまま別の配信になる。
    final playback = ref.read(playbackProvider);
    if (playback is LivePlayback &&
        playback.creatorId == creatorId &&
        playback.live.playbackUrl != live.playbackUrl) {
      ref.read(playbackProvider.notifier).play(creatorId, live);
    }
  }

  /// その発信者の配信が終わったと分かった。その配信を流していたら、知らせてから閉じる。
  /// 流していなければ（ホームの埋め込みだけなど）、何もしない。
  void end(String creatorId) {
    final playback = ref.read(playbackProvider);
    if (playback is! LivePlayback || playback.creatorId != creatorId) return;
    // 先に知らせる。聞く側は、閉じる前の様子（固定ビューアか、ホームの埋め込みビューアか）で、出し方を決める。
    state = LiveEnded(creatorId);
    ref.read(playbackProvider.notifier).endFor(creatorId);
  }
}

final liveEndWatcherProvider = NotifierProvider<LiveEndWatcher, LiveEnded?>(
  LiveEndWatcher.new,
);
