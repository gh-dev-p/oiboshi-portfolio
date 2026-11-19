import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/announce_template.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/l10n/app_localizations.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/creator_admin/view_models/announce_image_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/widgets/announce_image_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

/// 週間の告知画像（届ける・広める仕様書 4.4.1）。
void main() {
  group('週の区切り（月曜から日曜）', () {
    test('今週は、その週の月曜 0 時から', () {
      // 2026-11-18 は水曜。
      expect(
        announceWeekStart(DateTime(2026, 11, 18, 15), AnnounceWeek.thisWeek),
        DateTime(2026, 11, 16),
      );
      // 日曜は、前の月曜からの週。
      expect(
        announceWeekStart(DateTime(2026, 11, 22, 23), AnnounceWeek.thisWeek),
        DateTime(2026, 11, 16),
      );
      // 月曜はその日から。
      expect(
        announceWeekStart(DateTime(2026, 11, 16), AnnounceWeek.thisWeek),
        DateTime(2026, 11, 16),
      );
    });

    test('来週は、次の月曜から（月をまたいでも）', () {
      expect(
        announceWeekStart(DateTime(2026, 11, 26), AnnounceWeek.nextWeek),
        DateTime(2026, 11, 30),
      );
      expect(
        announceWeekStart(DateTime(2026, 12, 31), AnnounceWeek.nextWeek),
        DateTime(2027, 1, 4),
      );
    });
  });

  group('一緒に共有する文', () {
    final l10n = lookupAppLocalizations(const Locale('ja'));
    final monday = DateTime(2026, 11, 16);
    AnnounceData dataWith(List<ScheduleItem> items) =>
        AnnounceData(creator: sampleCreator(), weekStart: monday, items: items);

    test('予定ごとにリンクの行を作り、最後に誘う用のリンクを置く', () {
      final text = announceShareText(
        dataWith([
          sampleSchedule(
            'y1',
            '雑談の予約',
            monday.add(const Duration(hours: 20)),
            service: SnsService.youtube,
            fetched: true,
            externalId: 'abc123',
          ),
          // リンクの無い予定は入れない（ミナトは Twitch をつないでいない）。
          sampleSchedule(
            't1',
            'Twitch の配信',
            monday.add(const Duration(days: 1, hours: 21)),
            service: SnsService.twitch,
            fetched: true,
          ),
          sampleSchedule(
            'e1',
            'とても長い名前のワンマンライブ2026冬ツアー東京公演',
            monday.add(const Duration(days: 5, hours: 18)),
            eventId: 'ev1',
            ticketUrl: 'https://ticket.example/1',
          ),
          // 広告のリンクは使わず、公演のページにする。
          sampleSchedule(
            'e2',
            'ファンミーティング',
            monday.add(const Duration(days: 6, hours: 13)),
            eventId: 'ev2',
            ticketUrl: 'https://ad.example/1',
            ticketIsPromotion: true,
            performanceUrl: 'https://info.example/2',
          ),
        ]),
        l10n,
        maxWeight: 1000,
      );
      expect(
        text,
        '星野ミナトの週間の予定（11/16–11/22）\n'
        '11/16(月) 20:00 雑談の予約 https://youtu.be/abc123\n'
        '11/21(土) 18:00 とても長い名前のワンマンライブ2026冬ツアー… https://ticket.example/1\n'
        '11/22(日) 13:00 ファンミーティング https://info.example/2\n'
        '\n'
        '▼追星で通知を受け取る\n'
        'https://oiboshi.perrii.app/c/minato?invite=1',
      );
    });

    test('同じリンクは2回目から付けない（チャンネルのページなど）', () {
      final text = announceShareText(
        dataWith([
          for (var d = 0; d < 2; d++)
            sampleSchedule(
              'y$d',
              '配信$d',
              monday.add(Duration(days: d, hours: 20)),
              service: SnsService.youtube,
            ),
        ]),
        l10n,
      );
      expect(text, contains('配信0 https://www.youtube.com/channel/UC123\n'));
      expect(text, contains('11/17(火) 20:00 配信1\n'));
    });

    test('X の長さに入りきらない予定は「ほか N 件」にまとめ、誘う用のリンクは残す', () {
      final text = announceShareText(
        dataWith([
          for (var i = 0; i < 14; i++)
            sampleSchedule(
              'e$i',
              '公演$i',
              monday.add(Duration(days: i ~/ 2, hours: 12 + i % 2)),
              eventId: 'ev$i',
              ticketUrl: 'https://ticket.example/$i',
            ),
        ]),
        l10n,
      );
      expect(xWeight(text), lessThanOrEqualTo(announceTextMaxWeight));
      expect(text, matches(RegExp(r'ほか \d+ 件\n')));
      expect(text, endsWith('https://oiboshi.perrii.app/c/minato?invite=1'));
    });

    test('短い URL があれば、予定のリンクも誘う用のリンクも短い URL にする（4.4.2）', () {
      final data = AnnounceData(
        creator: sampleCreator(),
        weekStart: monday,
        items: [
          sampleSchedule(
            'y1',
            '雑談の予約',
            monday.add(const Duration(hours: 20)),
            service: SnsService.youtube,
            fetched: true,
            externalId: 'abc123',
          ),
        ],
        shortUrls: const {
          'https://youtu.be/abc123':
              'https://oiboshi.perrii.app/s/AAAAAAAAAAAA',
          'https://oiboshi.perrii.app/c/minato?invite=1':
              'https://oiboshi.perrii.app/s/BBBBBBBBBBBB',
        },
      );
      expect(data.shareLinks, [
        'https://youtu.be/abc123',
        'https://oiboshi.perrii.app/c/minato?invite=1',
      ]);
      final text = announceShareText(data, l10n);
      expect(
        text,
        contains('雑談の予約 https://oiboshi.perrii.app/s/AAAAAAAAAAAA\n'),
      );
      expect(text, endsWith('https://oiboshi.perrii.app/s/BBBBBBBBBBBB'));
      expect(text, isNot(contains('youtu.be')));
    });

    test('X の数え方：全角は2、URL は23', () {
      expect(xWeight('abc'), 3);
      expect(xWeight('あいう'), 6);
      expect(xWeight('見て https://example.com/very/long/path'), 4 + 1 + 23);
    });
  });

  group('画面', () {
    late FakeData data;
    late FakeShareSheetService sheet;

    setUp(() {
      data = FakeData()..creators.add(sampleCreator());
      sheet = FakeShareSheetService();
    });

    // 画面の部品が全部組み立てられるよう、縦に長い画面にする。
    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Future<void> pumpAnnounce(WidgetTester tester) {
      tall(tester);
      return pumpScreen(
        tester,
        data,
        const AnnounceImageScreen(creatorId: 'minato'),
        shareSheet: sheet,
      );
    }

    testWidgets('サーバーが作った画像を出し、週を変えると作り直す', (tester) async {
      await pumpAnnounce(tester);
      expect(find.byType(Image), findsWidgets);
      expect(data.announceRenders, hasLength(1));
      final first = data.announceRenders.single;
      expect(first.creatorId, 'minato');
      expect(first.templateId, 'spotlight');
      expect(
        first.weekStart,
        announceWeekStart(DateTime.now(), AnnounceWeek.thisWeek),
      );
      // テンプレが1つでも並びを出す（2026-11-19 本人）。
      expect(find.text('スポットライト'), findsOneWidget);

      await tester.tap(find.text('来週'));
      await tester.pumpAndSettle();
      expect(
        data.announceRenders.last.weekStart,
        announceWeekStart(DateTime.now(), AnnounceWeek.nextWeek),
      );
      await unmount(tester);
    });

    testWidgets('テンプレを押すと作り直し、選んだものを覚える', (tester) async {
      data.announceTemplates = [
        ...data.announceTemplates,
        const AnnounceTemplate(
          id: 'pastel',
          name: 'パステル',
          thumbnailUrl: 'https://f.example/thumbnail/pastel',
        ),
      ];
      await pumpAnnounce(tester);
      await tester.tap(find.text('パステル'));
      await tester.pumpAndSettle();
      expect(data.announceRenders.last.templateId, 'pastel');
      await unmount(tester);

      // 選んだものを端末に覚える（次に開いたときに使う）。
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('announceTemplate'), 'pastel');
    });

    test('使うテンプレ：覚えたものが一覧にあればそれ、無ければ既定', () {
      const a = AnnounceTemplate(id: 'a', name: 'A', thumbnailUrl: 'u');
      const b = AnnounceTemplate(
        id: 'b',
        name: 'B',
        thumbnailUrl: 'u',
        isDefault: true,
      );
      expect(announceTemplateIdFor('a', [a, b]), 'a');
      expect(announceTemplateIdFor('gone', [a, b]), 'b');
      expect(announceTemplateIdFor(null, [a, b]), 'b');
      expect(announceTemplateIdFor('a', []), 'spotlight');
    });

    testWidgets('作っている間は、回る印と「画像を作っています」。作り直すときは前の画像を薄くする', (tester) async {
      data.announceRenderGate = Completer<void>();
      // 回る印は止まらないので、pumpAndSettle を使わずに数コマ進める。
      tall(tester);
      await tester.pumpWidget(
        await testApp(data, const AnnounceImageScreen(creatorId: 'minato')),
      );
      for (var k = 0; k < 5; k++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('画像を作っています'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      data.announceRenderGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('画像を作っています'), findsNothing);

      // 週を変えて作り直す間は、前の画像を薄くして、その上に出す。
      data.announceRenderGate = Completer<void>();
      await tester.tap(find.text('来週'));
      await tester.pump();
      expect(find.text('画像を作っています'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1),
        findsOneWidget,
      );
      data.announceRenderGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('画像を作っています'), findsNothing);
      await unmount(tester);
    });

    testWidgets('テンプレの一覧が取れなくても、既定のテンプレで作る', (tester) async {
      data.announceTemplatesFail = true;
      await pumpAnnounce(tester);
      expect(find.text('スポットライト'), findsNothing);
      expect(data.announceRenders.single.templateId, 'spotlight');
      await unmount(tester);
    });

    testWidgets('画像を作れなければ「再試行」を出し、共有は押せない', (tester) async {
      data.announceRenderFail = true;
      await pumpAnnounce(tester);
      expect(find.text('画像を作れませんでした'), findsOneWidget);
      final share = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, '画像とリンクを共有'),
      );
      expect(share.onPressed, isNull);

      data.announceRenderFail = false;
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();
      expect(find.text('画像を作れませんでした'), findsNothing);
      await unmount(tester);
    });

    testWidgets('画像を変えると、その画像で作り直す。アイコンに戻せる', (tester) async {
      final picker = FakeImagePickerService(picked: Uint8List(10));
      tall(tester);
      await pumpScreen(
        tester,
        data,
        const AnnounceImageScreen(creatorId: 'minato'),
        shareSheet: sheet,
        picker: picker,
      );
      expect(find.text('アイコンに戻す'), findsNothing);
      await tester.tap(find.text('画像を変える'));
      await tester.pumpAndSettle();
      expect(picker.picks, 1);
      expect(data.announcePhotos['minato'], isNotNull);
      expect(data.announceRenders.last.photo, data.announcePhotos['minato']);

      await tester.tap(find.text('アイコンに戻す'));
      await tester.pumpAndSettle();
      expect(data.announcePhotos, isEmpty);
      expect(data.announceRenders.last.photo, isNull);
      expect(find.text('アイコンに戻す'), findsNothing);
      await unmount(tester);
    });

    testWidgets('写真を選ばなければ何もしない。上げられなければ知らせる', (tester) async {
      final picker = FakeImagePickerService();
      tall(tester);
      await pumpScreen(
        tester,
        data,
        const AnnounceImageScreen(creatorId: 'minato'),
        picker: picker,
      );
      await tester.tap(find.text('画像を変える'));
      await tester.pumpAndSettle();
      expect(data.announcePhotos, isEmpty);

      picker.picked = Uint8List(10);
      data.announcePhotoFail = true;
      await tester.tap(find.text('画像を変える'));
      await tester.pumpAndSettle();
      expect(find.text('画像を変えられませんでした'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('共有では、サーバーが作った画像と文を渡す', (tester) async {
      await pumpAnnounce(tester);
      await tester.tap(find.text('画像とリンクを共有'));
      await tester.pumpAndSettle();
      expect(sheet.sharedImages, hasLength(1));
      expect(sheet.sharedImageTexts.single, contains('星野ミナトの週間の予定'));
      await unmount(tester);
    });

    testWidgets('一緒に共有する文の見本と、コピーのボタンを出す', (tester) async {
      await pumpAnnounce(tester);
      await tester.scrollUntilVisible(
        find.text('文をコピー'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('画像とリンクを共有'), findsOneWidget);
      // 誘う用のリンクは、追星の短い URL にする（4.4.2）。
      expect(
        find.textContaining(
          'https://oiboshi.perrii.app/s/${data.shortLinkIds['https://oiboshi.perrii.app/c/minato?invite=1']}',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('?invite=1'), findsNothing);
      await unmount(tester);
    });

    testWidgets('文のリンクが押された数を出す（4.4.2）', (tester) async {
      final monday = announceWeekStart(DateTime.now(), AnnounceWeek.thisWeek);
      data.schedules.add(
        sampleSchedule(
          'y1',
          '雑談の予約',
          monday.add(const Duration(hours: 20)),
          service: SnsService.youtube,
          fetched: true,
          externalId: 'abc123',
        ),
      );
      data.shortLinkClicks['https://youtu.be/abc123'] = 3;
      data.shortLinkClicks['https://oiboshi.perrii.app/c/minato?invite=1'] = 12;
      await pumpAnnounce(tester);
      expect(find.text('リンクが押された数'), findsOneWidget);
      expect(find.textContaining('雑談の予約'), findsWidgets);
      expect(find.text('3回'), findsOneWidget);
      expect(find.text('追星に誘うリンク'), findsOneWidget);
      expect(find.text('12回'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('短い URL を作れなくても、元の URL で文を出す', (tester) async {
      data.shortLinksFail = true;
      await pumpAnnounce(tester);
      await tester.scrollUntilVisible(
        find.text('文をコピー'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('https://oiboshi.perrii.app/c/minato?invite=1'),
        findsOneWidget,
      );
      // 押された数は、読めなければ出さない。
      expect(find.text('リンクが押された数'), findsNothing);
      await unmount(tester);
    });
  });

  test('画像と文を共有シートに渡す（ファイル名に週の月曜の日付）', () async {
    final data = FakeData()..creators.add(sampleCreator());
    final sheet = FakeShareSheetService();
    final container = await testContainer(data, shareSheet: sheet);
    final ok = await container
        .read(announceImageViewModelProvider.notifier)
        .share(
          Uint8List(0),
          creatorId: 'minato',
          weekStart: DateTime(2026, 11, 16),
          text: '今週の予定',
        );
    expect(ok, isTrue);
    expect(sheet.sharedImages, ['oiboshi-minato-week-20261116.png']);
    expect(sheet.sharedImageTexts, ['今週の予定']);
  });
}
