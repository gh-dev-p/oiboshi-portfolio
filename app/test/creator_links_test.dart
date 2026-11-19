import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator_link.dart';
import 'package:oiboshi/domain/models/report.dart';
import 'package:oiboshi/domain/models/share_link.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/core/ui/sns_style.dart';
import 'package:oiboshi/ui/creator/widgets/creator_link_buttons.dart';
import 'package:oiboshi/ui/creator_admin/widgets/creator_links_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

/// リンク集（届ける・広める仕様書 4.6、画面定義書（設定・発信者）2.3.17・2.3.18、（ファン向け）2.4.1）。
void main() {
  group('決まり', () {
    test('題名は、前後の空白を除いて1〜30文字（見た目の1文字）', () {
      expect(CreatorLinkRules.isValidTitle('ファンクラブ'), isTrue);
      expect(CreatorLinkRules.isValidTitle('  '), isFalse);
      expect(CreatorLinkRules.isValidTitle('あ' * 30), isTrue);
      expect(CreatorLinkRules.isValidTitle('あ' * 31), isFalse);
      expect(CreatorLinkRules.isValidTitle('👨‍👩‍👧' * 30), isTrue);
    });

    test('URL は https とホストがあるものだけ', () {
      expect(CreatorLinkRules.isValidUrl('https://fc.example.com/'), isTrue);
      expect(CreatorLinkRules.isValidUrl(' https://a.example.com '), isTrue);
      expect(CreatorLinkRules.isValidUrl('http://a.example.com/'), isFalse);
      expect(CreatorLinkRules.isValidUrl('https://'), isFalse);
      expect(CreatorLinkRules.isValidUrl('javascript:alert(1)'), isFalse);
      expect(
        CreatorLinkRules.isValidUrl('https://a.example.com/${'a' * 2000}'),
        isFalse,
      );
    });

    test('誘う用のリンクを見分ける', () {
      expect(
        ShareLink.isInviteLinkFor(
          'minato',
          'https://oiboshi.perrii.app/c/minato?invite=1',
        ),
        isTrue,
      );
      expect(
        ShareLink.isInviteLinkFor(
          'minato',
          'https://oiboshi.perrii.app/c/minato',
        ),
        isFalse,
      );
      expect(
        ShareLink.isInviteLinkFor(
          'minato',
          'https://oiboshi.perrii.app/c/other?invite=1',
        ),
        isFalse,
      );
      expect(
        ShareLink.isInviteLinkFor(
          'minato',
          'https://evil.example.com/c/minato?invite=1',
        ),
        isFalse,
      );
    });

    test('つないだ SNS のアカウントのページを指すリンクを見分ける', () {
      const accounts = {SnsService.x: 'Minato_X', SnsService.youtube: 'UCabc'};
      expect(
        CreatorLinkRules.isSnsProfileLink(accounts, 'https://x.com/Minato_X'),
        isTrue,
      );
      expect(
        CreatorLinkRules.isSnsProfileLink(accounts, 'https://x.com/minato_x/'),
        isTrue,
      );
      expect(
        CreatorLinkRules.isSnsProfileLink(
          accounts,
          'https://www.youtube.com/channel/UCabc',
        ),
        isTrue,
      );
      expect(
        CreatorLinkRules.isSnsProfileLink(accounts, 'https://x.com/someone'),
        isFalse,
      );
      expect(
        CreatorLinkRules.isSnsProfileLink(accounts, 'https://fc.example.com/'),
        isFalse,
      );
    });

    test('行き先のドメインから、ボタンに付ける公式アイコンを決める', () {
      expect(
        CreatorLinkRules.iconServiceFor('https://www.youtube.com/@a'),
        SnsService.youtube,
      );
      expect(
        CreatorLinkRules.iconServiceFor('https://youtu.be/x'),
        SnsService.youtube,
      );
      expect(
        CreatorLinkRules.iconServiceFor('https://twitter.com/a'),
        SnsService.x,
      );
      expect(
        CreatorLinkRules.iconServiceFor('https://www.instagram.com/a/'),
        SnsService.instagram,
      );
      expect(
        CreatorLinkRules.iconServiceFor('https://www.twitch.tv/a'),
        SnsService.twitch,
      );
      // Twitch は、ウェブではロゴを使えない。
      expect(
        CreatorLinkRules.iconServiceFor('https://www.twitch.tv/a', web: true),
        isNull,
      );
      expect(
        CreatorLinkRules.iconServiceFor('https://twitcasting.tv/a'),
        SnsService.twitcasting,
      );
      expect(
        CreatorLinkRules.iconServiceFor(
          'https://ssl.twitcasting.tv/a',
          web: true,
        ),
        SnsService.twitcasting,
      );
      expect(CreatorLinkRules.iconServiceFor('https://booth.pm/a'), isNull);
      expect(
        CreatorLinkRules.iconServiceFor('https://notyoutube.com/'),
        isNull,
      );
    });

    test('Spotify・Discord の行き先も見分ける（LINE は入れない）', () {
      expect(
        CreatorLinkRules.brandFor('https://open.spotify.com/artist/a'),
        LinkBrand.spotify,
      );
      expect(
        CreatorLinkRules.brandFor('https://discord.gg/abc'),
        LinkBrand.discord,
      );
      expect(
        CreatorLinkRules.brandFor('https://discord.com/invite/abc'),
        LinkBrand.discord,
      );
      expect(CreatorLinkRules.brandFor('https://line.me/R/ti/p/@a'), isNull);
      expect(CreatorLinkRules.brandFor('https://www.youtube.com/@a'), isNull);
    });

    test('行から作る', () {
      final l = CreatorLink.fromRow({
        'id': 'l1',
        'title': 'グッズ',
        'url': 'https://shop.example.com/a',
        'click_count': 12,
      });
      expect(l.host, 'shop.example.com');
      expect(l.clickCount, 12);
    });
  });

  group('リンク集のページの並び（ウェブと同じ表）', () {
    // 公開サイトのリポジトリ（別管理） の oiboshi/worker/links_page_cases.json と同じ中身。ウェブは同じ表を deno test で確かめる。
    final cases =
        (jsonDecode(
                  File(
                    'test/fixtures/links_page_cases.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['cases']
            as List<dynamic>;
    for (final c in cases.cast<Map<String, dynamic>>()) {
      test(c['name'], () {
        final links = [
          for (final l in (c['links'] as List).cast<Map<String, dynamic>>())
            CreatorLink(
              id: l['id'] as String,
              title: l['title'] as String,
              url: l['url'] as String,
            ),
        ];
        expect([
          for (final b in CreatorLinkRules.pageLinks(links))
            {
              'id': b.id,
              // ボタンのアイコン（見本は公開のページと同じ。Twitch のロゴは出さない）。
              'icon':
                  CreatorLinkRules.iconServiceFor(b.url, web: true)?.name ??
                  CreatorLinkRules.brandFor(b.url)?.name,
            },
        ], c['buttons']);
      });
    }
  });

  group('リンク集の画面', () {
    late FakeData data;

    setUp(() {
      data = FakeData()..creators.add(sampleCreator());
    });

    Future<void> pump(WidgetTester tester) =>
        pumpScreen(tester, data, const CreatorLinksScreen(creatorId: 'minato'));

    testWidgets('着地の画面は、カード・「編集」「共有」・押された数だけを出す', (tester) async {
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 'a',
          title: 'ファンクラブ',
          url: 'https://fc.example.com/',
          clickCount: 1234,
        ),
        const CreatorLink(
          id: 'b',
          title: 'グッズ',
          url: 'https://shop.example.com/',
          clickCount: 0,
        ),
      ];
      await pump(tester);
      expect(
        find.byKey(const ValueKey('creator-links-preview')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('creator-links-edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('creator-links-share')), findsOneWidget);
      expect(find.text('1,234回'), findsOneWidget);
      expect(find.text('0回'), findsOneWidget);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('creator-link-clicks-a')))
            .dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('creator-link-clicks-b')))
              .dy,
        ),
      );
      // 追加・説明の文・URL の表示・ドメインは出さない。
      expect(find.byKey(const ValueKey('creator-links-add')), findsNothing);
      expect(find.text('リンク集のページ'), findsNothing);
      expect(find.text('https://oiboshi.perrii.app/c/minato'), findsNothing);
      expect(find.text('fc.example.com'), findsNothing);
      expect(find.textContaining('押された数は、'), findsNothing);
    });

    testWidgets('1件もなければ、押された数の所は空の一言', (tester) async {
      await pump(tester);
      expect(find.text('まだリンクがありません'), findsOneWidget);
      expect(find.byKey(const ValueKey('creator-links-edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('creator-links-share')), findsOneWidget);
    });

    testWidgets('「共有」で、「追星に誘う」と同じ文と誘う用のリンクを渡す', (tester) async {
      final sheet = FakeShareSheetService();
      await pumpScreen(
        tester,
        data,
        const CreatorLinksScreen(creatorId: 'minato'),
        shareSheet: sheet,
      );
      await tester.tap(find.byKey(const ValueKey('creator-links-share')));
      await tester.pumpAndSettle();
      expect(sheet.shared, [
        '追星で私の配信・予定を追いかけてね\nhttps://oiboshi.perrii.app/c/minato?invite=1',
      ]);
    });

    testWidgets('「編集」で編集の画面を開き、戻ると直した中身が出る', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('creator-links-edit')));
      await tester.pumpAndSettle();
      expect(find.text('リンク集を編集'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('creator-links-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('creator-link-title')),
        'ファンクラブ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('creator-link-url')),
        'https://fc.example.com/',
      );
      await tester.tap(find.byKey(const ValueKey('creator-link-save')));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(find.text('リンク集を編集'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('creator-links-preview')),
          matching: find.text('ファンクラブ'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey(
            'creator-link-clicks-${data.creatorLinks['minato']!.single.id}',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('0回'), findsOneWidget);
    });

    testWidgets('リンク集のページの見本に、名前・プロフィール文・リンクのボタンを出す', (tester) async {
      data.creators
        ..clear()
        ..add(sampleCreator().copyWith(bio: '歌と雑談の配信をしています。\n2行目'));
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 'a',
          title: 'ファンクラブ',
          url: 'https://fc.example.com/',
          clickCount: 3,
        ),
      ];
      await pump(tester);
      final preview = find.byKey(const ValueKey('creator-links-preview'));
      expect(preview, findsOneWidget);
      expect(
        find.descendant(of: preview, matching: find.text('星野ミナト')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: preview,
          matching: find.text('歌と雑談の配信をしています。\n2行目'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: preview, matching: find.text('ファンクラブ')),
        findsOneWidget,
      );
      // 共有したときのカード（OGP）の見本は出さない。
      expect(find.text('星野ミナト｜追星'), findsNothing);
    });

    testWidgets('見本は SNS のアイコンの列を出さず、リンクを全部、登録した順にボタンで出す（2026-11-19 本人）', (
      tester,
    ) async {
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 'x',
          title: 'X',
          url: 'https://x.com/minato_x',
          clickCount: 5,
        ),
        const CreatorLink(
          id: 'cas',
          title: 'ツイキャス',
          url: 'https://twitcasting.tv/m',
          clickCount: 4,
        ),
        const CreatorLink(
          id: 'yt',
          title: 'YouTube',
          url: 'https://www.youtube.com/channel/UC1',
          clickCount: 3,
        ),
        const CreatorLink(
          id: 'tw',
          title: 'Twitch',
          url: 'https://www.twitch.tv/m',
          clickCount: 2,
        ),
      ];
      await pump(tester);
      final preview = find.byKey(const ValueKey('creator-links-preview'));
      double y(Finder f) => tester.getTopLeft(f).dy;
      // ボタンは全部、登録した順。
      final buttons = [
        for (final id in ['x', 'cas', 'yt', 'tw'])
          y(
            find.descendant(
              of: preview,
              matching: find.byKey(ValueKey('creator-links-preview-link-$id')),
            ),
          ),
      ];
      expect([...buttons]..sort(), buttons);
      // ボタンのアイコンは公開のページと同じ（Twitch のロゴは出さない）。
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('creator-links-preview-link-tw')),
          matching: find.byType(PlatformIcon),
        ),
        findsNothing,
      );
      // 押された数の一覧も登録した順で、行のアイコンは見本のボタンと同じ。
      final order = [
        for (final id in ['x', 'cas', 'yt', 'tw'])
          y(find.byKey(ValueKey('creator-link-clicks-$id'))),
      ];
      expect([...order]..sort(), order);
      for (final (id, service) in [
        ('x', SnsService.x),
        ('cas', SnsService.twitcasting),
        ('yt', SnsService.youtube),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('creator-link-clicks-$id')),
            matching: find.byWidgetPredicate(
              (w) => w is PlatformIcon && w.service == service,
            ),
          ),
          findsOneWidget,
        );
      }
      expect(find.text('3回'), findsOneWidget);
    });

    testWidgets('見本を押すと、ページの全体を画面いっぱいで出し、閉じると戻る', (tester) async {
      data.creatorLinks['minato'] = [
        for (var i = 1; i <= 6; i++)
          CreatorLink(
            id: 'l$i',
            title: 'リンク$i',
            url: 'https://l$i.example.com/',
            clickCount: 0,
          ),
      ];
      await pump(tester);
      // 見本の下の「押すと全体を表示します」は出さない（2026-11-19 本人）。
      expect(find.text('押すと全体を表示します'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('creator-links-preview')));
      await tester.pumpAndSettle();
      final screen = find.byKey(const ValueKey('creator-links-page-screen'));
      expect(screen, findsOneWidget);
      // 公開のページと同じく、画面の幅で組む（ボタンは左右 16 の余白で横幅いっぱい。中身は 560 まで）。
      final screenWidth = tester.getSize(screen).width;
      final pageWidth = screenWidth < 560 ? screenWidth : 560.0;
      expect(
        tester
            .getSize(
              find.descendant(
                of: screen,
                matching: find.byKey(
                  const ValueKey('creator-links-preview-link-l1'),
                ),
              ),
            )
            .width,
        pageWidth - 32,
      );
      // カードで切れていたいちばん下のリンクと、下の追星への入口も出る（スクロールで見られる）。
      await tester.scrollUntilVisible(
        find.descendant(of: screen, matching: find.text('アプリをお持ちの方はこちら')),
        300,
        scrollable: find.descendant(
          of: screen,
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        find.descendant(of: screen, matching: find.text('リンク6')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('creator-links-page-close')));
      await tester.pumpAndSettle();
      expect(screen, findsNothing);
      expect(
        find.byKey(const ValueKey('creator-links-preview')),
        findsOneWidget,
      );
    });

    testWidgets('ファンに見せない発信者なら、共有せずに知らせる', (tester) async {
      data.unshareableCreatorIds.add('minato');
      final sheet = FakeShareSheetService();
      await pumpScreen(
        tester,
        data,
        const CreatorLinksScreen(creatorId: 'minato'),
        shareSheet: sheet,
      );
      await tester.tap(find.byKey(const ValueKey('creator-links-share')));
      await tester.pumpAndSettle();
      expect(sheet.shared, isEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('リンク集の編集の画面', () {
    late FakeData data;

    setUp(() {
      data = FakeData()..creators.add(sampleCreator());
    });

    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      data,
      const CreatorLinksEditScreen(creatorId: 'minato'),
    );

    testWidgets('リンクと、ドメイン・押された数を並び順で出す', (tester) async {
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 'a',
          title: 'ファンクラブ',
          url: 'https://fc.example.com/',
          clickCount: 1234,
        ),
        const CreatorLink(
          id: 'b',
          title: 'グッズ',
          url: 'https://shop.example.com/',
          clickCount: 0,
        ),
      ];
      await pump(tester);
      expect(find.text('ファンクラブ'), findsOneWidget);
      expect(find.text('fc.example.com'), findsOneWidget);
      expect(find.text('1,234回'), findsOneWidget);
      expect(find.text('0回'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('ファンクラブ')).dy,
        lessThan(tester.getTopLeft(find.text('グッズ')).dy),
      );
    });

    testWidgets('1件もなければ案内を出し、追加のシートで足せる', (tester) async {
      await pump(tester);
      expect(find.textContaining('まだリンクがありません'), findsOneWidget);
      await tester.tap(find.text('リンクを追加'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('creator-link-title')),
        ' ファンクラブ ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('creator-link-url')),
        'https://fc.example.com/',
      );
      await tester.tap(find.byKey(const ValueKey('creator-link-save')));
      await tester.pumpAndSettle();
      expect(data.creatorLinks['minato']!.single.title, 'ファンクラブ');
      expect(find.text('ファンクラブ'), findsOneWidget);
      expect(find.text('0回'), findsOneWidget);
    });

    testWidgets('題名が空・URL の形が違えば、保存せずに理由を出す', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('creator-links-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('creator-link-url')),
        'http://fc.example.com/',
      );
      await tester.tap(find.byKey(const ValueKey('creator-link-save')));
      await tester.pumpAndSettle();
      expect(find.text('題名を入れてください'), findsOneWidget);
      expect(find.text('https で始まる URL を入れてください'), findsOneWidget);
      expect(data.creatorLinks['minato'] ?? [], isEmpty);
    });

    testWidgets('短縮 URL は、サーバーが断った理由を欄の下に出し、シートを閉じない', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('creator-links-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('creator-link-title')),
        'x',
      );
      await tester.enterText(
        find.byKey(const ValueKey('creator-link-url')),
        'https://bit.ly/abc',
      );
      await tester.tap(find.byKey(const ValueKey('creator-link-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('短縮 URL は使えません'), findsOneWidget);
      expect(find.byKey(const ValueKey('creator-link-save')), findsOneWidget);
      expect(data.creatorLinks['minato'] ?? [], isEmpty);
    });

    testWidgets('10件あれば、追加を押せず、上限を出す', (tester) async {
      data.creatorLinks['minato'] = [
        for (var i = 0; i < CreatorLinkRules.maxLinks; i++)
          CreatorLink(
            id: 'l$i',
            title: 'リンク$i',
            url: 'https://l$i.example.com/',
            clickCount: 0,
          ),
      ];
      await pump(tester);
      final add = tester.widget<AppTextButton>(
        find.byKey(const ValueKey('creator-links-add')),
      );
      expect(add.onPressed, isNull);
      await tester.scrollUntilVisible(
        find.text('リンクは10件までです'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('リンクは10件までです'), findsOneWidget);
    });

    testWidgets('行を押すと編集でき、URL を変えると押された数が0に戻る', (tester) async {
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 'a',
          title: 'ファンクラブ',
          url: 'https://fc.example.com/',
          clickCount: 5,
        ),
      ];
      await pump(tester);
      await tester.tap(find.text('ファンクラブ'));
      await tester.pumpAndSettle();
      expect(find.text('リンクを編集'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('creator-link-url')),
        'https://fc2.example.com/',
      );
      await tester.tap(find.byKey(const ValueKey('creator-link-save')));
      await tester.pumpAndSettle();
      expect(find.text('fc2.example.com'), findsOneWidget);
      expect(find.text('0回'), findsOneWidget);
    });

    testWidgets('左へ払って確かめると、消す', (tester) async {
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 'a',
          title: 'ファンクラブ',
          url: 'https://fc.example.com/',
          clickCount: 5,
        ),
      ];
      await pump(tester);
      await tester.drag(find.text('ファンクラブ'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('「ファンクラブ」を消しますか？'), findsOneWidget);
      await tester.tap(find.text('削除').last);
      await tester.pumpAndSettle();
      expect(data.creatorLinks['minato'], isEmpty);
      expect(find.textContaining('まだリンクがありません'), findsOneWidget);
    });
  });

  group('発信者ページのボタン', () {
    late FakeData data;

    setUp(() {
      data = FakeData()..creators.add(sampleCreator());
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 'a',
          title: 'ファンクラブ',
          url: 'https://fc.example.com/join',
          clickCount: 3,
        ),
      ];
    });

    Future<void> pump(WidgetTester tester, {required bool canReport}) =>
        pumpScreen(
          tester,
          data,
          Scaffold(
            body: CreatorLinkButtons(creatorId: 'minato', canReport: canReport),
          ),
        );

    testWidgets('題名のボタンを出し、押すとドメインを出して確かめる', (tester) async {
      await pump(tester, canReport: true);
      await tester.tap(find.text('ファンクラブ'));
      await tester.pumpAndSettle();
      expect(find.text('外部のサイトを開きます'), findsOneWidget);
      expect(find.text('fc.example.com'), findsOneWidget);
      expect(find.text('このリンクを通報する'), findsOneWidget);
      // キャンセルでは数えない。
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(data.linkClicks, isEmpty);
    });

    testWidgets('「開く」で押された数を送る', (tester) async {
      await pump(tester, canReport: true);
      await tester.tap(find.text('ファンクラブ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('creator-link-open')));
      await tester.pumpAndSettle();
      expect(data.linkClicks, ['a']);
    });

    testWidgets('「このリンクを通報する」で、そのリンクの通報のシートを出す', (tester) async {
      await pump(tester, canReport: true);
      await tester.tap(find.text('ファンクラブ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('creator-link-report')));
      await tester.pumpAndSettle();
      expect(find.text('通報する'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('report-reason-dangerousLink')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('送信'));
      await tester.tap(find.text('送信'));
      await tester.pumpAndSettle();
      final (target, reason, _) = data.reports.single;
      expect(target, isA<LinkReportTarget>());
      expect((target as LinkReportTarget).linkId, 'a');
      expect(reason, ReportReason.dangerousLink);
      expect(data.linkClicks, isEmpty);
    });

    testWidgets('自分がオーナーの発信者では、通報を出さない', (tester) async {
      await pump(tester, canReport: false);
      await tester.tap(find.text('ファンクラブ'));
      await tester.pumpAndSettle();
      expect(find.text('このリンクを通報する'), findsNothing);
    });

    testWidgets('追星に誘うリンクは、アプリの発信者ページには出さない', (tester) async {
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 'i',
          title: '追星ですべてを受け取る',
          url: 'https://oiboshi.perrii.app/c/minato?invite=1',
          clickCount: 0,
        ),
        ...data.creatorLinks['minato']!,
      ];
      await pump(tester, canReport: true);
      expect(find.text('追星ですべてを受け取る'), findsNothing);
      expect(find.text('ファンクラブ'), findsOneWidget);
    });

    testWidgets('つないだ SNS のリンクは、発信者ページには出さない', (tester) async {
      data.creatorLinks['minato'] = [
        const CreatorLink(
          id: 's',
          title: 'X',
          url: 'https://x.com/minato_x',
          clickCount: 0,
        ),
        ...data.creatorLinks['minato']!,
      ];
      await pumpScreen(
        tester,
        data,
        const Scaffold(
          body: CreatorLinkButtons(
            creatorId: 'minato',
            canReport: true,
            snsAccounts: {SnsService.x: 'minato_x'},
          ),
        ),
      );
      expect(find.text('X'), findsNothing);
      expect(find.text('ファンクラブ'), findsOneWidget);
    });

    testWidgets('リンクがなければ何も出さない', (tester) async {
      data.creatorLinks['minato'] = [];
      await pump(tester, canReport: true);
      expect(find.byType(InkWell), findsNothing);
    });
  });
}
