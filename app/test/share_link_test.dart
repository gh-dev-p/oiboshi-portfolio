import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/share_link.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';
import 'package:oiboshi/ui/core/ui/qr_code_view.dart';
import 'package:oiboshi/ui/share/view_models/share_link_viewmodel.dart';
import 'package:oiboshi/ui/share/widgets/share_link_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  group('共有のリンクの形（届ける・広める仕様書 4.3.1）', () {
    test('発信者の共有のリンクを作る', () {
      expect(
        ShareLink.forCreator('minato').toString(),
        'https://oiboshi.perrii.app/c/minato',
      );
    });

    test('共有のリンクと、アプリで開くのリンクから、発信者 ID を読む', () {
      String? read(String url) => ShareLink.creatorIdFrom(Uri.parse(url));
      expect(read('https://oiboshi.perrii.app/c/minato'), 'minato');
      expect(read('https://oiboshi.perrii.app/c/minato/'), 'minato');
      expect(read('https://oiboshi.perrii.app/c/a_b-1?utm=x'), 'a_b-1');
      expect(read('oiboshi://c/minato'), 'minato');
      expect(read('oiboshi-dev://c/minato'), 'minato');
    });

    test('ほかの URL・形の違う ID は読まない', () {
      String? read(String url) => ShareLink.creatorIdFrom(Uri.parse(url));
      expect(read('http://oiboshi.perrii.app/c/minato'), isNull);
      expect(read('https://example.com/c/minato'), isNull);
      expect(read('https://oiboshi.perrii.app/privacy'), isNull);
      expect(read('https://oiboshi.perrii.app/c/'), isNull);
      expect(read('https://oiboshi.perrii.app/c/minato/x'), isNull);
      expect(read('https://oiboshi.perrii.app/c/Minato'), isNull);
      expect(read('https://oiboshi.perrii.app/c/${'a' * 41}'), isNull);
      expect(read('oiboshi://x/minato'), isNull);
      expect(read('other://c/minato'), isNull);
    });

    test('誘う用のリンク（4.3.6）は、?invite=1 を付け、読むときに見分ける', () {
      expect(
        ShareLink.forCreator('minato', invite: true).toString(),
        'https://oiboshi.perrii.app/c/minato?invite=1',
      );
      expect(
        ShareLink.fromText('https://oiboshi.perrii.app/c/minato?invite=1'),
        (creatorId: 'minato', invite: true),
      );
      expect(ShareLink.fromText('https://oiboshi.perrii.app/c/minato'), (
        creatorId: 'minato',
        invite: false,
      ));
      expect(
        ShareLink.fromText('https://oiboshi.perrii.app/c/minato?invite=0'),
        (creatorId: 'minato', invite: false),
      );
    });

    test('文字列（クリップボードの中身）から読む', () {
      expect(
        ShareLink.creatorIdFromText('  https://oiboshi.perrii.app/c/minato\n'),
        'minato',
      );
      expect(ShareLink.creatorIdFromText('こんにちは'), isNull);
      expect(ShareLink.creatorIdFromText(''), isNull);
      expect(ShareLink.creatorIdFromText(null), isNull);
    });
  });

  group('リンクの共有（4.3.2）', () {
    late FakeData data;
    late FakeShareSheetService sheet;

    setUp(() {
      data = FakeData()..creators.add(sampleCreator());
      sheet = FakeShareSheetService();
    });

    test('ファンに見せる発信者なら、誘う用のリンクを入れた文を共有シートに渡す', () async {
      final container = await testContainer(data, shareSheet: sheet);
      final outcome = await container
          .read(shareLinkViewModelProvider.notifier)
          .share('minato', message: (link) => '星野ミナト $link');
      expect(outcome, ShareLinkOutcome.opened);
      expect(sheet.shared, [
        '星野ミナト https://oiboshi.perrii.app/c/minato?invite=1',
      ]);
    });

    test('ファンに見せない発信者なら、共有しない', () async {
      data.unshareableCreatorIds.add('minato');
      final container = await testContainer(data, shareSheet: sheet);
      final outcome = await container
          .read(shareLinkViewModelProvider.notifier)
          .share('minato', message: (link) => '$link');
      expect(outcome, ShareLinkOutcome.unavailable);
      expect(sheet.shared, isEmpty);
    });

    test('QR を PNG の画像にして共有シートに渡す', () async {
      final container = await testContainer(data, shareSheet: sheet);
      final outcome = await container
          .read(shareLinkViewModelProvider.notifier)
          .shareQrImage('minato');
      expect(outcome, ShareLinkOutcome.opened);
      expect(sheet.sharedImages, ['oiboshi-minato-qr.png']);
      final png = await qrPng('https://oiboshi.perrii.app/c/minato');
      // PNG の印（先頭の8バイト）。
      expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    });

    test('確かめられない・共有シートを開けないなら、失敗を返す', () async {
      sheet.fail = true;
      final container = await testContainer(data, shareSheet: sheet);
      final outcome = await container
          .read(shareLinkViewModelProvider.notifier)
          .share('minato', message: (link) => '$link');
      expect(outcome, ShareLinkOutcome.failed);
    });
  });

  group('リンクから開く（4.3.3）', () {
    late FakeData data;
    late FakeAppLinkService links;

    setUp(() {
      data = FakeData()
        ..creators.add(sampleCreator())
        ..posts.add(samplePost())
        ..onboardingDone = true;
      links = FakeAppLinkService();
    });

    Future<void> pumpHome(WidgetTester tester) =>
        pumpScreen(tester, data, const HomeShell(), links: links);

    testWidgets('共有のリンクで開いたら、発信者ページを開く', (tester) async {
      await pumpHome(tester);
      expect(find.byType(CreatorScreen), findsNothing);
      links.open('https://oiboshi.perrii.app/c/minato');
      await tester.pumpAndSettle();
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('アプリで開くのリンク（oiboshi://）でも開く', (tester) async {
      await pumpHome(tester);
      links.open('oiboshi://c/minato');
      await tester.pumpAndSettle();
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('発信者がない・ファンに見せないなら、ホームで知らせる', (tester) async {
      data.unshareableCreatorIds.add('minato');
      await pumpHome(tester);
      links.open('https://oiboshi.perrii.app/c/minato');
      await tester.pumpAndSettle();
      expect(find.byType(CreatorScreen), findsNothing);
      expect(find.text('リンクの発信者が見つかりませんでした'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('ほかの URL では何もしない', (tester) async {
      await pumpHome(tester);
      links.open('https://example.com/c/minato');
      await tester.pumpAndSettle();
      expect(find.byType(CreatorScreen), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      await unmount(tester);
    });
  });

  group('「リンクを共有」の画面（4.3.2・4.3.5）', () {
    late FakeData data;
    late FakeShareSheetService sheet;

    setUp(() {
      data = FakeData()..creators.add(sampleCreator());
      sheet = FakeShareSheetService();
    });

    Future<void> pumpShare(WidgetTester tester) => pumpScreen(
      tester,
      data,
      const ShareLinkScreen(creatorId: 'minato'),
      shareSheet: sheet,
    );

    testWidgets('名前・ID・QR・誘う用のリンクを出し、ファンの文で共有シートに渡す', (tester) async {
      await pumpShare(tester);
      expect(find.text('星野ミナト'), findsOneWidget);
      expect(find.text('@minato'), findsOneWidget);
      expect(find.byType(QrCodeView), findsOneWidget);
      expect(
        find.text('https://oiboshi.perrii.app/c/minato?invite=1'),
        findsOneWidget,
      );
      await tester.tap(find.text('リンクを共有する'));
      await tester.pumpAndSettle();
      expect(
        sheet.shared.single,
        '星野ミナトの配信と予定を、追星で追えます\nhttps://oiboshi.perrii.app/c/minato?invite=1',
      );
      await unmount(tester);
    });

    testWidgets('「追星に誘う」は、誘う用のリンクと誘う文を渡す（4.3.6）', (tester) async {
      await pumpScreen(
        tester,
        data,
        const ShareLinkScreen(creatorId: 'minato', asCreator: true),
        shareSheet: sheet,
      );
      expect(find.text('追星に誘う'), findsOneWidget);
      expect(
        find.text('https://oiboshi.perrii.app/c/minato?invite=1'),
        findsOneWidget,
      );
      expect(
        find.textContaining('フォローした状態で始まります', skipOffstage: false),
        findsOneWidget,
      );
      await tester.tap(find.text('リンクを共有する'));
      await tester.pumpAndSettle();
      expect(
        sheet.shared.single,
        '追星で私の配信・予定を追いかけてね\nhttps://oiboshi.perrii.app/c/minato?invite=1',
      );
      await unmount(tester);
    });

    testWidgets('リンクを押すと写し、知らせる', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      await pumpShare(tester);
      await tester.tap(
        find.text('https://oiboshi.perrii.app/c/minato?invite=1'),
      );
      await tester.pumpAndSettle();
      expect(copied, 'https://oiboshi.perrii.app/c/minato?invite=1');
      expect(find.text('リンクをコピーしました'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('ファンに見せない状態なら、理由を出して共有させない', (tester) async {
      data.unshareableCreatorIds.add('minato');
      await pumpShare(tester);
      expect(find.text('まだ共有できません'), findsOneWidget);
      expect(find.text('リンクを共有する'), findsNothing);
      await unmount(tester);
    });
  });
}
