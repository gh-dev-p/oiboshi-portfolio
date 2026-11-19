import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/provider_retry.dart';
import 'package:oiboshi/config/service_providers.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/schedule_filter.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/schedule/view_models/month_calendar_viewmodel.dart';
import 'package:oiboshi/ui/schedule/view_models/time_schedule_viewmodel.dart';
import 'package:oiboshi/utils/formatters.dart';

import 'fakes.dart';

void main() {
  late FakeData data;
  late ProviderContainer container;
  final now = DateTime.now();
  final today = dateOnly(now);
  final tomorrow = today.add(const Duration(days: 1));

  ScheduleItem item(
    String id,
    DateTime startsAt, {
    SnsService? service = SnsService.youtube,
    String creatorId = 'minato',
  }) => sampleSchedule(
    id,
    id,
    startsAt,
    creatorId: creatorId,
    endsAt: startsAt.add(const Duration(hours: 1)),
    service: service,
  );

  setUp(() {
    data = FakeData()
      ..creators.add(sampleCreator())
      ..follows.add(Follow(creatorId: 'minato', followedAt: now));
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(data)),
        creatorRepositoryProvider.overrideWithValue(
          FakeCreatorRepository(data),
        ),
        followRepositoryProvider.overrideWithValue(FakeFollowRepository(data)),
        postRepositoryProvider.overrideWithValue(FakePostRepository(data)),
        scheduleRepositoryProvider.overrideWithValue(
          FakeScheduleRepository(data),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  /// 読み込みが終わる（読み込み中でなくなる）のを待つ。
  Future<AsyncValue<T>> settled<T>(
    ProviderSubscription<Object?> Function(void Function() onChange) listen,
    AsyncValue<T> Function() read,
  ) {
    final completer = Completer<AsyncValue<T>>();
    void check() {
      final d = read();
      if (!d.isLoading && !completer.isCompleted) completer.complete(d);
    }

    final sub = listen(check);
    check();
    return completer.future.whenComplete(sub.close);
  }

  group('タイムスケジュール', () {
    Future<AsyncValue<TimeScheduleData>> settledData() => settled(
      (onChange) =>
          container.listen(timeScheduleViewModelProvider, (_, _) => onChange()),
      () => container.read(timeScheduleViewModelProvider).result,
    );
    TimeScheduleViewModel vm() =>
        container.read(timeScheduleViewModelProvider.notifier);

    test('今日を選んで始め、その日に重なる予定と投稿を出す', () async {
      data.schedules.add(item('today', today.add(const Duration(hours: 10))));
      data.schedules.add(
        item('tomorrow', tomorrow.add(const Duration(hours: 10))),
      );
      data.posts.add(samplePost(postedAt: today.add(const Duration(hours: 9))));
      expect(container.read(timeScheduleViewModelProvider).day, today);
      final d = (await settledData()).requireValue;
      expect(d.day, today);
      expect([for (final s in d.schedules) s.id], ['today']);
      expect(d.posts, hasLength(1));
      expect(d.allOshis, hasLength(1));
    });

    test('日を切り替えると、読み込むあいだは前の日のデータを保ち、読めたら入れ替える', () async {
      data.schedules.add(item('today', today.add(const Duration(hours: 10))));
      data.schedules.add(
        item('tomorrow', tomorrow.add(const Duration(hours: 10))),
      );
      await settledData();
      vm().selectDay(tomorrow);
      final during = container.read(timeScheduleViewModelProvider);
      expect(during.day, tomorrow);
      expect(during.result.isLoading, isTrue);
      expect(during.data!.day, today);
      final d = (await settledData()).requireValue;
      expect(d.day, tomorrow);
      expect([for (final s in d.schedules) s.id], ['tomorrow']);
    });

    test('絞り込みで、推し・プラットフォーム・種類を絞る', () async {
      data.schedules.add(item('yt', today.add(const Duration(hours: 10))));
      data.schedules.add(
        item(
          'tw',
          today.add(const Duration(hours: 12)),
          service: SnsService.twitch,
        ),
      );
      data.schedules.add(
        item('event', today.add(const Duration(hours: 14)), service: null),
      );
      await settledData();
      vm().setFilter(const ScheduleFilter(services: {SnsService.twitch}));
      var d = (await settledData()).requireValue;
      expect([for (final s in d.schedules) s.id], ['tw', 'event']);

      vm().setFilter(const ScheduleFilter(showPlatformless: false));
      d = (await settledData()).requireValue;
      expect([for (final s in d.schedules) s.id], ['yt', 'tw']);

      // 外した推しの予定は出さない。
      data.creators.add(const Creator(id: 'sora', name: '月城ソラ'));
      data.follows.add(Follow(creatorId: 'sora', followedAt: now));
      await vm().refresh();
      vm().setFilter(const ScheduleFilter(hiddenCreatorIds: {'minato'}));
      d = (await settledData()).requireValue;
      expect([for (final o in d.oshis) o.id], ['sora']);
      expect(d.allOshis, hasLength(2));
      expect(d.schedules, isEmpty);
    });

    test('外した推しだけを隠し、あとからフォローした推しは出す', () async {
      data.creators
        ..add(const Creator(id: 'sora', name: '月城ソラ'))
        ..add(const Creator(id: 'hina', name: '日向ヒナ'));
      data.follows.add(Follow(creatorId: 'sora', followedAt: now));
      await settledData();
      vm().setFilter(const ScheduleFilter(hiddenCreatorIds: {'sora'}));
      var d = (await settledData()).requireValue;
      expect([for (final o in d.oshis) o.id], ['minato']);

      data.follows.add(Follow(creatorId: 'hina', followedAt: now));
      await vm().refresh();
      d = (await settledData()).requireValue;
      expect({for (final o in d.oshis) o.id}, {'minato', 'hina'});

      // フォローを外して、出す推しがいなくなったら、全員を出す。
      data.follows.removeWhere((f) => f.creatorId != 'sora');
      await vm().refresh();
      d = (await settledData()).requireValue;
      expect([for (final o in d.oshis) o.id], ['sora']);
    });

    test('読み直しに失敗しても前の値を残し、もう一度読めたら新しい値にする', () async {
      data.schedules.add(item('a', today.add(const Duration(hours: 10))));
      await settledData();
      data.schedules.add(item('b', today.add(const Duration(hours: 12))));
      data.failReads = true;
      await vm().refresh();
      final failed = container.read(timeScheduleViewModelProvider);
      expect(failed.result.hasError, isTrue);
      expect([for (final s in failed.data!.schedules) s.id], ['a']);

      data.failReads = false;
      await vm().refresh();
      final ok = container.read(timeScheduleViewModelProvider);
      expect(ok.result.hasError, isFalse);
      expect([for (final s in ok.data!.schedules) s.id], ['a', 'b']);
    });
  });

  group('月のカレンダー', () {
    final key = MonthCalendarKey(creatorIds: const ['minato'], initialDay: now);
    Future<AsyncValue<MonthData>> settledData() => settled(
      (onChange) => container.listen(
        monthCalendarViewModelProvider(key),
        (_, _) => onChange(),
      ),
      () => container.read(monthCalendarViewModelProvider(key)).data,
    );
    MonthCalendarViewModel vm() =>
        container.read(monthCalendarViewModelProvider(key).notifier);

    test('開いた日の月と日を選んで始め、その月の予定と実績を読む', () async {
      final thisMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      data.schedules.add(
        item('this', thisMonth.add(const Duration(hours: 10))),
      );
      data.schedules.add(
        item('next', nextMonth.add(const Duration(hours: 10))),
      );
      data.posts.add(
        samplePost(postedAt: thisMonth.add(const Duration(hours: 9))),
      );
      final state = container.read(monthCalendarViewModelProvider(key));
      expect(state.month, thisMonth);
      expect(state.selected, today);
      final d = (await settledData()).requireValue;
      expect([for (final s in d.schedules) s.id], ['this']);
      expect(d.posts, hasLength(1));
      expect(d.schedulesOn(thisMonth), hasLength(1));
      expect(d.dotsOn(thisMonth), (live: true, event: false, post: true));
    });

    test('点は、配信・イベント・投稿の3種類を日ごとに数え、絞り込みに従う', () {
      final day = DateTime(2026, 11, 10);
      final next = DateTime(2026, 11, 11);
      final postOnly = DateTime(2026, 11, 12);
      final data = MonthData(
        schedules: [
          item('live', day.add(const Duration(hours: 20))),
          item('event', day.add(const Duration(hours: 10)), service: null),
          item(
            'hina-live',
            next.add(const Duration(hours: 20)),
            creatorId: 'hina',
          ),
        ],
        posts: [
          samplePost(postedAt: day.add(const Duration(hours: 23, minutes: 59))),
          samplePost(
            id: 'x:1',
            creatorId: 'hina',
            source: SnsService.x,
            postedAt: postOnly.add(const Duration(hours: 9)),
          ),
        ],
      );
      expect(data.dotsOn(day), (live: true, event: true, post: true));
      expect(data.dotsOn(next), (live: true, event: false, post: false));
      expect(data.dotsOn(postOnly), (live: false, event: false, post: true));
      expect(data.dotsOn(DateTime(2026, 11, 13)), (
        live: false,
        event: false,
        post: false,
      ));

      // 投稿を出さない絞り込みなら、投稿の点も出さない。
      const ids = ['minato', 'hina'];
      final noPosts = data.filtered(
        const ScheduleFilter(showPosts: false),
        ids,
      );
      expect(noPosts.dotsOn(day), (live: true, event: true, post: false));
      expect(noPosts.dotsOn(postOnly), (
        live: false,
        event: false,
        post: false,
      ));
      // 推しを外すと、その推しの投稿の点も消える。
      final noHina = data.filtered(
        const ScheduleFilter(hiddenCreatorIds: {'hina'}),
        ids,
      );
      expect(noHina.dotsOn(postOnly), (live: false, event: false, post: false));
      expect(noHina.dotsOn(day).post, isTrue);
    });

    test('月を移すと、その月の1日を選び、データを読み直す', () async {
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      data.schedules.add(
        item('next', nextMonth.add(const Duration(hours: 10))),
      );
      await settledData();
      vm().moveMonth(1);
      final during = container.read(monthCalendarViewModelProvider(key));
      expect(during.month, nextMonth);
      expect(during.selected, nextMonth);
      expect(during.data.hasValue, isFalse);
      final d = (await settledData()).requireValue;
      expect([for (final s in d.schedules) s.id], ['next']);

      vm().moveMonth(-1);
      final back = container.read(monthCalendarViewModelProvider(key));
      expect(back.selected, today);
      expect((await settledData()).requireValue.schedules, isEmpty);
    });

    test('読めなかったら、もう一度試すで読み直す', () async {
      data.failReads = true;
      expect((await settledData()).hasError, isTrue);
      data.failReads = false;
      vm().retry();
      expect((await settledData()).hasValue, isTrue);
    });
  });
}
