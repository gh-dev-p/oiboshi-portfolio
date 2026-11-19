import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/event_draft.dart';
import 'package:oiboshi/ui/creator_admin/widgets/event_manage_screen.dart';
import 'package:oiboshi/ui/core/ui/settings_row.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';
import 'package:oiboshi/domain/models/event.dart';
import 'package:oiboshi/ui/creator_admin/widgets/creator_menu_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/event_candidates_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/event_page_reader_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/event_register_screen.dart';
import 'package:oiboshi/domain/models/ticket_search.dart';
import 'package:oiboshi/utils/js_result.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

/// イベントの登録（画面定義書（設定・発信者向け）2.3.9。試作）。
void main() {
  setUpScreenTests();

  const url = 'https://t.pia.jp/pia/event/event.do?eventBundleCd=b1';

  Future<void> pumpRegister(WidgetTester tester) async {
    data.ownedCreatorId = 'minato';
    await pumpScreen(
      tester,
      data,
      const EventRegisterScreen(creatorId: 'minato'),
    );
  }

  /// 一覧の下のほうにある欄まで、スクロールして出す。
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  /// 「読み取る」で開いたページから、「このページから読み取る」で読み取る。[html] は、ページから取り出す部分。
  Future<void> readFromPage(
    WidgetTester tester, {
    String html = '<div>2026/11/2(月) 18:00 開演</div>',
    String pageUrl = '',
  }) async {
    FakeWebViewPlatform.loadedUrls.clear();
    FakeWebViewPlatform.pageFinished.clear();
    FakeWebViewPlatform.scripts.clear();
    // Android は、JavaScript の結果を、JSON の文字列（引用符つき）で返す。
    FakeWebViewPlatform.scriptResult = jsonEncode(html);
    addTearDown(() => FakeWebViewPlatform.scriptResult = null);
    await tester.tap(find.text('読み取る'));
    // 読み込み中のバーが動き続けるので、落ち着くのを待たずに、画面の移りの分だけ進める。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(EventPageReaderScreen), findsOneWidget);
    for (final f in FakeWebViewPlatform.pageFinished) {
      f(pageUrl);
    }
    await tester.pump();
    await tester.tap(find.text('このページから読み取る'));
    await tester.pumpAndSettle();
  }

  testWidgets('発信者メニューの「イベントの管理」の「登録」から、登録の画面を開く', (tester) async {
    data.ownedCreatorId = 'minato';
    await pumpScreen(
      tester,
      data,
      const CreatorMenuScreen(creatorId: 'minato'),
    );
    // 発信者メニューの行が増えたので、行まで送ってから押す。
    await tester.scrollUntilVisible(
      find.text('イベントの管理'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('イベントの管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登録').first);
    await tester.pumpAndSettle();
    expect(find.byType(EventRegisterScreen), findsOneWidget);
    expect(find.text('チケットの URL'), findsOneWidget);
    expect(find.text('公演'), findsOneWidget);
    // 1つのイベントに、公演は1つ。公演を足すボタンはない。
    expect(find.text('＋ 公演を足す'), findsNothing);
    // 終了の欄の下に、空のときの表示を知らせる（2026-11-19 本人）。
    await tester.scrollUntilVisible(
      find.text('指定しない場合は、その日の終わりまで表示します'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('指定しない場合は、その日の終わりまで表示します'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('「読み取る」で、貼った URL をアプリの中で開き、要る部分だけを取り出して読み取る', (tester) async {
    data.eventDrafts[url] = EventDraft(
      title: 'Zepp ツアー',
      performances: [
        PerformanceDraft(
          date: DateTime(2026, 11, 2),
          start: (hour: 18, minute: 0),
          venue: 'Zepp Nagoya',
        ),
        PerformanceDraft(date: DateTime(2026, 11, 12), venue: 'Zepp Haneda'),
      ],
    );
    await pumpRegister(tester);
    await tester.enterText(find.byType(TextField).first, url);
    await tester.pump();
    FakeWebViewPlatform.loadedUrls.clear();
    FakeWebViewPlatform.pageFinished.clear();
    FakeWebViewPlatform.scriptResult = jsonEncode('<div>x</div>');
    addTearDown(() => FakeWebViewPlatform.scriptResult = null);
    await tester.tap(find.text('読み取る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // サーバーは読みに行かず、アプリの中でページを開く。
    expect(data.eventUrlReads, isEmpty);
    expect(FakeWebViewPlatform.loadedUrls, [Uri.parse(url)]);
    expect(find.text('t.pia.jp'), findsOneWidget);
    // 読み込み終えるまでは押せない。
    await tester.tap(find.text('このページから読み取る'), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(EventPageReaderScreen), findsOneWidget);
    for (final f in FakeWebViewPlatform.pageFinished) {
      f(url);
    }
    await tester.pump();
    await tester.tap(find.text('このページから読み取る'));
    await tester.pumpAndSettle();
    expect(find.byType(EventPageReaderScreen), findsNothing);
    // ページ全体ではなく、要る部分だけを取り出す JavaScript を走らせる。
    expect(
      FakeWebViewPlatform.scripts.last,
      EventPageReaderScreen.extractScript,
    );
    expect(data.eventPageHtmls, ['<div>x</div>']);
    // 公演が2つあるので、1つ選ぶ。
    expect(find.text('公演を選ぶ'), findsOneWidget);
    expect(find.text('2026年11月2日（月） 18:00'), findsOneWidget);
    expect(find.text('2026年11月12日（木）'), findsOneWidget);
    await tester.tap(find.text('Zepp Haneda'));
    await tester.pumpAndSettle();
    expect(find.text('読み取りました。内容を確かめてください'), findsOneWidget);
    expect(find.text('Zepp ツアー'), findsOneWidget);
    expect(find.text('Zepp Haneda'), findsOneWidget);
    expect(find.text('Zepp Nagoya'), findsNothing);
    // 選んだ公演は、開始が分からないので、保存すると必須の項目が足りないと知らせる。
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('必須の項目を入力してください'), findsOneWidget);
    expect(data.schedules, isEmpty);
    await unmount(tester);
  });

  testWidgets('読み取れなければ、手で入れるよう知らせる。https でない URL は開かない', (tester) async {
    await pumpRegister(tester);
    FakeWebViewPlatform.loadedUrls.clear();
    await tester.enterText(find.byType(TextField).first, 'http://example.com/');
    await tester.pump();
    await tester.tap(find.text('読み取る'));
    await tester.pumpAndSettle();
    expect(FakeWebViewPlatform.loadedUrls, isEmpty);
    expect(find.text('https:// で始まる URL を入れてください'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'https://l-tike.com/x/',
    );

    await tester.pump();
    await readFromPage(tester);
    expect(data.eventUrlReads, ['https://l-tike.com/x/']);
    expect(find.text('読み取れませんでした。手で入れてください'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('URL が空のあいだは、「読み取る」を押してもページを開かない', (tester) async {
    await pumpRegister(tester);
    FakeWebViewPlatform.loadedUrls.clear();
    await tester.tap(find.text('読み取る'));
    await tester.pumpAndSettle();
    expect(FakeWebViewPlatform.loadedUrls, isEmpty);
    expect(find.byType(EventPageReaderScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('ページの中を移ってから読み取ったら、移った先の URL で読み取り、リンクにする', (tester) async {
    const moved = 'https://t.pia.jp/pia/event/event.do?eventBundleCd=b9';
    data.eventDrafts[moved] = EventDraft(
      title: '移った先のツアー',
      performances: [
        PerformanceDraft(
          date: DateTime(2026, 11, 2),
          start: (hour: 18, minute: 0),
        ),
      ],
    );
    await pumpRegister(tester);
    await tester.enterText(find.byType(TextField).first, url);
    await tester.pump();
    await readFromPage(tester, pageUrl: moved);
    expect(data.eventUrlReads, [moved]);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final event = data.events.values.single;
    expect(event.title, '移った先のツアー');
    expect(event.links.map((l) => l.url), [moved]);
    await unmount(tester);
  });

  test('JavaScript の結果は、引用符つきの JSON の文字列もほどく', () {
    expect(jsResultToString('"a\\nb"'), 'a\nb');
    expect(jsResultToString('<div></div>'), '<div></div>');
  });

  testWidgets('読み取った公演から1つ選んで保存すると、その公演でイベントを作る', (tester) async {
    data.eventDrafts[url] = EventDraft(
      title: 'Zepp ツアー',
      performances: [
        PerformanceDraft(
          date: DateTime(2026, 11, 2),
          start: (hour: 18, minute: 0),
          venue: 'Zepp Nagoya',
        ),
        PerformanceDraft(
          date: DateTime(2026, 11, 12),
          start: (hour: 19, minute: 0),
          end: (hour: 21, minute: 0),
          venue: 'Zepp Haneda',
        ),
      ],
    );
    await pumpRegister(tester);
    await tester.enterText(find.byType(TextField).first, url);
    await tester.pump();
    await readFromPage(tester);
    await tester.tap(find.text('Zepp Haneda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final saved = data.schedules.single;
    expect(saved.title, 'Zepp ツアー');
    expect(saved.ticketUrl, url);
    expect(saved.venue, 'Zepp Haneda');
    expect(saved.isEvent, isTrue);
    expect(saved.startsAt, DateTime(2026, 11, 12, 19));
    expect(saved.endsAt, DateTime(2026, 11, 12, 21));
    await unmount(tester);
  });

  testWidgets('公演を選ばずに閉じたら、公演の欄は入れ替えない', (tester) async {
    data.eventDrafts[url] = EventDraft(
      title: 'Zepp ツアー',
      performances: [
        PerformanceDraft(date: DateTime(2026, 11, 2), venue: 'Zepp Nagoya'),
        PerformanceDraft(date: DateTime(2026, 11, 12), venue: 'Zepp Haneda'),
      ],
    );
    await pumpRegister(tester);
    await tester.enterText(find.byType(TextField).first, url);
    await tester.pump();
    await readFromPage(tester);
    expect(find.text('公演を選ぶ'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('公演を選ぶ'), findsNothing);
    expect(find.text('Zepp ツアー'), findsOneWidget);
    expect(find.text('Zepp Nagoya'), findsNothing);
    expect(find.text('Zepp Haneda'), findsNothing);
    await unmount(tester);
  });

  testWidgets('リンクは何本でも持て、PR はリンクごと。読み取った URL は、自動でリンクに入る', (tester) async {
    data.eventDrafts[url] = EventDraft(
      title: 'Zepp ツアー',
      performances: [
        PerformanceDraft(
          date: DateTime(2026, 11, 2),
          start: (hour: 18, minute: 0),
        ),
      ],
    );
    await pumpRegister(tester);
    await tester.enterText(find.byType(TextField).first, url);
    await tester.pump();
    await readFromPage(tester);
    await scrollTo(tester, find.text('＋ チケットリンクを足す'));
    expect(find.text(url), findsWidgets);
    await tester.tap(find.text('＋ チケットリンクを足す'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('＋ チケットリンクを足す'));
    // 2本目のリンクに、イープラスの URL を入れて、PR にする。
    final linkFields = find.descendant(
      of: find.byType(SurfacePanel),
      matching: find.widgetWithText(TextField, 'https://'),
    );
    await tester.enterText(
      linkFields.last,
      'https://eplus.jp/sf/detail/0000000001',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppSwitch).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final event = data.events.values.single;
    expect(event.title, 'Zepp ツアー');
    expect(
      [for (final l in event.links) (l.url, l.isPromotion)],
      [(url, false), ('https://eplus.jp/sf/detail/0000000001', true)],
    );
    // 公演は、イベントの公演として予定になり、1本目のリンクを写す。
    final perf = data.schedules.single;
    expect(perf.eventId, event.id);
    expect(perf.ticketUrl, url);
    await unmount(tester);
  });

  testWidgets('同じチケットのページが、ほかのイベントで登録済みなら、保存できない', (tester) async {
    data.events['other'] = const Event(
      id: 'other',
      creatorId: 'minato',
      title: '前のイベント',
      links: [EventLink(url: url)],
      performances: [],
    );
    data.eventDrafts[url] = EventDraft(
      title: 'Zepp ツアー',
      performances: [
        PerformanceDraft(
          date: DateTime(2026, 11, 2),
          start: (hour: 18, minute: 0),
        ),
      ],
    );
    await pumpRegister(tester);
    await tester.enterText(find.byType(TextField).first, url);
    await tester.pump();
    await readFromPage(tester);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('このチケットリンクは、ほかのイベントで登録済みです'), findsOneWidget);
    expect(data.events.keys, ['other']);
    await unmount(tester);
  });

  testWidgets('イベントの管理からイベントの公演を押すと、イベントの編集を開き、保存・削除できる', (tester) async {
    data.ownedCreatorId = 'minato';
    data.events['ev'] = const Event(
      id: 'ev',
      creatorId: 'minato',
      title: 'ツアー',
      links: [EventLink(url: url, isPromotion: true)],
      performances: [],
    );
    final day = DateTime.now().add(const Duration(days: 10));
    data.schedules.add(
      sampleSchedule(
        'p0',
        'ツアー',
        DateTime(day.year, day.month, day.day, 18),
        venue: 'Zepp Nagoya',
        ticketUrl: url,
        eventId: 'ev',
      ),
    );
    await pumpScreen(
      tester,
      data,
      const EventManageScreen(creatorId: 'minato'),
    );
    await tester.tap(find.text('ツアー').first);
    await tester.pumpAndSettle();
    expect(find.text('イベントの編集'), findsOneWidget);
    expect(find.text('ツアー'), findsOneWidget);
    expect(find.text('Zepp Nagoya'), findsOneWidget);
    // タイトルを変えて保存すると、公演のタイトルも変わる。
    await tester.enterText(find.widgetWithText(TextField, 'ツアー'), 'ツアー 2026');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(data.events['ev']!.title, 'ツアー 2026');
    expect(data.events['ev']!.links.single.isPromotion, isTrue);
    expect(
      data.schedules
          .where((s) => s.eventId == 'ev')
          .map((s) => s.title)
          .toSet(),
      {'ツアー 2026'},
    );

    // もう一度開いて、消す（保存のスナックバーが消えるのを待つ）。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ツアー 2026').first);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('このイベントを消す'));
    await tester.tap(find.text('このイベントを消す'));
    await tester.pumpAndSettle();
    expect(find.text('このイベントを消しますか？'), findsOneWidget);
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(data.events, isEmpty);
    expect(data.schedules.where((s) => s.eventId == 'ev'), isEmpty);
    await unmount(tester);
  });

  group('チケットサイトで探して、イベントの候補から登録する', () {
    const artist = 'https://t.pia.jp/pia/artist/artists.do?artistsCd=A1';
    const tour = 'https://t.pia.jp/pia/event/event.do?eventBundleCd=b2';
    const done = 'https://t.pia.jp/pia/event/event.do?eventBundleCd=b3';
    const nagoya =
        'https://t.pia.jp/pia/ticketInformation.do?eventCd=1234567&rlsCd=002';

    /// ページの JavaScript の結果。候補を拾う JavaScript には、イベントのページ2件を返し、ほかには [html] を返す。
    void answerScripts({String html = '<div>x</div>'}) {
      FakeWebViewPlatform.scriptHandler = (script) =>
          script == EventPageReaderScreen.candidatesScript
          ? jsonEncode(
              jsonEncode([
                {'url': tour, 'text': 'Zepp ツアー 2026'},
                {'url': done, 'text': '武道館 公演'},
              ]),
            )
          : jsonEncode(html);
      addTearDown(() => FakeWebViewPlatform.scriptHandler = null);
    }

    void registeredDone() {
      data.events['old'] = const Event(
        id: 'old',
        creatorId: 'minato',
        title: '武道館',
        links: [EventLink(url: done)],
        performances: [],
      );
    }

    /// 開いたページを、読み込み終えたことにする。
    Future<void> finishPage(WidgetTester tester, String url) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      for (final f in FakeWebViewPlatform.pageFinished) {
        f(url);
      }
      await tester.pump();
      await tester.pump();
    }

    /// アーティストのページを「読み取る」で開き、ページにあるイベントのページへのリンクから選ぶ。
    Future<void> openArtistPage(WidgetTester tester) async {
      FakeWebViewPlatform.loadedUrls.clear();
      FakeWebViewPlatform.pageFinished.clear();
      FakeWebViewPlatform.scripts.clear();
      answerScripts();
      registeredDone();
      await pumpRegister(tester);
      await tester.enterText(find.byType(TextField).first, artist);
      await tester.pump();
      await tester.tap(find.text('読み取る'));
      await finishPage(tester, artist);
      await tester.tap(find.text('このページのイベントから選ぶ（2件）'));
      await tester.pumpAndSettle();
    }

    /// 候補を押して開いたイベントのページで、「このイベントを登録」を押す。
    Future<void> registerCandidate(WidgetTester tester, String text) async {
      FakeWebViewPlatform.pageFinished.clear();
      FakeWebViewPlatform.scripts.clear();
      await tester.tap(find.text(text));
      await finishPage(tester, tour);
      expect(find.byType(EventPageReaderScreen), findsOneWidget);
      // 候補から開いたページでは、さらに候補は拾わない。
      expect(find.textContaining('このページのイベントから選ぶ'), findsNothing);
      await tester.tap(find.text('このイベントを登録'));
      await tester.pumpAndSettle();
    }

    test('チケットサイトを横断して、同じ日の公演を1つにまとめ、サイトごとに公演のページを選ぶ', () {
      final today = DateTime(2026, 10, 27);
      PerformanceEntry e(
        TicketSite site,
        DateTime date,
        String url, {
        String? venue,
        bool perf = true,
        String? title,
      }) => PerformanceEntry(
        site: site,
        date: date,
        url: url,
        perfLevel: perf,
        venue: venue,
        title: title,
      );
      final groups = TicketSearch.group([
        // 同じ公演を、ぴあ（抽選と先着）・イープラス・ローチケが売る。会場名の書き方が違う。
        e(
          TicketSite.pia,
          DateTime(2026, 11, 3),
          'https://t.pia.jp/pia/ticketInformation.do?lotRlsCd=1',
          venue: '国立代々木競技場 第一体育館',
          title: 'ほしぞらバンド',
        ),
        e(
          TicketSite.pia,
          DateTime(2026, 11, 3),
          'https://t.pia.jp/pia/ticketInformation.do?eventCd=1&rlsCd=001',
          venue: '国立代々木競技場 第一体育館',
          title: 'ほしぞらバンド',
        ),
        e(
          TicketSite.eplus,
          DateTime(2026, 11, 3),
          'https://eplus.jp/sf/detail/9900000001',
          perf: false,
          venue: '国立代々木競技場第一体育館',
        ),
        e(
          TicketSite.eplus,
          DateTime(2026, 11, 3),
          'https://eplus.jp/sf/detail/9900000001-P0000001P001001',
        ),
        e(
          TicketSite.lawson,
          DateTime(2026, 11, 3),
          'https://l-tike.com/order/?gLcode=1',
          venue: '国立代々木競技場　第一体育館（東京都）',
        ),
        // 別の日の公演は、別の行。
        e(
          TicketSite.eplus,
          DateTime(2026, 11, 21),
          'https://eplus.jp/sf/detail/9900000001-P0000002P001001',
          venue: '宮城セキスイハイムスーパーアリーナ',
        ),
        // 終わった公演は出さない。
        e(
          TicketSite.pia,
          DateTime(2026, 10, 21),
          'https://t.pia.jp/old',
          venue: '横浜',
        ),
      ], today);
      expect(groups.map((g) => g.date), [
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 21),
      ]);
      final first = groups.first;
      expect(first.tickets.map((t) => t.site), [
        TicketSite.pia,
        TicketSite.lawson,
        TicketSite.eplus,
      ]);
      expect(first.tickets.map((t) => t.url), [
        'https://t.pia.jp/pia/ticketInformation.do?eventCd=1&rlsCd=001',
        'https://l-tike.com/order/?gLcode=1',
        'https://eplus.jp/sf/detail/9900000001-P0000001P001001',
      ]);
      expect(first.eventTitle, 'ほしぞらバンド');
    });

    test('昼夜の公演は開演の時刻で分け、同じ日の別の会場の公演はまとめない', () {
      final today = DateTime(2026, 10, 27);
      final day = DateTime(2026, 11, 3);
      PerformanceEntry e(
        TicketSite site,
        String url, {
        String? venue,
        ({int hour, int minute})? start,
      }) => PerformanceEntry(
        site: site,
        date: day,
        url: url,
        perfLevel: true,
        venue: venue,
        start: start,
      );
      final groups = TicketSearch.group([
        // 昼夜の公演（イープラスは時刻が分かる。ぴあは分からない）。
        e(
          TicketSite.eplus,
          'https://eplus.jp/sf/detail/1-P1',
          venue: 'Zepp Haneda',
          start: (hour: 13, minute: 0),
        ),
        e(
          TicketSite.eplus,
          'https://eplus.jp/sf/detail/1-P2',
          venue: 'Zepp Haneda',
          start: (hour: 18, minute: 0),
        ),
        e(
          TicketSite.pia,
          'https://t.pia.jp/pia/ticketInformation.do?eventCd=1&rlsCd=001',
          venue: 'Zepp Haneda(TOKYO)',
        ),
        // 同じ日の、別の会場（サイトが重ならなくても、まとめない）。
        e(
          TicketSite.lawson,
          'https://l-tike.com/order/?gLcode=9',
          venue: '大阪城ホール',
        ),
      ], today);
      expect(groups.map((g) => (g.venue, g.start)), [
        ('Zepp Haneda', (hour: 13, minute: 0)),
        ('Zepp Haneda', (hour: 18, minute: 0)),
        ('大阪城ホール', null),
      ]);
      // 時刻の分からないぴあは、いちばん早い公演にまとめる。
      expect(groups[0].tickets.map((t) => t.site), [
        TicketSite.pia,
        TicketSite.eplus,
      ]);
      expect(groups[1].tickets.map((t) => t.site), [TicketSite.eplus]);
    });

    test('会場の分からない公演を介して、別の会場の公演をまとめない', () {
      final day = DateTime(2026, 12, 26);
      PerformanceEntry e(
        TicketSite site,
        String url, {
        String? venue,
        ({int hour, int minute})? start,
      }) => PerformanceEntry(
        site: site,
        date: day,
        url: url,
        perfLevel: true,
        venue: venue,
        start: start,
      );
      final groups = TicketSearch.group([
        // フェス（昼）。イープラスの、会場の分からないリンクも同じ公演。
        e(
          TicketSite.eplus,
          'https://eplus.jp/sf/detail/1-P1',
          venue: 'インテックス大阪',
          start: (hour: 11, minute: 0),
        ),
        e(
          TicketSite.eplus,
          'https://eplus.jp/sf/detail/1-P2',
          start: (hour: 11, minute: 0),
        ),
        // ワンマン（夜）。ローチケは時刻が分からない。
        e(
          TicketSite.eplus,
          'https://eplus.jp/sf/detail/2-P1',
          venue: 'クロコくんホール (日本ガイシホール)',
          start: (hour: 17, minute: 0),
        ),
        e(
          TicketSite.lawson,
          'https://l-tike.com/order/?gLcode=1',
          venue: 'クロコくんホール(日本ガイシホール)',
        ),
      ], DateTime(2026, 10, 27));
      expect(groups.map((g) => (g.venue, g.start)), [
        ('インテックス大阪', (hour: 11, minute: 0)),
        ('クロコくんホール (日本ガイシホール)', (hour: 17, minute: 0)),
      ]);
      expect(groups[0].tickets.map((t) => t.site), [TicketSite.eplus]);
      expect(groups[1].tickets.map((t) => t.site), [
        TicketSite.lawson,
        TicketSite.eplus,
      ]);
    });

    test('チケットリンクの URL が変わっても、日付・会場・開演が同じ公演は登録済みとみなす', () {
      ScheduleItem registered({required bool allDay, int hour = 0}) =>
          sampleSchedule(
            'p1',
            'Zepp ツアー',
            DateTime(2026, 11, 3, hour),
            allDay: allDay,
            venue: 'Zepp Haneda(TOKYO)',
            eventId: 'e1',
          );
      PerformanceGroup group({
        String venue = 'Zepp Haneda',
        ({int hour, int minute})? start,
      }) => PerformanceGroup(
        date: DateTime(2026, 11, 3),
        venue: venue,
        start: start,
        tickets: const [
          TicketOption(
            site: TicketSite.pia,
            url:
                'https://t.pia.jp/pia/ticketInformation.do?eventCd=1&rlsCd=002',
            eventTitle: 'Zepp ツアー',
          ),
        ],
      );
      // 時刻未定で登録した公演は、時刻の分からない候補とも、分かる候補とも同じとみなす。
      expect(
        TicketSearch.alreadyRegistered(group(), [registered(allDay: true)]),
        isTrue,
      );
      expect(
        TicketSearch.alreadyRegistered(group(start: (hour: 18, minute: 0)), [
          registered(allDay: true),
        ]),
        isTrue,
      );
      // 開演が違えば（昼夜の公演）、別の公演。
      expect(
        TicketSearch.alreadyRegistered(group(start: (hour: 18, minute: 0)), [
          registered(allDay: false, hour: 13),
        ]),
        isFalse,
      );
      // 会場が違えば、別の公演。
      expect(
        TicketSearch.alreadyRegistered(group(venue: '大阪城ホール'), [
          registered(allDay: true),
        ]),
        isFalse,
      );
    });

    test('アーティストの名前は、括弧の補足と記号を除いて比べる', () {
      bool same(String a, String b) =>
          TicketSearch.nameKey(a) == TicketSearch.nameKey(b);
      expect(same('星街すいせい', '星街すいせい (アイドルVtuber)'), isTrue);
      expect(same('超ときめき♡宣伝部', '超ときめき宣伝部'), isTrue);
      expect(same('Mrs. GREEN APPLE', 'Mrs.GREEN APPLE'), isTrue);
      expect(same('クモくん', 'いつも元気なクモくん'), isFalse);
    });

    test('同じ名前があれば、記号だけが違うアーティストは選ばない', () {
      const ado = ArtistHit(
        site: TicketSite.pia,
        name: 'Ado',
        url: 'https://t.pia.jp/a/1',
      );
      const dotted = ArtistHit(
        site: TicketSite.pia,
        name: 'A.D.O',
        url: 'https://t.pia.jp/a/2',
      );
      expect(TicketSearch.likelyArtists([dotted, ado], 'ado'), [ado]);
      const mrs = ArtistHit(
        site: TicketSite.eplus,
        name: 'Mrs.GREEN APPLE',
        url: 'https://eplus.jp/1',
      );
      expect(TicketSearch.likelyArtists([mrs], 'Mrs. GREEN APPLE'), [mrs]);
    });

    test('シャトルバスなどの券は、公演として拾わない', () {
      final result = jsonEncode({
        'title': '【シャトルバス】Mrs. GREEN APPLE',
        'performances': [
          {
            'date': '2026-11-18',
            'time': null,
            'venue': '長野ビッグハット',
            'url': null,
          },
        ],
      });
      expect(
        TicketSearch.parsePerformances(
          TicketSite.lawson,
          result,
          pageUrl: 'https://l-tike.com/concert/mevent/?mid=1',
        ),
        isEmpty,
      );
    });

    test('会場名の書き方の違いは、似かたで同じ会場とみなす', () {
      expect(
        TicketSearch.venueSimilarity(
          TicketSearch.venueKey('宮城・セキスイハイム スーパーアリーナ'),
          TicketSearch.venueKey('宮城セキスイハイムスーパーアリーナ'),
        ),
        1,
      );
      expect(
        TicketSearch.venueSimilarity(
          TicketSearch.venueKey('Kアリーナ横浜'),
          TicketSearch.venueKey('ぴあアリーナMM'),
        ),
        lessThan(0.4),
      );
    });

    test('会場名は、検索と同じ NFKC でそろえる（結合文字の濁点・囲み文字・ローマ数字）', () {
      // Mac から貼った名前は、濁点が別の字（U+3099）になることがある。
      expect(
        TicketSearch.venueKey('日本カ\u3099イシホール'),
        TicketSearch.venueKey('日本ガイシホール'),
      );
      expect(
        TicketSearch.venueKey('Ⅱホール（東京都）'),
        TicketSearch.venueKey('IIホール'),
      );
    });

    test('全角の英字の会場名（手入力）も、半角のものと同じ会場とみなす', () {
      expect(
        TicketSearch.venueKey('Ｚｅｐｐ　Ｎａｇｏｙａ'),
        TicketSearch.venueKey('Zepp Nagoya'),
      );
      PerformanceGroup g() => PerformanceGroup(
        date: DateTime(2026, 11, 2),
        venue: 'Zepp Nagoya',
        tickets: const [
          TicketOption(site: TicketSite.pia, url: nagoya, eventTitle: 'ツアー'),
        ],
      );
      expect(
        TicketSearch.alreadyRegistered(g(), [
          ScheduleItem(
            id: 's1',
            creatorId: 'minato',
            title: 'ツアー',
            startsAt: DateTime(2026, 11, 2),
            allDay: true,
            venue: 'Ｚｅｐｐ Ｎａｇｏｙａ',
            eventId: 'e1',
          ),
        ]),
        isTrue,
      );
    });

    test('アーティストのページのリンクは、そのサイトのものだけを、そのサイトの解析に渡す', () {
      expect(TicketSearch.onSite(TicketSite.pia, tour), isTrue);
      expect(
        TicketSearch.onSite(TicketSite.pia, 'https://zaiko.io/e/x'),
        isFalse,
      );
      expect(
        TicketSearch.onSite(TicketSite.eplus, 'https://eplus.jp/sf/detail/1'),
        isTrue,
      );
      expect(
        TicketSearch.onSite(TicketSite.lawson, 'https://livepocket.jp/e/x'),
        isFalse,
      );
      expect(
        TicketSearch.onSite(
          TicketSite.rakuten,
          'https://ticket.rakuten.co.jp/music/x/rt1/',
        ),
        isTrue,
      );
      expect(
        TicketSearch.onSite(TicketSite.rakuten, 'https://tiget.net/events/1'),
        isFalse,
      );
    });

    testWidgets('名前で探すと、4つのサイトのアーティストを、サイトの名前つきで並べる', (tester) async {
      FakeWebViewPlatform.loadedUrls.clear();
      FakeWebViewPlatform.pageFinished.clear();
      FakeWebViewPlatform.scriptHandler = (script) {
        // 3つのサイトを同時に開くので、どのサイトかは、走らせた JavaScript（サイトごとに違う）で見分ける。
        final page = script == TicketSearch.artistsScript(TicketSite.pia)
            ? 't.pia.jp'
            : script == TicketSearch.artistsScript(TicketSite.eplus)
            ? 'eplus.jp'
            : '';
        return jsonEncode(
          jsonEncode(switch (page) {
            't.pia.jp' => [
              {
                'name': '星野ミナト',
                'url': 'https://t.pia.jp/pia/artist/artists.do?artistsCd=M1',
              },
            ],
            'eplus.jp' => [
              {'name': '星野ミナト', 'url': 'https://eplus.jp/sf/word/1'},
              {'name': '星野ミナト (バンド)', 'url': 'https://eplus.jp/sf/word/2'},
            ],
            _ => <Object>[],
          }),
        );
      };
      addTearDown(() => FakeWebViewPlatform.scriptHandler = null);
      await pumpRegister(tester);
      await tester.tap(find.text('チケットサイトで探す'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('探す'));
      for (var i = 0; i < 4; i++) {
        await tester.pump();
        for (final f in [...FakeWebViewPlatform.pageFinished]) {
          f('');
        }
      }
      await tester.pumpAndSettle();
      expect(FakeWebViewPlatform.loadedUrls.map((u) => u.host).toSet(), {
        't.pia.jp',
        'eplus.jp',
        'l-tike.com',
        'ticket.rakuten.co.jp',
      });
      // 楽天チケットは、一覧の下の方（画面の外）にある。
      await tester.scrollUntilVisible(
        find.text('楽天チケット'),
        200,
        scrollable: find
            .ancestor(
              of: find.text('ローチケ').first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('楽天チケット'), findsWidgets);
      expect(find.text('チケットぴあ'), findsWidgets);
      expect(find.text('イープラス'), findsWidgets);
      expect(find.text('ローチケ'), findsWidgets);
      // ローチケと楽天チケットは、ヒットなし。
      expect(find.text('アーティストが見つかりませんでした'), findsNWidgets(2));
      // 名前が同じアーティストは、はじめから選んである（ぴあとイープラスの2人）。
      expect(find.text('公演を見る（2件）'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('ページにあるイベントのページへのリンクを候補に並べ、登録済みのものには印をつける', (tester) async {
      await openArtistPage(tester);
      expect(find.byType(EventCandidatesScreen), findsOneWidget);
      expect(find.text('Zepp ツアー 2026'), findsOneWidget);
      expect(find.text('武道館 公演'), findsOneWidget);
      expect(find.text('チケットぴあ'), findsNWidgets(2));
      expect(find.text('登録済み'), findsOneWidget);
      // リンクは拾うだけで、たどらない（開いたのはアーティストのページだけ）。
      expect(FakeWebViewPlatform.loadedUrls, [Uri.parse(artist)]);
      await unmount(tester);
    });

    testWidgets('イベントのページを開いて「このイベントを登録」を押すと、公演のページの URL ごと登録する', (
      tester,
    ) async {
      data.eventDrafts[tour] = EventDraft(
        title: 'Zepp ツアー',
        performances: [
          PerformanceDraft(
            date: DateTime(2026, 11, 2),
            start: (hour: 19, minute: 0),
            venue: 'Zepp Nagoya',
            url: nagoya,
          ),
        ],
      );
      await openArtistPage(tester);
      await registerCandidate(tester, 'Zepp ツアー 2026');
      expect(FakeWebViewPlatform.scripts, [
        EventPageReaderScreen.extractScript,
      ]);
      expect(data.eventUrlReads, [tour]);
      final event = data.events.values.singleWhere((e) => e.id != 'old');
      expect(event.title, 'Zepp ツアー');
      // リンクは、公演のページ（同じツアーのほかの公演も、別のイベントとして登録できる）。
      expect(event.links.map((l) => l.url), [nagoya]);
      final performance = data.schedules.single;
      expect(performance.venue, 'Zepp Nagoya');
      expect(performance.performanceUrl, nagoya);
      expect(performance.allDay, isFalse);
      expect(find.text('イベントを登録しました'), findsOneWidget);
      expect(find.byType(EventCandidatesScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('ページに公演が複数あれば、1つ選んで登録する。選ばなければ登録しない', (tester) async {
      data.eventDrafts[tour] = EventDraft(
        title: 'Zepp ツアー',
        performances: [
          PerformanceDraft(
            date: DateTime(2026, 11, 2),
            start: (hour: 19, minute: 0),
            venue: 'Zepp Nagoya',
            url: nagoya,
          ),
          PerformanceDraft(
            date: DateTime(2026, 11, 12),
            start: (hour: 19, minute: 0),
            venue: 'Zepp Haneda',
          ),
        ],
      );
      await openArtistPage(tester);
      await registerCandidate(tester, 'Zepp ツアー 2026');
      expect(find.text('公演を選ぶ'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(data.schedules, isEmpty);

      await registerCandidate(tester, 'Zepp ツアー 2026');
      await tester.tap(find.text('Zepp Haneda'));
      await tester.pumpAndSettle();
      final performance = data.schedules.single;
      expect(performance.venue, 'Zepp Haneda');
      expect(performance.startsAt, DateTime(2026, 11, 12, 19));
      // 公演のページの URL がなければ、リンクは候補のページ。
      final event = data.events.values.singleWhere((e) => e.id != 'old');
      expect(event.links.map((l) => l.url), [tour]);
      expect(find.text('登録済み'), findsNWidgets(2));
      await unmount(tester);
    });

    testWidgets('開演の時刻が読み取れない公演は、時刻未定で登録する', (tester) async {
      data.eventDrafts[tour] = EventDraft(
        title: 'Zepp ツアー',
        performances: [
          PerformanceDraft(
            date: DateTime(2026, 11, 2),
            venue: 'Zepp Nagoya',
            url: nagoya,
          ),
        ],
      );
      await openArtistPage(tester);
      await registerCandidate(tester, 'Zepp ツアー 2026');
      final performance = data.schedules.single;
      expect(performance.allDay, isTrue);
      expect(performance.timeTbd, isTrue);
      expect(performance.performanceUrl, nagoya);
      expect(find.text('イベントを登録しました。時刻未定の公演は、編集で時刻を足せます'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('タイトルが読み取れなければ、読み取った内容を入れた登録の画面を開く', (tester) async {
      data.eventDrafts[tour] = EventDraft(
        title: null,
        performances: [
          PerformanceDraft(date: DateTime(2026, 11, 2), venue: 'Zepp Nagoya'),
        ],
      );
      await openArtistPage(tester);
      await registerCandidate(tester, 'Zepp ツアー 2026');
      expect(data.events.keys, ['old']);
      expect(find.byType(EventRegisterScreen), findsOneWidget);
      expect(find.text('Zepp Nagoya'), findsOneWidget);
      // リンクには、候補の URL が入っている。
      expect(find.text(tour), findsWidgets);
      await unmount(tester);
    });

    testWidgets('タイトルが200字を超えるときも、保存せずに登録の画面を開く', (tester) async {
      data.eventDrafts[tour] = EventDraft(
        title: 'あ' * 201,
        performances: [
          PerformanceDraft(
            date: DateTime(2026, 11, 2),
            start: (hour: 19, minute: 0),
            venue: 'Zepp Nagoya',
          ),
        ],
      );
      await openArtistPage(tester);
      await registerCandidate(tester, 'Zepp ツアー 2026');
      expect(data.events.keys, ['old']);
      expect(find.byType(EventRegisterScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('時刻未定の公演は、編集で「ページから時刻を読む」から時刻を足せる', (tester) async {
      data.ownedCreatorId = 'minato';
      data.events['e1'] = const Event(
        id: 'e1',
        creatorId: 'minato',
        title: 'Zepp ツアー',
        links: [EventLink(url: tour)],
        performances: [],
      );
      data.schedules.add(
        sampleSchedule(
          'p1',
          'Zepp ツアー',
          DateTime(2026, 11, 2),
          allDay: true,
          venue: 'Zepp Nagoya',
          ticketUrl: nagoya,
          eventId: 'e1',
          performanceUrl: nagoya,
        ),
      );
      data.eventDrafts[nagoya] = EventDraft(
        title: 'クモくん 先着先行',
        performances: [
          PerformanceDraft(
            date: DateTime(2026, 11, 2),
            start: (hour: 19, minute: 0),
            venue: 'Zepp Nagoya',
          ),
        ],
      );
      await pumpScreen(
        tester,
        data,
        const EventRegisterScreen(creatorId: 'minato', eventId: 'e1'),
      );
      await scrollTo(tester, find.text('ページから時刻を読む'));
      expect(find.text('時刻未定'), findsOneWidget);
      FakeWebViewPlatform.loadedUrls.clear();
      FakeWebViewPlatform.pageFinished.clear();
      answerScripts(html: '<div>2026/11/2(月) 19:00 開演</div>');
      await tester.tap(find.text('ページから時刻を読む'));
      await finishPage(tester, nagoya);
      expect(FakeWebViewPlatform.loadedUrls, [Uri.parse(nagoya)]);
      await tester.tap(find.text('このページから時刻を読む'));
      await tester.pumpAndSettle();
      expect(find.text('時刻を読み取りました'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
      // 公演のほかの項目は、そのまま。
      expect(find.text('Zepp Nagoya'), findsOneWidget);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      final saved = data.schedules.single;
      expect(saved.allDay, isFalse);
      expect(saved.startsAt, DateTime(2026, 11, 2, 19));
      expect(saved.performanceUrl, nagoya);
      await unmount(tester);
    });
  });
}
