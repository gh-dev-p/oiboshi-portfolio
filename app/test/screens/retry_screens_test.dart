import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/ui/core/ui/creator_row.dart';
import 'package:oiboshi/ui/core/ui/skeleton.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/home/view_models/home_viewmodel.dart';
import 'package:oiboshi/ui/home/widgets/home_body.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';
import 'package:oiboshi/ui/onboarding/widgets/choose_oshi_screen.dart';
import 'package:oiboshi/ui/oshi/widgets/find_creators_screen.dart';
import 'package:oiboshi/ui/schedule/view_models/time_schedule_viewmodel.dart';
import 'package:oiboshi/ui/schedule/widgets/event_list_screen.dart';
import 'package:oiboshi/ui/schedule/widgets/month_calendar_screen.dart';
import 'package:oiboshi/ui/schedule/widgets/schedule_table.dart';
import 'package:oiboshi/ui/schedule/widgets/time_schedule_body.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

/// 「もう一度試す」「再試行」のあとの、読み込み中とスナックバー（画面定義書 5.1.3・2.2.4・2.2.5）。
void main() {
  setUpScreenTests();

  /// 初めて読み込めなかった画面で「もう一度試す」を押すと、読み込みが終わるまでスケルトンに戻る。
  Future<void> expectRetryShowsSkeleton(
    WidgetTester tester,
    Widget screen, {
    required Finder skeleton,
    required Finder loaded,
  }) async {
    data.failReads = true;
    await pumpScreen(tester, data, screen);
    expect(find.text('読み込めませんでした'), findsOneWidget);

    data.failReads = false;
    final gate = data.signInGate = Completer<void>();
    await tester.tap(find.text('もう一度試す'));
    await tester.pump();
    expect(find.text('読み込めませんでした'), findsNothing);
    expect(skeleton, findsWidgets);

    gate.complete();
    await tester.pumpAndSettle();
    expect(loaded, findsWidgets);
    await unmount(tester);
  }

  testWidgets('ホームで「もう一度試す」を押すと、スケルトンに戻る', (tester) async {
    await expectRetryShowsSkeleton(
      tester,
      const HomeBody(),
      skeleton: find.byType(SkeletonBox),
      loaded: find.text('推しを探しましょう'),
    );
  });

  testWidgets('推しリストで「もう一度試す」を押すと、スケルトンに戻る', (tester) async {
    data.onboardingDone = true;
    data.follows.add(sampleFollow());
    data.failReads = true;
    await pumpScreen(tester, data, const HomeShell());
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    expect(find.text('読み込めませんでした'), findsWidgets);

    data.failReads = false;
    final gate = data.signInGate = Completer<void>();
    await tester.tap(find.text('もう一度試す').last);
    await tester.pump();
    expect(find.byType(CreatorListSkeleton), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('星野ミナト'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('発信者ページで「もう一度試す」を押すと、スケルトンに戻る', (tester) async {
    await expectRetryShowsSkeleton(
      tester,
      const CreatorScreen(creatorId: 'minato'),
      skeleton: find.byType(SkeletonBox),
      loaded: find.text('歌とゲームの配信をしています'),
    );
  });

  testWidgets('推しを探すで「もう一度試す」を押すと、スケルトンに戻る', (tester) async {
    await expectRetryShowsSkeleton(
      tester,
      const FindCreatorsScreen(),
      skeleton: find.byType(CreatorListSkeleton),
      loaded: find.text('星野ミナト'),
    );
  });

  testWidgets('推しを選ぶで「もう一度試す」を押すと、スケルトンに戻る', (tester) async {
    // 下部のバーがあるので、スケルトンが収まる高さにする。
    tester.view.physicalSize = const Size(2400, 3000);
    addTearDown(tester.view.resetPhysicalSize);
    await expectRetryShowsSkeleton(
      tester,
      const ChooseOshiScreen(),
      skeleton: find.byType(CreatorListSkeleton),
      loaded: find.text('星野ミナト'),
    );
  });

  testWidgets('更新に失敗して「再試行」を押すと、読み込み中はスナックバーを出さず、また失敗したら1回だけ出す', (
    tester,
  ) async {
    data.follows.add(sampleFollow());
    // ほかのタブのスナックバーが混ざらないように、ホームだけを出す。
    await pumpScreen(tester, data, const HomeBody());
    expect(find.text('新しい動画'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeBody)),
    );

    // 1分ごとの読み直しに失敗すると、内容を残してスナックバーを出す。
    data.failReads = true;
    await container.read(homeViewModelProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsOneWidget);
    expect(find.text('新しい動画'), findsOneWidget);

    // 「再試行」で読み込んでいるあいだは、スナックバーを出さない。
    final gate = data.signInGate = Completer<void>();
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsNothing);
    expect(find.text('新しい動画'), findsOneWidget);

    // また失敗したら、もう一度だけ出す。
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsOneWidget);

    // 「再試行」が成功したら、出さない。
    data.failReads = false;
    data.signInGate = null;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsNothing);
    expect(find.text('新しい動画'), findsOneWidget);
    await unmount(tester);
  });

  /// 定期の読み直しに失敗すると、内容を残してスナックバーを出す。「再試行」で読み込むあいだは出さず、
  /// また失敗したら出し、成功したら出さない。
  Future<void> expectRefreshFailureSnackBar(
    WidgetTester tester,
    Widget screen, {
    required Finder content,
  }) async {
    await pumpScreen(tester, data, screen);
    expect(content, findsWidgets);

    data.failReads = true;
    await tester.pump(refreshInterval);
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsOneWidget);
    expect(content, findsWidgets);

    final gate = data.signInGate = Completer<void>();
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsNothing);
    expect(content, findsWidgets);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsOneWidget);

    data.failReads = false;
    data.signInGate = null;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsNothing);
    expect(content, findsWidgets);
    await unmount(tester);
  }

  testWidgets('イベント一覧は、読み込み中も、同じ失敗が続く間も、スナックバーを重ねて出さない', (tester) async {
    data.schedules.add(
      sampleSchedule(
        's1',
        '周年ライブ',
        DateTime.now().add(const Duration(days: 7)),
        eventId: 'ev',
      ),
    );
    await expectRefreshFailureSnackBar(
      tester,
      EventListScreen(creators: data.creators),
      content: find.text('周年ライブ'),
    );
  });

  testWidgets('月のカレンダーは、読み込み中も、同じ失敗が続く間も、スナックバーを重ねて出さない', (tester) async {
    final day = DateTime(2026, 10, 16);
    data.schedules.add(
      sampleSchedule('s1', 'ファンミーティング', day.add(const Duration(hours: 18))),
    );
    await expectRefreshFailureSnackBar(
      tester,
      MonthCalendarScreen(creators: data.creators, initialDay: day),
      content: find.text('ファンミーティング'),
    );
  });

  testWidgets('タイムスケジュールは、読み込み中も、同じ失敗が続く間も、スナックバーを重ねて出さない', (tester) async {
    data.follows.add(sampleFollow());
    await expectRefreshFailureSnackBar(
      tester,
      const TimeScheduleBody(),
      content: find.byType(ScheduleTable),
    );
  });

  testWidgets('タイムスケジュールは、日を切り替えて読めなかったときも、内容を残してスナックバーを出す', (tester) async {
    data.follows.add(sampleFollow());
    await pumpScreen(tester, data, const TimeScheduleBody());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TimeScheduleBody)),
    );
    data.failReads = true;
    container
        .read(timeScheduleViewModelProvider.notifier)
        .selectDay(DateTime.now().add(const Duration(days: 1)));
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsOneWidget);
    expect(find.text('読み込めませんでした'), findsNothing);
    await unmount(tester);
  });

  testWidgets('イベント一覧で「もう一度試す」を押すと、スケルトンに戻り、サインインからやり直す', (tester) async {
    await expectRetryShowsSkeleton(
      tester,
      EventListScreen(creators: data.creators),
      skeleton: find.byType(SkeletonLine),
      loaded: find.text('これからのイベントはありません'),
    );
  });

  testWidgets('月のカレンダーで「もう一度試す」を押すと、スケルトンに戻る', (tester) async {
    await expectRetryShowsSkeleton(
      tester,
      MonthCalendarScreen(creators: data.creators, initialDay: DateTime.now()),
      skeleton: find.byType(SkeletonLine),
      loaded: find.byIcon(Icons.chevron_left),
    );
  });

  testWidgets('推しの行を横にスクロールしても、タイムラインの続きを読まない', (tester) async {
    for (var i = 0; i < 12; i++) {
      data.creators.add(Creator(id: 'c$i', name: '推し$i'));
      data.follows.add(sampleFollow('c$i'));
    }
    for (var i = 0; i < 60; i++) {
      data.posts.add(
        samplePost(
          id: 'yt:p$i',
          text: '投稿$i',
          postedAt: DateTime.now().subtract(Duration(hours: 2, minutes: i)),
        ),
      );
    }
    data.follows.add(sampleFollow());
    data.onboardingDone = true;
    await tester.pumpWidget(await testApp(data, const HomeShell()));
    // タイムラインの末尾に読み込み中の印が回り続けるので、pumpAndSettle は使わない。
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('推し0'), findsOneWidget);
    data.timelineReads.clear();

    await tester.drag(find.text('推し0'), const Offset(-600, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(data.timelineReads, isEmpty);
    await unmount(tester);
  });
}
