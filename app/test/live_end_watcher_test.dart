import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/view_models/clock_provider.dart';
import 'package:oiboshi/ui/creator/view_models/creator_providers.dart';
import 'package:oiboshi/ui/creator/view_models/creator_viewmodel.dart';
import 'package:oiboshi/ui/oshi/view_models/oshi_providers.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  late FakeData data;
  late ProviderContainer container;
  late List<LiveEnded> ended;

  setUp(() async {
    data = FakeData()..creators.add(sampleCreator(live: sampleLive()));
    container = await testContainer(data);
    ended = [];
    // 画面（小窓の層）と同じく、聞き続ける。
    final sub = container.listen(liveEndWatcherProvider, (_, next) {
      if (next != null) ended.add(next);
    });
    addTearDown(sub.close);
  });

  /// 1分ごとの読み直しと同じく、発信者を読み直して、届くのを待つ。
  Future<void> reloadCreator() async {
    container.invalidate(creatorProvider('minato'));
    await container.read(creatorProvider('minato').future);
    await Future<void>.delayed(Duration.zero);
  }

  test('発信者ページを閉じたあとも、配信が終わったと分かったら、小窓を閉じて知らせる', () async {
    container.read(playbackProvider.notifier).play('minato', sampleLive());
    // 発信者ページが開いていなくても、発信者を読む。
    await container.read(creatorProvider('minato').future);

    // 配信中のあいだは、閉じない。
    await reloadCreator();
    expect(container.read(playbackProvider), isA<LivePlayback>());
    expect(ended, isEmpty);

    data.creators[0] = sampleCreator();
    await reloadCreator();
    expect(container.read(playbackProvider), isNull);
    expect(ended.map((e) => e.creatorId), ['minato']);
  });

  test('読み直しに失敗しても、閉じない', () async {
    container.read(playbackProvider.notifier).play('minato', sampleLive());
    await container.read(creatorProvider('minato').future);
    data
      ..creators[0] = sampleCreator()
      ..failReads = true;
    container.invalidate(creatorProvider('minato'));
    await expectLater(
      container.read(creatorProvider('minato').future),
      throwsA(anything),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(playbackProvider), isA<LivePlayback>());
    expect(ended, isEmpty);
  });

  test('投稿の動画の小窓は、閉じない', () async {
    container
        .read(playbackProvider.notifier)
        .playPost(samplePost(), sampleCreator(), Duration.zero);
    data.creators[0] = sampleCreator();
    await reloadCreator();
    expect(container.read(playbackProvider), isA<PostPlayback>());
    expect(ended, isEmpty);
  });

  test('別の配信に切り替えたあとは、前の発信者の配信の終わりで閉じない', () async {
    data.creators.add(
      Creator(
        id: 'other',
        name: 'ほか',
        live: sampleLive(),
        linkedAccounts: const {},
      ),
    );
    container.read(playbackProvider.notifier).play('minato', sampleLive());
    await container.read(creatorProvider('minato').future);
    container.read(playbackProvider.notifier).play('other', sampleLive());
    await container.read(creatorProvider('other').future);

    data.creators[0] = sampleCreator();
    await reloadCreator();
    final playback = container.read(playbackProvider);
    expect(playback, isA<LivePlayback>());
    expect((playback as LivePlayback).creatorId, 'other');
    expect(ended, isEmpty);
  });

  test('発信者ページが先に終わりに気づいても、知らせてから閉じる', () async {
    container.read(playbackProvider.notifier).play('minato', sampleLive());
    container.read(creatorViewModelProvider('minato').notifier).endLive();
    expect(container.read(playbackProvider), isNull);
    expect(ended.map((e) => e.creatorId), ['minato']);

    // 流していない配信の終わりでは、知らせない（ホームの埋め込みだけのとき）。
    container.read(creatorViewModelProvider('minato').notifier).endLive();
    expect(ended, hasLength(1));
  });

  test('配信の確認の時刻が時計より古くなったら、終わったとみなす', () async {
    final later = DateTime.now().add(const Duration(minutes: 10));
    final clocked = await testContainer(
      data,
      overrides: [clockProvider.overrideWithValue(() => later)],
    );
    final sub = clocked.listen(liveEndWatcherProvider, (_, _) {});
    addTearDown(sub.close);
    clocked.read(playbackProvider.notifier).play('minato', sampleLive());
    await clocked.read(creatorProvider('minato').future);
    await Future<void>.delayed(Duration.zero);

    data.creators[0] = sampleCreator(
      live: sampleLive(checkedAt: DateTime.now()),
    );
    clocked.invalidate(creatorProvider('minato'));
    await clocked.read(creatorProvider('minato').future);
    await Future<void>.delayed(Duration.zero);
    expect(clocked.read(playbackProvider), isNull);
  });

  test('同じ発信者のまま配信元が替わったら、新しい配信で流し直す', () async {
    container.read(playbackProvider.notifier).play('minato', sampleLive());
    await container.read(creatorProvider('minato').future);
    // 同じ配信のあいだは、流し直さない。
    final before = container.read(playbackProvider);
    await reloadCreator();
    expect(container.read(playbackProvider), same(before));

    // ツイキャスが終わり、YouTube の配信が続いている（発信者ごとに配信中は1つ）。
    data.creators[0] = sampleCreator(
      live: sampleLive(
        service: SnsService.youtube,
        playbackUrl: 'https://www.youtube.com/embed/live',
      ),
    );
    await reloadCreator();
    final playback = container.read(playbackProvider);
    expect(playback, isA<LivePlayback>());
    expect(
      (playback! as LivePlayback).live.playbackUrl,
      'https://www.youtube.com/embed/live',
    );
    expect(ended, isEmpty);
  });
}
