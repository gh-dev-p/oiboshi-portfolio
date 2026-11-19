import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/core/view_models/removed_posts_provider.dart';
import 'package:oiboshi/ui/creator_admin/view_models/post_manage_viewmodel.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  final posts = [samplePost(id: 'yt:1'), samplePost(id: 'yt:2')];
  late FakeData data;
  late ProviderContainer container;

  setUp(() async {
    data = FakeData()
      ..creators.add(sampleCreator())
      ..posts.addAll(posts)
      ..ownedCreatorId = 'minato';
    container = await testContainer(data);
  });

  Future<PostManageViewModel> open() async {
    final provider = postManageViewModelProvider('minato');
    final loaded = Completer<void>();
    final sub = container.listen(provider, (_, state) {
      if (state.posts.hasValue && !loaded.isCompleted) loaded.complete();
    }, fireImmediately: true);
    addTearDown(sub.close);
    await loaded.future;
    return container.read(provider.notifier);
  }

  PostManageState read() =>
      container.read(postManageViewModelProvider('minato'));

  test('自分の投稿を、新しい順に並べる', () async {
    await open();
    final listed = read().posts.value!;
    expect({for (final p in listed) p.creatorId}, {'minato'});
    expect(listed, hasLength(2));
  });

  test('隠した投稿も、一覧に残し、隠している印を付ける', () async {
    data.hiddenPostIds.add('yt:2');
    await open();
    expect([
      for (final p in read().posts.value!) p.id,
    ], unorderedEquals(['yt:1', 'yt:2']));
    expect(read().hiddenIds, {'yt:2'});
  });

  test('隠すと、一覧には残して印を付け、投稿を出している画面に知らせる', () async {
    final vm = await open();
    expect(await vm.setHidden(posts[1], hidden: true), isTrue);
    expect(data.hiddenPostIds, {'yt:2'});
    expect(data.posts, hasLength(2));
    expect(container.read(removedPostsProvider), {'yt:2'});
    expect([for (final p in read().posts.value!) p.id], contains('yt:2'));
    expect(read().hiddenIds, {'yt:2'});
  });

  test('また出すと、印を外し、投稿を出している画面に知らせる', () async {
    data.hiddenPostIds.add('yt:2');
    final vm = await open();
    final before = container.read(removedPostsProvider);
    expect(await vm.setHidden(posts[1], hidden: false), isTrue);
    expect(data.hiddenPostIds, isEmpty);
    expect(read().hiddenIds, isEmpty);
    // 前の起動で隠した投稿でも、聞いている画面が読み直すよう、知らせる。
    expect(identical(container.read(removedPostsProvider), before), isFalse);
  });

  test('隠した投稿を小窓で流していたら、小窓を閉じる', () async {
    final vm = await open();
    container
        .read(playbackProvider.notifier)
        .playPost(posts[0], null, Duration.zero);
    expect(await vm.setHidden(posts[0], hidden: true), isTrue);
    expect(container.read(playbackProvider), isNull);
  });

  test('隠せなかったら、印を付けず、画面にも知らせない', () async {
    data.hidePostFails = true;
    final vm = await open();
    expect(await vm.setHidden(posts[0], hidden: true), isFalse);
    expect(data.hiddenPostIds, isEmpty);
    expect(read().hiddenIds, isEmpty);
    expect(container.read(removedPostsProvider), isEmpty);
  });
}
