import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/core/view_models/post_shuffle_provider.dart';

import 'fakes.dart';

void main() {
  test('流している投稿の動画だけ、続きの位置を変える', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final playback = container.read(playbackProvider.notifier);
    final post = samplePost();
    playback.playPost(post, null, Duration.zero, canOpenAuthor: true);

    playback.seek(post.id, const Duration(seconds: 42));
    final moved = container.read(playbackProvider)! as PostPlayback;
    expect(moved.start, const Duration(seconds: 42));
    expect(moved.canOpenAuthor, isTrue);

    // ほかの投稿なら、何もしない。
    playback.seek('yt:other', const Duration(seconds: 7));
    expect(
      (container.read(playbackProvider)! as PostPlayback).start,
      const Duration(seconds: 42),
    );
  });

  group('ランダム再生から配信に切り替えて戻す', () {
    late ProviderContainer container;
    late PlaybackNotifier playback;
    late PostShuffle order;
    final videos = [
      for (var i = 0; i < 6; i++)
        samplePost(id: 'yt:$i', creatorId: i.isEven ? 'minato' : 'sora'),
    ];

    setUp(() {
      container = ProviderContainer();
      playback = container.read(playbackProvider.notifier);
      order = PostShuffle(videos, random: Random(1));
      // 固定ビューアと同じく、流すものが替わったら、止めていたのをやめる。
      container.listen(playbackProvider, (previous, next) {
        final key = next is PostPlayback ? next.post.id : next.runtimeType;
        final before = previous is PostPlayback
            ? previous.post.id
            : previous.runtimeType;
        if (key != before) {
          container.read(fixedViewerPausedProvider.notifier).set(false);
        }
      });
    });
    tearDown(() => container.dispose());

    PostPlayback current() => container.read(playbackProvider)! as PostPlayback;

    test('同じ順番の同じ動画を、切り替える直前の位置から続ける', () {
      playback.playShuffle(order, const {});
      playback.stepShuffle(1);
      final before = current();
      playback.seek(before.post.id, const Duration(seconds: 30));

      playback.play('minato', sampleLive());
      // 固定ビューアが、切り替える直前の位置を知らせる。
      playback.updateSuspended(
        before.post.id,
        position: const Duration(seconds: 75),
        paused: false,
      );
      expect(container.read(playbackProvider), isA<LivePlayback>());
      // 配信の間に、配信を切り替えても忘れない。
      playback.play('sora', sampleLive());

      expect(playback.resumeSuspendedShuffle(), isTrue);
      final after = current();
      expect(after.post.id, before.post.id);
      expect(after.start, const Duration(seconds: 75));
      expect(identical(after.shuffle, before.shuffle), isTrue);
      expect(container.read(fixedViewerPausedProvider), isFalse);
      // 前の動画にも戻れる（シャッフルし直していない）。
      expect(after.shuffle!.order.hasPrevious, isTrue);
      playback.stepShuffle(-1);
      expect(current().post.id, after.shuffle!.order.current!.id);
      // 戻したら、控えたものは忘れる。
      expect(playback.suspendedShuffle, isNull);
    });

    test('止めていたら、止めたまま戻す', () {
      playback.playShuffle(order, const {});
      final before = current();
      container.read(fixedViewerPausedProvider.notifier).set(true);

      playback.play('minato', sampleLive());
      expect(container.read(fixedViewerPausedProvider), isFalse);

      expect(playback.resumeSuspendedShuffle(), isTrue);
      expect(current().post.id, before.post.id);
      expect(container.read(fixedViewerPausedProvider), isTrue);
    });

    test('プレイヤーで一時停止していたら、止めたまま戻す', () {
      playback.playShuffle(order, const {});
      final before = current();
      playback.play('minato', sampleLive());
      playback.updateSuspended(
        before.post.id,
        position: const Duration(seconds: 12),
        paused: true,
      );

      expect(playback.resumeSuspendedShuffle(), isTrue);
      expect(current().start, const Duration(seconds: 12));
      expect(container.read(fixedViewerPausedProvider), isTrue);
    });

    test('流せなくなった動画なら戻さず、控えたものを捨てる', () {
      playback.playShuffle(order, const {});
      playback.play('minato', sampleLive());

      expect(playback.resumeSuspendedShuffle(canPlay: (_) => false), isFalse);
      expect(container.read(playbackProvider), isA<LivePlayback>());
      expect(playback.suspendedShuffle, isNull);
    });

    test('追星から消した動画なら、控えたものを捨てる', () {
      playback.playShuffle(order, const {});
      final before = current();
      playback.play('minato', sampleLive());

      playback.endPost(before.post.id);
      expect(playback.resumeSuspendedShuffle(), isFalse);
    });

    test('ランダム再生でない動画からの切り替えは、控えない', () {
      playback.playPost(samplePost(), null, Duration.zero);
      playback.play('minato', sampleLive());
      expect(playback.suspendedShuffle, isNull);
    });
  });
}
