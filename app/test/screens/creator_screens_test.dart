import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator_link.dart';
import 'package:oiboshi/ui/share/widgets/share_link_screen.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/report.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/core/ui/live_player.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/creator/widgets/creator_cover.dart';
import 'package:oiboshi/ui/creator/widgets/creator_page_parts.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  testWidgets('発信者ページは、プロフィールと投稿を出し、開くと既読にする', (tester) async {
    // カバー（横3：縦1）が画面の幅で伸びるので、スマホの大きさで確かめる。
    usePhoneScreen(tester);
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    expect(find.text('歌とゲームの配信をしています'), findsOneWidget);
    expect(find.text('@minato'), findsOneWidget);
    // 合計フォロワーは、数の下に「合計フォロワー」を積む。SNS が1つなので、チップも同じ数。
    expect(find.text('4.5万'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('4.5万').first).dy,
      lessThan(tester.getTopLeft(find.text('合計フォロワー')).dy),
    );
    expect(find.text('新しい動画'), findsOneWidget);
    // フォロー中は、「フォロー中」のボタンではなく、ベルだけの丸いボタン。
    expect(find.text('フォロー中'), findsNothing);
    expect(find.byType(CreatorBellButton), findsOneWidget);
    expect(data.follows.first.lastSeenAt, isNotNull);
    await unmount(tester);
  });

  testWidgets('リンク集を、合計フォロワー数の下にボタンで並べ、オーナーには通報を出さない', (tester) async {
    usePhoneScreen(tester);
    data.creatorLinks['minato'] = [
      const CreatorLink(
        id: 'a',
        title: 'ファンクラブ',
        url: 'https://fc.example.com/',
      ),
      const CreatorLink(
        id: 'b',
        title: 'グッズ',
        url: 'https://shop.example.com/',
      ),
    ];
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    expect(find.text('ファンクラブ'), findsOneWidget);
    expect(find.text('グッズ'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('合計フォロワー')).dy,
      lessThan(tester.getTopLeft(find.text('ファンクラブ')).dy),
    );
    await tester.tap(find.text('ファンクラブ'));
    await tester.pumpAndSettle();
    expect(find.text('このリンクを通報する'), findsOneWidget);
    await unmount(tester);

    data.ownedCreatorId = 'minato';
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.tap(find.text('ファンクラブ'));
    await tester.pumpAndSettle();
    expect(find.text('外部のサイトを開きます'), findsOneWidget);
    expect(find.text('このリンクを通報する'), findsNothing);
    await unmount(tester);
  });

  testWidgets('フォロー中のベルを押すと、シートで通知の切り替えとフォローをやめるを選べる', (tester) async {
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    // 通知オンは、塗ったベル。
    expect(find.byIcon(Icons.notifications), findsOneWidget);

    await tester.tap(find.byType(CreatorBellButton));
    await tester.pumpAndSettle();
    expect(find.text('通知をオフにする'), findsOneWidget);
    expect(find.text('フォローをやめる'), findsOneWidget);
    await tester.tap(find.text('通知をオフにする'));
    await tester.pumpAndSettle();
    expect(data.follows.single.notify, isFalse);
    // 通知オフは、斜線の入ったベル。シートは、逆の「通知をオンにする」。
    expect(find.byIcon(Icons.notifications_off), findsOneWidget);
    await tester.tap(find.byType(CreatorBellButton));
    await tester.pumpAndSettle();
    expect(find.text('通知をオンにする'), findsOneWidget);

    await tester.tap(find.text('フォローをやめる'));
    await tester.pumpAndSettle();
    expect(data.follows, isEmpty);
    expect(find.byType(CreatorBellButton), findsNothing);
    expect(find.text('フォロー'), findsOneWidget);
    await unmount(tester);
  });

  // 配信スクリーンモードはやめた。配信中も、ページはいつもの見た目にし、配信は固定ビューアだけで流す（2026-11-19 本人）。
  testWidgets('配信中も、いつもの見た目にし、アイコンに「LIVE」の印と「固定ビューアで見る」を出す', (tester) async {
    data.creators[0] = sampleCreator(live: sampleLive());
    usePhoneScreen(tester);
    await tester.pumpWidget(
      await testApp(data, const CreatorScreen(creatorId: 'minato')),
    );
    await tester.pump();
    await tester.pump();
    // いつものページ（カバー・プロフィール文・投稿）。ページの中では配信を流さない。
    expect(find.byType(CreatorCover), findsOneWidget);
    expect(find.text('歌とゲームの配信をしています'), findsOneWidget);
    expect(find.byType(LivePlayer), findsNothing);
    // アイコンに、ホームの推しの丸と同じ「LIVE」の印。
    final avatar = tester.widget<OshiAvatar>(find.byType(OshiAvatar).first);
    expect(avatar.badge, OshiBadge.live);
    expect(find.text('固定ビューアで見る'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('配信していなければ、「LIVE」の印も「固定ビューアで見る」も出さない', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      await testApp(data, const CreatorScreen(creatorId: 'minato')),
    );
    await tester.pump();
    await tester.pump();
    final avatar = tester.widget<OshiAvatar>(find.byType(OshiAvatar).first);
    expect(avatar.badge, isNot(OshiBadge.live));
    expect(find.text('固定ビューアで見る'), findsNothing);
    await unmount(tester);
  });

  testWidgets(
    '「固定ビューアで見る」で固定ビューアに流し、帯のアイコンでページを開いて固定ビューアを閉じても、ページはいつもの見た目のまま',
    (tester) async {
      data.creators[0] = sampleCreator(live: sampleLive());
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      final container = homeContainer(tester);
      await tester.tap(find.byType(OshiAvatar).first);
      await settleFrames(tester);
      final page = find.byType(CreatorScreen);
      expect(page, findsOneWidget);
      Finder pagePlayer() =>
          find.descendant(of: page, matching: find.byType(LivePlayer));
      expect(pagePlayer(), findsNothing);

      // 押すと、その配信を固定ビューアで流し、スイッチも入れる。流している間は、ボタンを出さない。
      await tester.tap(find.text('固定ビューアで見る'));
      await settleFrames(tester);
      expect(container.read(fixedViewerOnProvider), isTrue);
      expect(
        container.read(playbackProvider),
        isA<LivePlayback>().having((p) => p.creatorId, 'creatorId', 'minato'),
      );
      expect(find.text('固定ビューアで見る'), findsNothing);

      // ページを閉じて、固定ビューアの帯の推しのアイコンで、またページを開く。
      Navigator.of(tester.element(page)).pop();
      await settleFrames(tester);
      await tester.tap(find.byTooltip('発信者ページを開く'));
      await settleFrames(tester);
      expect(page, findsOneWidget);

      // 下部ナビのスイッチで固定ビューアを閉じても、ページの中に映像を出さない（暗い枠を残さない。2026-11-19 本人が見つけた不具合）。
      await tester.tap(find.bySemanticsLabel('固定ビューア'));
      await settleFrames(tester);
      expect(container.read(fixedViewerOnProvider), isFalse);
      expect(container.read(playbackProvider), isNull);
      expect(pagePlayer(), findsNothing);
      expect(find.byType(CreatorCover), findsOneWidget);
      // 閉じたら、また「固定ビューアで見る」を出し、押すと流す。
      expect(find.text('固定ビューアで見る'), findsOneWidget);
      await tester.tap(find.text('固定ビューアで見る'));
      await settleFrames(tester);
      expect(container.read(playbackProvider), isA<LivePlayback>());
      await unmount(tester);
    },
  );

  testWidgets('固定ビューアで別のものを流しているか、止めているときも、「固定ビューアで見る」でこの配信を流す', (
    tester,
  ) async {
    data.creators[0] = sampleCreator(live: sampleLive());
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    final container = homeContainer(tester);
    await tester.tap(find.byType(OshiAvatar).first);
    await settleFrames(tester);
    await tester.tap(find.text('固定ビューアで見る'));
    await settleFrames(tester);
    // コントローラーで止めたら、流していないとみなし、ボタンを出す。押すと流し直す。
    container.read(fixedViewerPausedProvider.notifier).set(true);
    await settleFrames(tester);
    expect(find.text('固定ビューアで見る'), findsOneWidget);
    await tester.tap(find.text('固定ビューアで見る'));
    await settleFrames(tester);
    expect(container.read(fixedViewerPausedProvider), isFalse);
    expect(find.text('固定ビューアで見る'), findsNothing);
    await unmount(tester);
  });

  testWidgets('YouTube の配信の固定ビューアは、画面の幅いっぱいで、縦も横も 200 以上（YouTube の規約）', (
    tester,
  ) async {
    FakeWebViewPlatform.channels.clear();
    data.creators[0] = sampleCreator(
      live: sampleLive(
        service: SnsService.youtube,
        title: 'ゲーム配信',
        playbackUrl: 'https://www.youtube.com/embed/abc123',
        link: 'https://www.youtube.com/watch?v=abc123',
      ),
    );
    data.follows.add(sampleFollow());
    // スマホの大きさ（390×844）。固定ビューアのぶん、画面を下にずらすので、縦に余裕のある画面で見る。
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tester.tap(find.byType(OshiAvatar).first);
    await settleFrames(tester);
    // ページの「固定ビューアで見る」で、固定ビューアで流す。
    await tester.tap(find.text('固定ビューアで見る'));
    await settleFrames(tester);
    // 画面の幅いっぱい（最大 400）で、縦も横も 200 以上。
    final screen = tester.getSize(find.byType(HomeShell));
    final topLeft = tester.getTopLeft(find.byType(LivePlayer));
    final bottomRight = tester.getBottomRight(find.byType(LivePlayer));
    expect(bottomRight.dy - topLeft.dy, greaterThanOrEqualTo(199.5));
    expect(
      bottomRight.dx - topLeft.dx,
      moreOrLessEquals(screen.width < 400 ? screen.width : 400, epsilon: 1),
    );
    // いちばん上の左右の真ん中に据え付ける。ドラッグしても動かない。
    expect(
      tester.getCenter(find.byType(LivePlayer)).dx,
      moreOrLessEquals(screen.width / 2, epsilon: 1),
    );
    await tester.drag(
      find.byType(LivePlayer),
      Offset(-screen.width * 0.3, -screen.height * 0.6),
    );
    await settleFrames(tester);
    expect(
      tester.getCenter(find.byType(LivePlayer)).dx,
      moreOrLessEquals(screen.width / 2, epsilon: 1),
    );
    expect(
      tester.getTopLeft(find.byType(LivePlayer)).dy,
      lessThan(screen.height / 4),
    );
    await unmount(tester);
  });

  testWidgets('プロフィール文は、改行があれば1行目だけを出し、「もっと見る」で開き「閉じる」で戻す', (tester) async {
    await pumpScreen(
      tester,
      data,
      const Scaffold(
        body: CreatorBio('1行目です\n2行目 https://example.com', style: TextStyle()),
      ),
    );
    expect(find.text('1行目です…', findRichText: true), findsOneWidget);
    expect(find.textContaining('2行目', findRichText: true), findsNothing);
    await tester.tap(find.text('もっと見る'));
    await tester.pump();
    expect(find.textContaining('2行目', findRichText: true), findsOneWidget);
    expect(find.text('もっと見る'), findsNothing);
    await tester.tap(find.text('閉じる'));
    await tester.pump();
    expect(find.text('1行目です…', findRichText: true), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('プロフィール文は、1行に収まらなければ折りたたみ、収まれば「もっと見る」を出さない', (tester) async {
    await pumpScreen(
      tester,
      data,
      Scaffold(
        body: Column(
          children: [
            CreatorBio('長い' * 200, style: const TextStyle()),
            const CreatorBio('短い', style: TextStyle()),
          ],
        ),
      ),
    );
    expect(find.text('もっと見る'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('確認済みのアカウントがない SNS のフォロワー数のチップは、押せない', (tester) async {
    const creator = Creator(
      id: 'c',
      name: 'C',
      linkedAccounts: {
        SnsService.youtube: CreatorAccount(
          service: SnsService.youtube,
          account: 'UC1',
          verified: true,
        ),
      },
      // Instagram は確認が外れ、数が消えるのを待っている。
      followerCounts: {SnsService.youtube: 590000, SnsService.instagram: 10000},
    );
    await pumpScreen(
      tester,
      data,
      const Scaffold(body: CreatorFollowerCounts(creator: creator)),
    );
    CreatorSnsChip chip(SnsService s) => tester
        .widgetList<CreatorSnsChip>(find.byType(CreatorSnsChip))
        .firstWhere((c) => c.service == s);
    expect(chip(SnsService.youtube).onTap, isNotNull);
    expect(chip(SnsService.instagram).onTap, isNull);
    // 「.0」は付けない。合計は、文字の並び（Text.rich）の中にある。
    expect(find.textContaining('60万', findRichText: true), findsOneWidget);
    expect(find.text('59万'), findsOneWidget);
    expect(find.text('1万'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('メニューの「通報する」で、理由を選んで送ると、通報してスナックバーを出す', (tester) async {
    // 通報のシートは背が高いので、スマホの画面の大きさにする（シートの上に、スナックバーの場所を空けるため）。
    usePhoneScreen(tester);
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通報する'));
    await tester.pumpAndSettle();
    // 理由を選ぶまで、送信を押せない。
    final submit = find.widgetWithText(PrimaryButton, '送信');
    expect(tester.widget<PrimaryButton>(submit).onPressed, isNull);
    await tester.tap(find.text('なりすまし'));
    await tester.enterText(find.byType(TextField), ' 本人ではありません ');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('通報しました。運営が確認します'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsNothing);
    final (target, reason, detail) = data.reports.single;
    expect((target as CreatorReportTarget).creatorId, 'minato');
    expect(reason, ReportReason.impersonation);
    expect(detail, '本人ではありません');
    await unmount(tester);
  });

  testWidgets('24時間のうちに通報済みなら、シートを残したまま知らせる', (tester) async {
    usePhoneScreen(tester);
    data.reportResult = ReportResult.duplicate;
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通報する'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('その他'));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, '送信'));
    await tester.pumpAndSettle();
    expect(find.text('この内容は、すでに通報を受け付けています'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, '送信'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('「この発信者を表示しない」で、フォローを外して表示しないにし、前の画面に戻る', (tester) async {
    data.follows.add(sampleFollow());
    await pumpOpener(
      tester,
      data,
      (context) => CreatorScreen.open(context, 'minato'),
    );
    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この発信者を表示しない'));
    await tester.pumpAndSettle();
    expect(find.text('星野ミナトを表示しないようにしますか？'), findsOneWidget);
    await tester.tap(find.text('表示しない'));
    await tester.pumpAndSettle();
    expect(data.follows, isEmpty);
    expect(data.hiddenCreatorIds, ['minato']);
    expect(find.byType(CreatorScreen), findsNothing);
    expect(find.text('この発信者を表示しないようにしました'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('表示しないにできなければ、ページに残って知らせる', (tester) async {
    data.hiddenWriteFails = true;
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この発信者を表示しない'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('表示しない'));
    await tester.pumpAndSettle();
    expect(find.text('表示しないにできませんでした'), findsOneWidget);
    expect(find.byType(CreatorScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('自分がオーナーの発信者のメニューには、「リンクを共有」だけを出す', (tester) async {
    data.ownedCreatorId = 'minato';
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('リンクを共有'), findsOneWidget);
    expect(find.text('通報する'), findsNothing);
    expect(find.text('この発信者を表示しない'), findsNothing);
    await unmount(tester);
  });

  testWidgets('ファンが開いた発信者ページのメニューにも、「リンクを共有」を出す', (tester) async {
    final sheet = FakeShareSheetService();
    await pumpScreen(
      tester,
      data,
      const CreatorScreen(creatorId: 'minato'),
      shareSheet: sheet,
    );
    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('通報する'), findsOneWidget);
    await tester.tap(find.text('リンクを共有'));
    await tester.pumpAndSettle();
    // 「リンクを共有」の画面を開き、そこから共有シートへ。
    expect(find.byType(ShareLinkScreen), findsOneWidget);
    await tester.tap(find.text('リンクを共有する'));
    await tester.pumpAndSettle();
    expect(
      sheet.shared.single,
      contains('https://oiboshi.perrii.app/c/minato'),
    );
    await unmount(tester);
  });
}
