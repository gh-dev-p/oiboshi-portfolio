import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/service_providers.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/creator/view_models/creator_viewmodel.dart';
import 'package:oiboshi/ui/oshi/view_models/find_creators_viewmodel.dart';
import 'package:oiboshi/ui/oshi/view_models/oshi_providers.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  late FakeData data;
  late FakeImagePickerService picker;
  late ProviderContainer container;

  setUp(() async {
    data = FakeData()..creators.add(sampleCreator());
    picker = FakeImagePickerService();
    container = await testContainer(
      data,
      overrides: [imagePickerServiceProvider.overrideWithValue(picker)],
    );
  });

  /// 画面が開いているのと同じく、聞き続けて、読み込みを待つ。
  Future<CreatorViewModel> open() async {
    final provider = creatorViewModelProvider('minato');
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future);
    return container.read(provider.notifier);
  }

  test('写真を選ばなければ、カバーを変えない', () async {
    data.follows.add(sampleFollow());
    final vm = await open();
    expect(await vm.pickAndSetCover(), CoverChangeResult.cancelled);
    expect(picker.picks, 1);
    expect(data.follows.first.coverUrl, isNull);
  });

  test('写真を選ぶと、縮めたバイト列でカバーを変え、フォローを読み直す', () async {
    data.follows.add(sampleFollow());
    picker.picked = Uint8List(3);
    final vm = await open();
    expect(await vm.pickAndSetCover(), CoverChangeResult.changed);
    expect(data.follows.first.coverUrl, 'memory://minato/3');
    final follows = await container.read(followsProvider.future);
    expect(follows.first.coverUrl, 'memory://minato/3');
  });

  test('保存に失敗したら、失敗と返す', () async {
    // フォローしていない発信者のカバーは、保存できない。
    picker.picked = Uint8List(3);
    final vm = await open();
    expect(await vm.pickAndSetCover(), CoverChangeResult.failed);
  });

  test('写真を選ぶと、表を出していても、裏（自分の写真）を出す', () async {
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now(),
        coverUrl: 'memory://old',
        showOwnCover: false,
      ),
    );
    picker.picked = Uint8List(3);
    final vm = await open();
    expect(await vm.pickAndSetCover(), CoverChangeResult.changed);
    expect(data.follows.first.showOwnCover, isTrue);
    final provider = creatorViewModelProvider('minato');
    await container.read(followsProvider.future);
    final state = await container.read(provider.future);
    expect(state.showingOwnCover, isTrue);
    expect(state.coverUrl, 'memory://minato/3');
  });

  test('自分の写真があれば、裏返すと表と裏を切り替え、どちらを出すかを覚える', () async {
    data.creators[0] = sampleCreator().copyWith(
      coverUrl: 'https://x/creator.jpg',
    );
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now(),
        coverUrl: 'memory://own',
      ),
    );
    final vm = await open();
    final provider = creatorViewModelProvider('minato');
    await container.read(followsProvider.future);
    var state = await container.read(provider.future);
    expect(state.hasOwnCover, isTrue);
    expect(state.coverUrl, 'memory://own');

    // 押すと、保存を待たずに表に切り替える。
    final saving = vm.flipCover();
    state = container.read(provider).requireValue;
    expect(state.showingOwnCover, isFalse);
    expect(state.coverUrl, 'https://x/creator.jpg');
    await saving;
    expect(data.follows.first.showOwnCover, isFalse);

    // フォローを読み直しても、表のまま。
    await container.read(followsProvider.future);
    state = await container.read(provider.future);
    expect(state.showingOwnCover, isFalse);

    await vm.flipCover();
    expect(data.follows.first.showOwnCover, isTrue);
    expect(container.read(provider).requireValue.coverUrl, 'memory://own');
  });

  test('覚えた面は、ページを開き直しても出す', () async {
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now(),
        coverUrl: 'memory://own',
        showOwnCover: false,
      ),
    );
    await open();
    await container.read(followsProvider.future);
    final state = await container.read(
      creatorViewModelProvider('minato').future,
    );
    expect(state.hasOwnCover, isTrue);
    expect(state.showingOwnCover, isFalse);
  });

  test('自分の写真がなければ、裏返さない', () async {
    data.follows.add(sampleFollow());
    final vm = await open();
    await container.read(followsProvider.future);
    await vm.flipCover();
    expect(data.follows.first.showOwnCover, isTrue);
    expect(
      container
          .read(creatorViewModelProvider('minato'))
          .requireValue
          .hasOwnCover,
      isFalse,
    );
  });

  test('推しが設定したカバーに戻すと、自分の写真を消す', () async {
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now(),
        coverUrl: 'memory://own',
      ),
    );
    final vm = await open();
    await container.read(followsProvider.future);
    expect(await vm.resetCover(), CoverChangeResult.changed);
    expect(data.follows.first.coverUrl, isNull);
    expect(data.removedCovers, ['minato']);
    final state = container
        .read(creatorViewModelProvider('minato'))
        .requireValue;
    expect(state.hasOwnCover, isFalse);
    expect(state.coverUrl, isNull);
  });

  test('カバーに戻せなかったら、失敗と返す', () async {
    // フォローしていない発信者のカバーは、戻せない。
    final vm = await open();
    expect(await vm.resetCover(), CoverChangeResult.failed);
  });

  test('フォローを外すと、自分の写真も消す', () async {
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now(),
        coverUrl: 'memory://own',
      ),
    );
    final vm = await open();
    await container.read(followsProvider.future);
    expect(await vm.toggleFollow(), isTrue);
    expect(data.follows, isEmpty);
    expect(data.removedCovers, ['minato']);
  });

  test('配信が終わったら、その発信者の小窓を閉じる', () async {
    final live = sampleLive(startedAt: DateTime.now());
    final vm = await open();
    container.read(playbackProvider.notifier).play('other', live);
    vm.endLive();
    expect(container.read(playbackProvider), isA<LivePlayback>());

    container.read(playbackProvider.notifier).play('minato', live);
    vm.endLive();
    expect(container.read(playbackProvider), isNull);
  });
  test('1分ごとの読み直しのあとも、新着の区切りを残し、既読の印は開いたときの1回だけ', () async {
    final seen = DateTime.now().subtract(const Duration(hours: 2));
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: seen.subtract(const Duration(days: 1)),
        lastSeenAt: seen,
      ),
    );
    data.posts.addAll([
      samplePost(id: 'yt:new', postedAt: seen.add(const Duration(hours: 1))),
      samplePost(
        id: 'yt:old',
        postedAt: seen.subtract(const Duration(hours: 1)),
      ),
    ]);
    await open();
    final provider = creatorViewModelProvider('minato');
    // フォローが届いて、作り直すのを待つ。
    await container.read(followsProvider.future);
    await container.read(provider.future);
    expect(container.read(provider).requireValue.seenBefore, seen);
    final marked = data.follows.first.lastSeenAt;
    expect(marked, isNot(seen));

    // 1分ごとの読み直しと同じく、投稿とフォローを読み直す。
    container.invalidate(creatorPostsProvider('minato'));
    container.invalidate(followsProvider);
    await container.read(provider.future);
    final state = container.read(provider).requireValue;
    expect(state.seenBefore, seen);
    expect(state.newDividerIndexAt(DateTime.now()), 0);
    expect(data.follows.first.lastSeenAt, marked);
  });

  test('開いたら、読み直しを待たずに、手元のフォローも既読にし、推しの「NEW」をその場で消す', () async {
    final seen = DateTime.now().subtract(const Duration(hours: 2));
    data.creators[0] = sampleCreator(
      latestPostAt: seen.add(const Duration(hours: 1)),
    );
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: seen.subtract(const Duration(days: 1)),
        lastSeenAt: seen,
      ),
    );
    final oshis = container.listen(oshisProvider, (_, _) {});
    addTearDown(oshis.close);
    final before = await container.read(oshisProvider.future);
    expect(before.single.hasNewAt(DateTime.now()), isTrue);

    await open();
    // 組み立てのあとで、手元のフォローを書き換える。
    await Future<void>.delayed(Duration.zero);
    // 読み直し（1分ごと）は待たない。
    final after = await container.read(oshisProvider.future);
    expect(after.single.hasNewAt(DateTime.now()), isFalse);
    // 区切りは、開く前の時刻のまま。
    expect(
      container
          .read(creatorViewModelProvider('minato'))
          .requireValue
          .seenBefore,
      seen,
    );
  });

  test('表示しないにすると、先に足してからフォローを外す', () async {
    data.follows.add(sampleFollow());
    final vm = await open();
    await container.read(followsProvider.future);
    expect(await vm.hide(), isTrue);
    expect(data.hiddenCreatorIds, ['minato']);
    expect(data.follows, isEmpty);
    expect(data.removedCovers, ['minato']);
  });

  test('表示しないに足せなければ、フォローもカバー画像も外さない', () async {
    data
      ..follows.add(sampleFollow())
      ..hiddenWriteFails = true;
    final vm = await open();
    await container.read(followsProvider.future);
    expect(await vm.hide(), isFalse);
    expect(data.hiddenCreatorIds, isEmpty);
    expect(data.follows, hasLength(1));
    expect(data.removedCovers, isEmpty);
  });

  test('足したあと、フォローを外せなくても、表示しないにはできている', () async {
    data
      ..follows.add(sampleFollow())
      ..unfollowFails = true;
    final vm = await open();
    await container.read(followsProvider.future);
    expect(await vm.hide(), isTrue);
    expect(data.hiddenCreatorIds, ['minato']);
    expect(data.follows, hasLength(1));
  });

  test('表示しないにすると、推しを探すのおすすめからも消え、選び直さない', () async {
    data.creators.add(const Creator(id: 'aiu', name: 'あいう'));
    final find = container.listen(findCreatorsViewModelProvider, (_, _) {});
    addTearDown(find.close);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    List<String> ids() => [
      for (final c in find.read().creators.requireValue) c.id,
    ];
    expect(ids(), ['aiu', 'minato']);

    final vm = await open();
    expect(await vm.hide(), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(ids(), ['aiu']);
    expect(data.recommendCount, 1);
  });
}
