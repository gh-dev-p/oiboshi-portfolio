import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/view_models/removed_posts_provider.dart';
import 'package:oiboshi/ui/home/view_models/home_viewmodel.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  late FakeData data;
  late ProviderContainer container;
  final base = DateTime.now().subtract(const Duration(hours: 1));

  /// [creatorId] の投稿を [count] 件、[from] から1分ずつ古くして足す。
  void addPosts(
    String creatorId,
    int count, {
    String prefix = 'p',
    DateTime? from,
  }) {
    final start = from ?? base;
    for (var i = 0; i < count; i++) {
      data.posts.add(
        samplePost(
          id: '$prefix:${i.toString().padLeft(3, '0')}',
          creatorId: creatorId,
          text: '$prefix$i',
          postedAt: start.subtract(Duration(minutes: i)),
          permalink: 'https://example.com/$prefix/$i',
        ),
      );
    }
  }

  setUp(() async {
    data = FakeData()
      ..creators.addAll([
        sampleCreator(),
        const Creator(id: 'sora', name: '天野ソラ'),
      ])
      ..follows.add(
        Follow(
          creatorId: 'minato',
          followedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
    container = await testContainer(data);
  });

  /// 画面が開いているのと同じく、聞き続けて、読み込みを待つ。
  Future<HomeViewModel> open() async {
    final sub = container.listen(homeViewModelProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(homeViewModelProvider.future);
    return container.read(homeViewModelProvider.notifier);
  }

  HomeState state() => container.read(homeViewModelProvider).requireValue;

  test('追星から消した投稿は、続きで読んだ投稿からも外す', () async {
    addPosts('minato', 60);
    final vm = await open();
    await vm.loadMore();
    expect([for (final p in state().posts) p.id], contains('p:055'));

    data.posts.removeWhere((p) => p.id == 'p:055');
    container.read(removedPostsProvider.notifier).add('p:055');
    await container.read(homeViewModelProvider.future);
    final ids = [for (final p in state().posts) p.id];
    expect(ids, isNot(contains('p:055')));
    expect(ids, hasLength(59));
    expect(vm, same(container.read(homeViewModelProvider.notifier)));
  });

  test('続きで読んだ投稿は、読み直しても残る', () async {
    addPosts('minato', 120);
    final vm = await open();
    expect(state().posts, hasLength(50));
    await vm.loadMore();
    expect(state().posts, hasLength(100));
    expect(state().exhausted, isFalse);

    await vm.refresh();
    expect(state().posts, hasLength(100));
    expect(state().exhausted, isFalse);
    await vm.loadMore();
    expect(state().posts, hasLength(120));
    expect(state().exhausted, isTrue);
  });

  test('最後まで読んだあとに推しを足すと、終端を決め直し、足した推しの続きを読める', () async {
    addPosts('minato', 60);
    final vm = await open();
    await vm.loadMore();
    expect(state().posts, hasLength(60));
    expect(state().exhausted, isTrue);

    addPosts(
      'sora',
      60,
      prefix: 's',
      from: base.add(const Duration(seconds: 30)),
    );
    data.follows.add(sampleFollow('sora'));
    await vm.refresh();
    expect(state().posts, hasLength(50));
    expect(state().exhausted, isFalse);
    await vm.loadMore();
    await vm.loadMore();
    await vm.loadMore();
    expect(state().posts, hasLength(120));
    expect(state().exhausted, isTrue);
  });

  test('読み直しのあいだに 50 件を超えて増えたら、続きを捨てて、最新の 50 件から出し直す', () async {
    addPosts('minato', 60);
    final vm = await open();
    await vm.loadMore();
    expect(state().exhausted, isTrue);

    // 前に読んだ投稿より新しい投稿が 55 件（間に 5 件、読んでいない投稿がある）。
    addPosts('minato', 55, prefix: 'n', from: DateTime.now());
    await vm.refresh();
    expect(state().posts, hasLength(50));
    expect(state().posts.first.id, 'n:000');
    expect(state().exhausted, isFalse);

    // 続きは、出し直した最後の投稿の次から読み、間をあけない。
    await vm.loadMore();
    await vm.loadMore();
    expect(state().posts, hasLength(115));
    expect(state().exhausted, isTrue);
  });

  test('つながっている読み直しでは、新しい投稿を足し、消えた投稿を除く', () async {
    addPosts('minato', 60);
    final vm = await open();
    await vm.loadMore();

    addPosts('minato', 3, prefix: 'n', from: DateTime.now());
    data.posts.removeWhere((p) => p.id == 'p:001');
    await vm.refresh();
    final ids = [for (final p in state().posts) p.id];
    expect(ids.take(3), ['n:000', 'n:001', 'n:002']);
    expect(ids, isNot(contains('p:001')));
    expect(ids, hasLength(62));
    expect(state().exhausted, isTrue);
  });

  test('ページの境目で同じ時刻の投稿を、取りこぼさない', () async {
    // 45 件目から 10 件が同じ時刻（ページの境目の 50 件目をまたぐ）。
    for (var i = 0; i < 60; i++) {
      final minutes = i < 45 ? i : (i < 55 ? 45 : i);
      data.posts.add(
        samplePost(
          id: 'p:${i.toString().padLeft(3, '0')}',
          text: 'p$i',
          postedAt: base.subtract(Duration(minutes: minutes)),
        ),
      );
    }
    final vm = await open();
    expect(state().posts, hasLength(50));
    await vm.loadMore();
    expect(state().posts, hasLength(60));
    expect({for (final p in state().posts) p.id}, hasLength(60));
    // 続きは、読み込んだいちばん古い投稿の次から読む。
    expect(data.timelineReads.last?.id, state().posts[49].id);
  });

  /// これからの予定を [schedules] 件、これからのイベントを [events] 件、足す。
  void addSchedules({required int schedules, required int events}) {
    final now = DateTime.now();
    for (var i = 0; i < schedules; i++) {
      data.schedules.add(
        sampleSchedule(
          's$i',
          '配信$i',
          laterToday(i + 1, of: schedules),
          service: SnsService.youtube,
        ),
      );
    }
    for (var i = 0; i < events; i++) {
      data.schedules.add(
        sampleSchedule('e$i', 'ライブ$i', now.add(Duration(days: i + 1))),
      );
    }
  }

  test('「次の予定」「イベント」は2件まで出し、残りの件数を持つ', () async {
    addSchedules(schedules: 5, events: 4);
    await open();
    expect(state().upcoming, hasLength(2));
    expect(state().upcomingMore, 3);
    expect(state().events, hasLength(2));
    expect(state().eventsMore, 2);
  });

  test('2件以下なら、残りの件数は0', () async {
    addSchedules(schedules: 2, events: 2);
    await open();
    expect(state().upcoming, hasLength(2));
    expect(state().upcomingMore, 0);
    expect(state().events, hasLength(2));
    expect(state().eventsMore, 0);
  });

  test('「次の予定」は本日中の予定だけを出し、明日より先の予定は数えない', () async {
    final now = DateTime.now();
    data.schedules.addAll([
      sampleSchedule(
        'today',
        '今日の配信',
        laterToday(1),
        service: SnsService.youtube,
      ),
      sampleSchedule(
        'tomorrow',
        '明日の配信',
        DateTime(now.year, now.month, now.day + 1, 12),
        service: SnsService.youtube,
      ),
    ]);
    await open();
    expect(state().upcoming.map((s) => s.id), ['today']);
    expect(state().upcomingMore, 0);
  });
}
