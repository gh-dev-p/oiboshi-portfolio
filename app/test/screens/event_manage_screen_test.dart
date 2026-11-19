import 'package:flutter/widgets.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/event.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/state_view.dart';
import 'package:oiboshi/ui/creator_admin/widgets/creator_menu_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/event_manage_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/event_register_screen.dart';
import 'package:oiboshi/ui/schedule/widgets/month_calendar_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

/// イベントの管理（画面定義書（設定・発信者向け）2.3.7）と、
/// 予定の詳細の「編集」「リンクを開く」（画面定義書（スケジュール）2.1.5）。
/// 一覧の行からのイベントの編集・削除は、event_register_screens_test.dart で確かめる。
void main() {
  setUpScreenTests();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  /// イベント [eventId] の公演。
  ScheduleItem event(
    String id,
    String title,
    DateTime startsAt, {
    String? ticketUrl,
    String eventId = 'ev',
  }) => sampleSchedule(
    id,
    title,
    startsAt,
    ticketUrl: ticketUrl,
    eventId: eventId,
  );

  testWidgets('発信者メニューの「イベントの管理」から一覧を開き、1件もなければ登録を促す', (tester) async {
    data.ownedCreatorId = 'minato';
    await pumpScreen(
      tester,
      data,
      const CreatorMenuScreen(creatorId: 'minato'),
    );
    // 「イベントの登録」と「カレンダー予定」の行は、「イベントの管理」の1行にまとめた。
    expect(find.text('カレンダー予定'), findsNothing);
    expect(find.text('イベントの登録'), findsNothing);
    // 発信者メニューの行が増えたので、行まで送ってから押す。
    await tester.scrollUntilVisible(
      find.text('イベントの管理'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('イベントの管理'));
    await tester.pumpAndSettle();
    expect(find.byType(EventManageScreen), findsOneWidget);
    expect(find.text('イベントはまだありません'), findsOneWidget);
    // 空の状態の「登録」から、イベントの登録の画面へ。
    await tester.tap(
      find.descendant(of: find.byType(StateView), matching: find.text('登録')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EventRegisterScreen), findsOneWidget);
    expect(find.text('イベントの登録'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('一覧は、取得した予約を出さず、過去のイベントは閉じてまとめる。「登録」でイベントの登録を開く', (tester) async {
    data.ownedCreatorId = 'minato';
    data.schedules.addAll([
      event('e1', 'ツアー名古屋', today.add(const Duration(days: 2, hours: 18))),
      event(
        'e2',
        '前のライブ',
        today.subtract(const Duration(days: 10)),
        eventId: 'ev2',
      ),
      sampleSchedule(
        'f1',
        '取った予約',
        today.add(const Duration(days: 3, hours: 20)),
        service: SnsService.youtube,
        fetched: true,
      ),
    ]);
    await pumpScreen(
      tester,
      data,
      const EventManageScreen(creatorId: 'minato'),
    );
    expect(find.text('イベントの管理'), findsOneWidget);
    expect(find.text('ツアー名古屋'), findsOneWidget);
    expect(find.text('取った予約'), findsNothing);
    expect(find.text('過去のイベント'), findsOneWidget);
    expect(find.text('前のライブ'), findsNothing);
    await tester.tap(find.text('過去のイベント'));
    await tester.pumpAndSettle();
    expect(find.text('前のライブ'), findsOneWidget);

    await tester.tap(find.text('登録'));
    await tester.pumpAndSettle();
    expect(find.byType(EventRegisterScreen), findsOneWidget);
    expect(find.text('イベントの登録'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('予定の詳細の「編集」は、イベントの公演のオーナーにだけ出し、押すとイベントの編集を開く', (tester) async {
    final day = DateTime(2026, 10, 16);
    data.events['ev'] = const Event(
      id: 'ev',
      creatorId: 'minato',
      title: 'ファンミーティング',
      links: [],
      performances: [],
    );
    data.schedules.addAll([
      event('e1', 'ファンミーティング', day.add(const Duration(hours: 18))),
      sampleSchedule(
        'f1',
        '取った予約',
        day.add(const Duration(hours: 21)),
        service: SnsService.youtube,
        fetched: true,
      ),
    ]);
    Future<void> openDetail(String title) async {
      await pumpScreen(
        tester,
        data,
        MonthCalendarScreen(creators: data.creators, initialDay: day),
      );
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }

    // オーナーでなければ、出さない。
    await openDetail('ファンミーティング');
    expect(find.text('発信者のページを開く'), findsOneWidget);
    expect(find.text('編集'), findsNothing);
    await unmount(tester);

    data.ownedCreatorId = 'minato';
    // 取得した予約は、オーナーでも出さない。
    await openDetail('取った予約');
    expect(find.text('編集'), findsNothing);
    await unmount(tester);

    await openDetail('ファンミーティング');
    expect(find.text('編集'), findsOneWidget);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(find.text('イベントの編集'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('リンクを開く前に、行き先のドメインを出して確かめる', (tester) async {
    final day = DateTime(2026, 10, 16);
    data.schedules.add(
      event(
        'e1',
        'ファンミーティング',
        day.add(const Duration(hours: 18)),
        ticketUrl: 'https://tickets.example.com/e/1?ref=oiboshi',
      ),
    );
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(creators: data.creators, initialDay: day),
    );
    // 月のカレンダーの「チケット」（イベントなので）のボタン。
    await tester.tap(find.text('チケット'));
    await tester.pumpAndSettle();
    expect(find.text('外部のサイトを開きます'), findsOneWidget);
    expect(find.text('tickets.example.com'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('外部のサイトを開きます'), findsNothing);
    // 予定の詳細の「チケットを見る」も同じ。
    await tester.tap(find.text('ファンミーティング'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('チケットを見る'));
    await tester.pumpAndSettle();
    expect(find.text('tickets.example.com'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('https:// で始まらない、前からあるリンクは開かない', (tester) async {
    final day = DateTime(2026, 10, 16);
    data.schedules.add(
      event(
        'e1',
        'ファンミーティング',
        day.add(const Duration(hours: 18)),
        ticketUrl: 'http://tickets.example.com/e/1',
      ),
    );
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(creators: data.creators, initialDay: day),
    );
    await tester.tap(find.text('チケット'));
    await tester.pumpAndSettle();
    expect(find.text('外部のサイトを開きます'), findsNothing);
    expect(find.text('ページを開けませんでした'), findsOneWidget);
    await unmount(tester);
  });
}
