import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/ui/oshi/view_models/oshi_list_viewmodel.dart';
import 'package:oiboshi/ui/oshi/view_models/oshi_providers.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  late FakeData data;
  late ProviderContainer container;

  setUp(() async {
    data = FakeData()
      ..creators.add(sampleCreator())
      ..creators.add(
        Creator(
          id: 'aiu',
          name: 'あいう',
          live: sampleLive(link: 'https://twitcasting.tv/aiu'),
        ),
      )
      ..follows.add(sampleFollow())
      ..follows.add(sampleFollow('aiu'));
    container = await testContainer(data);
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));

  OshiListState state() => container.read(oshiListViewModelProvider);

  List<String> names(List<OshiListEntry> entries) => [
    for (final e in entries) e.oshi.creator.name,
  ];

  test('配信中の推しを先に並べ、検索の言葉で絞り込む', () async {
    expect(state().entries.isLoading, isTrue);
    await settle();
    expect(names(state().entries.requireValue), ['あいう', '星野ミナト']);
    expect(state().entries.requireValue.first.live?.title, '朝の雑談');

    container.read(oshiListViewModelProvider.notifier).setQuery('みなと');
    expect(state().query, 'みなと');
    expect(names(state().filtered), ['星野ミナト']);
    // 絞り込みは手元で行い、全員の一覧はそのまま。
    expect(names(state().entries.requireValue), ['あいう', '星野ミナト']);
  });

  test('読み直しても、検索の言葉は残る', () async {
    await settle();
    final vm = container.read(oshiListViewModelProvider.notifier);
    vm.setQuery('あ');
    data.follows.removeWhere((f) => f.creatorId == 'minato');
    await vm.refresh();
    expect(state().query, 'あ');
    expect(names(state().entries.requireValue), ['あいう']);
  });

  test('検索に合う推しがいなければ結果なしとし、推しが0人なら空とする', () async {
    // 読み込み中は、どちらでもない。
    expect(state().empty, isFalse);
    expect(state().noMatch, isFalse);
    await settle();
    final vm = container.read(oshiListViewModelProvider.notifier);
    expect(state().empty, isFalse);
    expect(state().noMatch, isFalse);

    vm.setQuery('いない人');
    expect(state().noMatch, isTrue);
    vm.setQuery('  ');
    expect(state().noMatch, isFalse);

    data.follows.clear();
    await vm.refresh();
    expect(state().empty, isTrue);
    // 0人のときは、言葉があっても、結果なしではなく空として出す。
    vm.setQuery('いない人');
    expect(state().noMatch, isFalse);
  });

  test('読めなかったら失敗を持ち、refresh は例外を外に出さない', () async {
    data.failReads = true;
    container.read(oshiListViewModelProvider);
    await settle();
    expect(state().entries.hasError, isTrue);
    await container.read(oshiListViewModelProvider.notifier).refresh();
    expect(state().entries.hasError, isTrue);

    data.failReads = false;
    await container.read(oshiListViewModelProvider.notifier).refresh();
    expect(state().entries.hasValue, isTrue);
  });

  test('フォローを続けて押しても、2回送らない。送り終われば、また押せる', () async {
    await settle();
    final actions = container.read(followActionsProvider.notifier);
    int count() => data.follows.where((f) => f.creatorId == 'new').length;
    final results = await Future.wait([
      actions.toggle('new'),
      actions.toggle('new'),
    ]);
    // 2回目は送らないので、失敗のスナックバーも出さない。
    expect(results, [true, true]);
    expect(count(), 1);

    expect(await actions.toggle('new'), isTrue);
    expect(count(), 0);
  });
}
