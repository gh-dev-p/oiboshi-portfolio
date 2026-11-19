import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/event.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/app_bottom_nav.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/home/widgets/home_body.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';
import 'package:oiboshi/ui/schedule/widgets/event_detail_screen.dart';
import 'package:oiboshi/ui/schedule/widgets/event_list_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  final now = DateTime.now();
  // 来月と再来月の15日（月の見出しが、2つに分かれる）。
  final nextMonth = DateTime(now.year, now.month + 1, 15, 18);
  final monthAfter = DateTime(now.year, now.month + 2, 15, 19);

  void addEvent(
    String id,
    String title,
    DateTime startsAt, {
    String creatorId = 'minato',
    String? venue,
  }) => data.schedules.add(
    sampleSchedule(id, title, startsAt, creatorId: creatorId, venue: venue),
  );

  testWidgets('イベント一覧は、月の見出しで区切って日付順に並べ、2人以上なら名前も出す', (tester) async {
    data.creators.add(const Creator(id: 'sora', name: '天野ソラ'));
    addEvent('e2', 'ツアー最終日', monthAfter, creatorId: 'sora');
    addEvent('e1', 'ワンマンライブ', nextMonth, venue: 'Zepp Haneda');
    addEvent('old', '終わったライブ', now.subtract(const Duration(days: 2)));
    // プラットフォームのある予定（配信）は、イベントではないので出さない。
    data.schedules.add(
      sampleSchedule('live', '雑談配信', nextMonth, service: SnsService.youtube),
    );
    await pumpScreen(tester, data, EventListScreen(creators: data.creators));
    expect(find.text('みんなのイベント'), findsOneWidget);
    expect(find.text('${nextMonth.year}年${nextMonth.month}月'), findsOneWidget);
    expect(
      find.text('${monthAfter.year}年${monthAfter.month}月'),
      findsOneWidget,
    );
    expect(find.text('ワンマンライブ'), findsOneWidget);
    expect(find.textContaining('18:00・Zepp Haneda'), findsOneWidget);
    expect(find.text('ツアー最終日'), findsOneWidget);
    expect(find.text('天野ソラ'), findsOneWidget);
    expect(find.text('終わったライブ'), findsNothing);
    expect(find.text('雑談配信'), findsNothing);
    // 日付順（ワンマンライブが先）。
    expect(
      tester.getTopLeft(find.text('ワンマンライブ')).dy,
      lessThan(tester.getTopLeft(find.text('ツアー最終日')).dy),
    );
    await unmount(tester);
  });

  testWidgets('1人のイベント一覧は、見出しに名前を出し、行を押すとイベントの詳細を開く', (tester) async {
    addEvent('e1', 'ワンマンライブ', nextMonth);
    await pumpScreen(
      tester,
      data,
      EventListScreen(creators: data.creators, openCreator: false),
    );
    expect(find.text('星野ミナトのイベント'), findsOneWidget);
    // 1人のときは、行に名前を出さない。
    expect(find.text('星野ミナト'), findsNothing);
    await tester.tap(find.text('ワンマンライブ'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('ワンマンライブ'), findsOneWidget);
    expect(find.text('星野ミナト'), findsOneWidget);
    // 発信者ページから開いた一覧では、発信者の行を押せない（矢印を出さない）。
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    // リンクがなければ、「チケットサイトで見る」を出さない。
    expect(find.textContaining('で購入'), findsNothing);
    await unmount(tester);
  });

  testWidgets('イベントの詳細は、日時・会場と、サイトの名前つきのリンクのボタンを出し、開く前に確かめる', (tester) async {
    final item = sampleSchedule(
      'e1',
      'ワンマンライブ',
      nextMonth,
      endsAt: nextMonth.add(const Duration(hours: 2)),
      venue: 'Zepp Haneda',
      ticketUrl: 'https://t.pia.jp/pia/event/event.do?eventBundleCd=b1',
      ticketIsPromotion: true,
    );
    await pumpScreen(
      tester,
      data,
      EventDetailScreen(item: item, creator: data.creators.first),
    );
    expect(find.text('ワンマンライブ'), findsOneWidget);
    expect(find.text('Zepp Haneda'), findsOneWidget);
    expect(find.textContaining('18:00〜20:00'), findsOneWidget);
    expect(find.text('チケットぴあで購入'), findsOneWidget);
    expect(find.text('PR'), findsOneWidget);
    expect(find.text('この予定を通報する'), findsOneWidget);
    expect(find.text('終了しました'), findsNothing);
    await tester.tap(find.text('チケットぴあで購入'));
    await tester.pumpAndSettle();
    expect(find.text('外部のサイトを開きます'), findsOneWidget);
    expect(find.text('t.pia.jp'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('3日前に始まり3日後に終わるイベントは、開催中として一覧に出す', (tester) async {
    data.schedules.add(
      sampleSchedule(
        'long',
        '展示会',
        now.subtract(const Duration(days: 3)),
        endsAt: now.add(const Duration(days: 3)),
      ),
    );
    await pumpScreen(tester, data, EventListScreen(creators: data.creators));
    expect(find.text('展示会'), findsOneWidget);
    await tester.tap(find.text('展示会'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('終了しました'), findsNothing);
    await unmount(tester);
  });

  testWidgets('当日の終日のイベントの詳細には「終了しました」を出さず、前の日のものには出す', (tester) async {
    final today = DateTime(now.year, now.month, now.day);
    await pumpScreen(
      tester,
      data,
      EventDetailScreen(
        item: sampleSchedule('d1', '当日の展示', today, allDay: true),
        creator: data.creators.first,
      ),
    );
    expect(find.text('終了しました'), findsNothing);
    await unmount(tester);
    await pumpScreen(
      tester,
      data,
      EventDetailScreen(
        item: sampleSchedule(
          'd2',
          '昨日の展示',
          today.subtract(const Duration(days: 1)),
          allDay: true,
        ),
        creator: data.creators.first,
      ),
    );
    expect(find.text('終了しました'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('時刻未定の公演は、一覧と詳細に「時刻未定」と出す', (tester) async {
    final day = DateTime(nextMonth.year, nextMonth.month, nextMonth.day);
    data.events['ev'] = const Event(
      id: 'ev',
      creatorId: 'minato',
      title: 'Zepp ツアー',
      links: [],
      performances: [],
    );
    final item = sampleSchedule(
      'p1',
      'Zepp ツアー',
      day,
      allDay: true,
      eventId: 'ev',
    );
    data.schedules.add(item);
    await pumpScreen(tester, data, EventListScreen(creators: data.creators));
    expect(find.textContaining('時刻未定'), findsOneWidget);
    expect(find.textContaining('終日'), findsNothing);
    await tester.tap(find.text('Zepp ツアー'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.textContaining('時刻未定'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('イベントのリンクが複数あれば、サイトごとのボタンを並べる', (tester) async {
    data.events['ev'] = const Event(
      id: 'ev',
      creatorId: 'minato',
      title: 'ワンマンライブ',
      links: [
        EventLink(url: 'https://t.pia.jp/pia/ticketInformation.do?eventCd=1'),
        EventLink(
          url: 'https://eplus.jp/sf/detail/0000000001',
          isPromotion: true,
        ),
        EventLink(url: 'https://www.example.com/tickets'),
      ],
      performances: [],
    );
    final item = sampleSchedule('p1', 'ワンマンライブ', nextMonth, eventId: 'ev');
    await pumpScreen(
      tester,
      data,
      EventDetailScreen(item: item, creator: data.creators.first),
    );
    expect(find.text('チケットぴあで購入'), findsOneWidget);
    expect(find.text('イープラスで購入'), findsOneWidget);
    // ボタンの上に、見出し「チケット」を出す。
    expect(find.text('チケット'), findsOneWidget);
    expect(find.text('example.comで購入'), findsOneWidget);
    expect(find.text('PR'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('オーナーには、イベントの詳細に「編集」を出し、通報は出さない', (tester) async {
    data.ownedCreatorId = 'minato';
    final item = sampleSchedule('e1', 'ワンマンライブ', nextMonth);
    await pumpScreen(
      tester,
      data,
      EventDetailScreen(item: item, creator: data.creators.first),
    );
    expect(find.text('編集'), findsOneWidget);
    expect(find.text('この予定を通報する'), findsNothing);
    await unmount(tester);
  });

  testWidgets('終わったイベントの詳細には、「終了しました」を出す', (tester) async {
    final item = sampleSchedule(
      'old',
      '終わったライブ',
      now.subtract(const Duration(days: 3)),
      endsAt: now.subtract(const Duration(days: 3, hours: -2)),
    );
    await pumpScreen(
      tester,
      data,
      EventDetailScreen(item: item, creator: data.creators.first),
    );
    expect(find.text('終了しました'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ホームの「イベント」の行を押すと、ホームのタブの中でイベントの詳細を開き、発信者の行から発信者ページへ行ける', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..follows.add(sampleFollow());
    addEvent('e1', 'ワンマンライブ', now.add(const Duration(days: 2)));
    await pumpScreen(tester, data, const HomeShell());
    final row = find.text('ワンマンライブ');
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(
      tester.widget<AppBottomNav>(find.byType(AppBottomNav)).currentIndex,
      0,
    );
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorScreen), findsOneWidget);
    expect(
      tester.widget<AppBottomNav>(find.byType(AppBottomNav)).currentIndex,
      2,
    );
    await unmount(tester);
  });

  testWidgets('イベントがなければ、ないことを知らせる', (tester) async {
    await pumpScreen(tester, data, EventListScreen(creators: data.creators));
    expect(find.text('これからのイベントはありません'), findsOneWidget);
    expect(find.text('イベントが登録されると、ここに出ます'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('発信者ページは、イベントを「次の予定」ではなく「イベント」に出し、2件まで並べる', (tester) async {
    // 発信者ページのカバー（横3：縦1）が画面の幅で伸びるので、縦を長くして投稿まで出す。
    usePhoneScreen(tester, size: const Size(2400, 3600));
    data.schedules.add(
      sampleSchedule(
        'live',
        '雑談配信',
        now.add(const Duration(days: 3)),
        service: SnsService.youtube,
      ),
    );
    for (var i = 0; i < 3; i++) {
      addEvent('e$i', 'ライブ$i', now.add(Duration(days: i + 1)));
    }
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    // 次の予定は、イベントより後の配信でも、配信を出す。
    expect(find.text('雑談配信'), findsOneWidget);
    expect(find.text('イベント'), findsOneWidget);
    expect(find.text('ライブ0'), findsOneWidget);
    expect(find.text('ライブ1'), findsOneWidget);
    expect(find.text('ライブ2'), findsNothing);
    expect(find.text('ほか 1 件'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('発信者ページのイベントがなくても、面を出し、ないことを知らせる', (tester) async {
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    expect(find.text('イベント'), findsOneWidget);
    expect(find.text('これからのイベントはありません'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('発信者ページの「イベント」の「ほか N 件」は、推しのタブの中で、その発信者のイベント一覧を開く', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..follows.add(sampleFollow());
    for (var i = 0; i < 4; i++) {
      addEvent('e$i', 'ライブ$i', now.add(Duration(days: i + 1)));
    }
    await pumpScreen(tester, data, const HomeShell());
    // ホームから発信者ページを開くと、推しのタブに開く。
    CreatorScreen.open(tester.element(find.byType(HomeBody)), 'minato');
    await tester.pumpAndSettle();
    final more = find.text('ほか 2 件');
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    final list = tester.widget<EventListScreen>(find.byType(EventListScreen));
    expect([for (final c in list.creators) c.id], ['minato']);
    expect(find.text('星野ミナトのイベント'), findsOneWidget);
    expect(find.text('ライブ3'), findsOneWidget);
    expect(
      tester.widget<AppBottomNav>(find.byType(AppBottomNav)).currentIndex,
      2,
    );
    await unmount(tester);
  });
}
