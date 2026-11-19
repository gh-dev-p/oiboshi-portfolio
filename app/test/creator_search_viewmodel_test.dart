import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/ui/onboarding/view_models/choose_oshi_viewmodel.dart';
import 'package:oiboshi/ui/oshi/view_models/creator_search_state.dart';
import 'package:oiboshi/ui/oshi/view_models/find_creators_viewmodel.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  late FakeData data;
  late ProviderContainer container;

  setUp(() async {
    data = FakeData()
      ..creators.add(sampleCreator())
      ..creators.add(const Creator(id: 'aiu', name: 'あいう'));
    container = await testContainer(data);
  });

  /// 画面と同じく、聞き続けて（autoDispose で捨てられないように）、状態を読む。
  CreatorSearchState Function() watch(
    NotifierProvider<CreatorSearchNotifier, CreatorSearchState> provider,
  ) {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    return () => container.read(provider);
  }

  /// 非同期の読み込みが落ち着くまで待つ。
  Future<void> settle([Duration duration = const Duration(milliseconds: 10)]) =>
      Future<void>.delayed(duration);

  List<String> names(CreatorSearchState s) => [
    for (final c in s.creators.requireValue) c.name,
  ];

  test('言葉が空なら、おすすめを出す', () async {
    final state = watch(findCreatorsViewModelProvider);
    expect(state().creators.isLoading, isTrue);
    await settle();
    expect(state().query, '');
    expect(names(state()), ['あいう', '星野ミナト']);
    expect(data.recommendCount, 1);
    expect(data.searches, isEmpty);
  });

  test('打ち終わってからサーバーで探し、前の結果を出したまま待つ', () async {
    final state = watch(findCreatorsViewModelProvider);
    await settle();
    final vm = container.read(findCreatorsViewModelProvider.notifier);
    vm.setQuery('み');
    await settle();
    vm.setQuery('みなと');
    await settle();
    // 待っている間は、問い合わせず、前の一覧を出したまま。
    expect(state().query, 'みなと');
    expect(names(state()), ['あいう', '星野ミナト']);
    expect(data.searches, isEmpty);

    await settle(searchDebounce);
    await settle();
    expect(data.searches, ['みなと']);
    expect(names(state()), ['星野ミナト']);

    // 言葉を消すと、同じおすすめに戻る（選び直さない）。
    container.read(findCreatorsViewModelProvider.notifier).setQuery('');
    await settle();
    expect(names(state()), ['あいう', '星野ミナト']);
    expect(data.recommendCount, 1);
  });

  test('フォローすると、フォロー中の ID に入り、一覧は読み直さない', () async {
    final state = watch(findCreatorsViewModelProvider);
    await settle();
    expect(state().isFollowing('aiu'), isFalse);
    expect(
      await container
          .read(findCreatorsViewModelProvider.notifier)
          .toggleFollow('aiu'),
      isTrue,
    );
    await settle();
    expect(state().isFollowing('aiu'), isTrue);
    expect(names(state()), ['あいう', '星野ミナト']);
    expect(data.recommendCount, 1);
  });

  test('検索の結果は、ユーザーが切り替わると読み直す', () async {
    final state = watch(findCreatorsViewModelProvider);
    await settle();
    container.read(findCreatorsViewModelProvider.notifier).setQuery('あいう');
    await settle(searchDebounce * 2);
    expect(names(state()), ['あいう']);
    expect(data.searches, ['あいう']);

    data.switchSessionUser('user-b');
    await settle(searchDebounce * 2);
    expect(data.searches, ['あいう', 'あいう']);
  });

  test('読めなかったら失敗を持ち、retry で読み直す', () async {
    data.failReads = true;
    final state = watch(findCreatorsViewModelProvider);
    await settle();
    expect(state().creators.hasError, isTrue);

    data.failReads = false;
    container.read(findCreatorsViewModelProvider.notifier).retry();
    await settle();
    expect(state().creators.hasError, isFalse);
    expect(names(state()), ['あいう', '星野ミナト']);
  });

  test('推しを選ぶも同じように動き、推しを探すと状態を共有しない', () async {
    final choose = watch(chooseOshiViewModelProvider);
    final find = watch(findCreatorsViewModelProvider);
    await settle();
    container.read(chooseOshiViewModelProvider.notifier).setQuery('あいう');
    await settle(searchDebounce);
    await settle();
    expect(choose().query, 'あいう');
    expect(names(choose()), ['あいう']);
    expect(find().query, '');
    expect(names(find()), ['あいう', '星野ミナト']);
  });

  test('結果なしのあと続けて打っても、新しい結果が届くまでは、前の言葉の結果のまま', () async {
    final state = watch(findCreatorsViewModelProvider);
    await settle();
    final vm = container.read(findCreatorsViewModelProvider.notifier);
    vm.setQuery('abc');
    await settle(searchDebounce);
    await settle();
    expect(state().noMatch, isTrue);
    expect(state().resultQuery, 'abc');

    vm.setQuery('abcd');
    await settle();
    // まだ探していない「abcd」ではなく、探した「abc」の結果なしとして出す。
    expect(state().query, 'abcd');
    expect(state().resultQuery, 'abc');
    expect(state().noMatch, isTrue);

    vm.setQuery('あいう');
    await settle(searchDebounce);
    await settle();
    expect(state().resultQuery, 'あいう');
    expect(state().noMatch, isFalse);
    expect(names(state()), ['あいう']);
  });

  test('見出し「おすすめ」は、検索の結果が届くまで残し、届いたら消す', () async {
    final state = watch(findCreatorsViewModelProvider);
    await settle();
    expect(state().showsRecommended, isTrue);
    container.read(findCreatorsViewModelProvider.notifier).setQuery('あいう');
    await settle();
    // 結果が届くまでは、おすすめの一覧と見出しのまま。
    expect(state().showsRecommended, isTrue);
    expect(names(state()), ['あいう', '星野ミナト']);
    await settle(searchDebounce);
    await settle();
    expect(state().showsRecommended, isFalse);
    expect(names(state()), ['あいう']);
  });

  test('おすすめが0人なら、見出しも結果なしも出さない', () async {
    data.creators.clear();
    final state = watch(findCreatorsViewModelProvider);
    await settle();
    expect(state().creators.requireValue, isEmpty);
    expect(state().showsRecommended, isFalse);
    expect(state().noMatch, isFalse);
  });
}
