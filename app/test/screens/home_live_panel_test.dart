import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/oshi.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/live_player.dart';
import 'package:oiboshi/ui/core/ui/live_strip_layout.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/core/ui/page_dots.dart';
import 'package:oiboshi/ui/core/ui/sns_style.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/home/widgets/home_live_panel.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

/// ホームの配信ビューアと推しレーン（機能仕様書 4.3.4）。
void main() {
  setUpScreenTests();

  Live live(String title, {SnsService service = SnsService.twitcasting}) =>
      liveTitled(title, service: service, link: 'https://example.com/$title');

  /// ホームの配信ビューアで流している配信。
  Iterable<LivePlayer> panelPlayers(WidgetTester tester) =>
      tester.widgetList<LivePlayer>(
        find.descendant(
          of: find.byType(HomeLivePanel),
          matching: find.byType(LivePlayer),
        ),
      );

  /// 帯の点の真ん中。真ん中に置くと左の組に重なるとき（テストの文字は幅が広い）は、
  /// 重ならないところまでずらすので、そのぶんを戻した値（ずらしていなければ、そのまま）。
  /// 帯の「LIVE」と配信元の印（見た目の角丸の箱）。
  Finder badgeBox(Finder scope) => find
      .descendant(
        of: find.descendant(of: scope, matching: find.byType(LiveSourceBadge)),
        matching: find.byType(Material),
      )
      .first;

  double dotsCenter(Rect dots, Rect avatar) {
    // 推しのアイコンの押せる範囲の右端（見た目 + 6）と、前の矢印の押せる範囲（34）の左端。
    final pushed = avatar.right + 6 + 34 + dots.width / 2;
    return dots.center.dx == pushed && pushed > 195 ? 195 : dots.center.dx;
  }

  testWidgets('文字を大きくする設定でも、推しレーンの名前がはみ出さない', (tester) async {
    data.creators[0] = sampleCreator(live: live('朝の雑談'));
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpHome(tester);
    // はみ出すと、描画の例外になり、テストが失敗する。
    expect(tester.takeException(), isNull);
    expect(find.text('星野ミナト'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('配信中の推しがいなければ、配信ビューアを出さない', (tester) async {
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    expect(
      find.descendant(
        of: find.byType(HomeLivePanel),
        matching: find.byType(PageView),
      ),
      findsNothing,
    );
    expect(find.text('● LIVE'), findsNothing);
    expect(find.byType(LivePlayer), findsNothing);
    await unmount(tester);
  });

  testWidgets('配信中の推しを、1人ずつ流し、帯の払いと矢印で周回して切り替える', (tester) async {
    data.creators[0] = sampleCreator(live: live('朝の雑談'));
    data.creators.add(hiyori(live: live('歌枠')));
    data.follows
      ..add(sampleFollow())
      ..add(sampleFollow('hiyori'));
    usePhoneScreen(tester);
    await pumpHome(tester);

    final panel = find.byType(HomeLivePanel);
    expect(panel, findsOneWidget);
    // 流すのは、いま出している1人だけ。
    expect(panelPlayers(tester).map((p) => p.live.title), ['朝の雑談']);
    // 映像の外の帯には、「LIVE」と配信元の印・推しのアイコン・矢印・固定ビューアのボタンを出す。名前やタイトルは出さない。
    final badge = find.descendant(
      of: panel,
      matching: find.byType(LiveSourceBadge),
    );
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('LIVE')),
      findsOneWidget,
    );
    // 配信元のロゴは、配信元の色の背景に、単色のロゴで出す（tech-risks.md 2.23）。
    expect(
      tester
          .widget<PlatformMark>(
            find.descendant(of: badge, matching: find.byType(PlatformMark)),
          )
          .service,
      SnsService.twitcasting,
    );
    expect(
      tester.widget<Material>(badgeBox(panel)).color,
      SnsStyle.color(SnsService.twitcasting),
    );
    expect(
      find.descendant(of: panel, matching: find.byType(PlatformIcon)),
      findsNothing,
    );
    expect(
      find.descendant(of: panel, matching: find.text('星野ミナト')),
      findsNothing,
    );
    expect(
      find.descendant(of: panel, matching: find.text('朝の雑談')),
      findsNothing,
    );
    // 印と推しのアイコンは、高さをそろえる。
    final liveHeight = tester.getSize(badgeBox(panel)).height;
    expect(liveHeight, 22);
    expect(
      tester
          .getSize(
            find.descendant(of: panel, matching: find.byType(AvatarImage)),
          )
          .height,
      liveHeight,
    );
    // 並びの決まり：見た目の間はどれも 12、左右の端の余白は 12、矢印と点の組は真ん中（画面定義書 2.2.1）。
    Rect rectOf(Finder f) =>
        tester.getRect(find.descendant(of: panel, matching: f).first);
    final badgeRect = tester.getRect(badgeBox(panel));
    final avatar = rectOf(find.byType(AvatarImage));
    final pin = rectOf(find.byIcon(Icons.smart_display_outlined));
    expect(badgeRect.left, 12);
    expect(avatar.left - badgeRect.right, 12);
    // 固定ビューアのボタンは、右端に置く。
    expect(390 - pin.right, 12);
    expect(dotsCenter(rectOf(find.byType(PageDots)), avatar), 195);

    // 映像の上で払っても、切り替わらない（YouTube の規約）。
    await tester.fling(
      find.descendant(of: panel, matching: find.byType(PageView)),
      const Offset(-300, 0),
      1000,
    );
    await settleFrames(tester);
    expect(panelPlayers(tester).map((p) => p.live.title), ['朝の雑談']);

    // 映像の下の帯を払うと、隣の推しに移る。
    await tester.fling(badge, const Offset(-300, 0), 1000);
    await settleFrames(tester);
    expect(panelPlayers(tester).map((p) => p.live.title), ['歌枠']);

    // 端の推しの次は、反対の端の推しに戻る（周回する）。
    await tester.fling(badge, const Offset(-300, 0), 1000);
    await settleFrames(tester);
    expect(panelPlayers(tester).map((p) => p.live.title), ['朝の雑談']);

    // 矢印でも切り替える。前へ戻すと、反対の端へ。
    await tester.tap(find.byTooltip('前の配信'));
    await settleFrames(tester);
    expect(panelPlayers(tester).map((p) => p.live.title), ['歌枠']);
    await tester.tap(find.byTooltip('次の配信'));
    await settleFrames(tester);
    expect(panelPlayers(tester).map((p) => p.live.title), ['朝の雑談']);
    await unmount(tester);
  });

  testWidgets('Twitch の配信も流し、帯の推しのアイコンで発信者ページを開く', (tester) async {
    data.creators[0] = sampleCreator(
      live: live('ゲーム配信', service: SnsService.twitch),
    );
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    expect(panelPlayers(tester).map((p) => p.live.title), ['ゲーム配信']);

    // 帯の印は、Twitch の色の背景に、Black Ops の Glitch で出す。押すと、配信元を開く（発信者ページには移らない）。
    final panel = find.byType(HomeLivePanel);
    expect(
      tester.widget<Material>(badgeBox(panel)).color,
      SnsStyle.color(SnsService.twitch),
    );
    expect(
      tester
          .widget<PlatformMark>(
            find.descendant(of: panel, matching: find.byType(PlatformMark)),
          )
          .service,
      SnsService.twitch,
    );
    expect(
      find.descendant(of: panel, matching: find.byTooltip('配信元で開く')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('発信者ページを開く'));
    await settleFrames(tester);
    expect(find.byType(CreatorScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('配信ビューアの映像を押しても、発信者ページに移らない', (tester) async {
    data.creators[0] = sampleCreator(live: live('朝の雑談'));
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);

    // ツイキャスは、映像を押すとミュートを切り替える（テストでは映像を読み込めないので、移らないことだけ見る）。
    await tester.tap(find.byType(LivePlayer));
    await settleFrames(tester);
    expect(find.byType(CreatorScreen), findsNothing);
    await unmount(tester);
  });

  /// 固定ビューアのプレイヤー（ホームの配信ビューアの外のもの）。
  Finder miniPlayer(WidgetTester tester) => find.byElementPredicate(
    (e) =>
        e.widget is LivePlayer &&
        e.findAncestorWidgetOfExactType<HomeLivePanel>() == null,
  );

  testWidgets('固定ビューアのボタンを押すと固定ビューアで上に据え付けてスイッチを入れ、スイッチを切ると配信ビューアに戻す', (
    tester,
  ) async {
    data.creators[0] = sampleCreator(live: live('朝の雑談'));
    data.creators.add(hiyori(live: live('歌枠')));
    data.follows
      ..add(sampleFollow())
      ..add(sampleFollow('hiyori'));
    usePhoneScreen(tester);
    await pumpHome(tester);
    expect(find.byType(PageDots), findsOneWidget);

    await tester.tap(find.byTooltip('固定ビューアで流す'));
    await settleFrames(tester);
    final container = homeContainer(tester);
    final playback = container.read(playbackProvider);
    expect((playback! as LivePlayback).creatorId, 'minato');
    // 固定ビューアのボタンで流し始めたら、下部ナビのスイッチも入れる。
    expect(container.read(fixedViewerOnProvider), isTrue);
    // 固定ビューアは音を出して流し、画面のいちばん上に置く。ホームの画面は、その下から始まる（重ねない）。
    expect(miniPlayer(tester), findsOneWidget);
    final mini = tester.getRect(miniPlayer(tester));
    expect(mini.top, lessThan(80));
    expect(
      tester.getTopLeft(find.byType(OshiAvatar).first).dy,
      greaterThan(mini.bottom),
    );
    // 固定ビューア（帯まで）の下に、すき間を空けない。推しレーンの上の余白 8 は、レーンの側に取る。
    final pinnedStrip = find
        .ancestor(
          of: find.byTooltip('推しの動画をランダムに流す'),
          matching: find.byType(LiveStripLayout),
        )
        .first;
    expect(
      tester.getTopLeft(find.byType(OshiAvatar).first).dy,
      tester.getBottomLeft(pinnedStrip).dy + 8,
    );
    // ホームのヘッダーは出さない（固定ビューアが上に据わるので、縦を空ける）。
    expect(find.text('追星'), findsNothing);
    // 固定ビューアの間は、ほかの推しが配信中でも、ホームの配信ビューアを出さない。
    expect(
      find.descendant(
        of: find.byType(HomeLivePanel),
        matching: find.byType(LiveSourceBadge),
      ),
      findsNothing,
    );

    // 固定ビューアの帯は、「LIVE」と配信元の印と何人目かの点を、ホームの配信ビューアと同じ見た目で出す。
    final strip = pinnedStrip;
    expect(
      find.descendant(of: strip, matching: find.byType(LiveSourceBadge)),
      findsOneWidget,
    );
    final dots = find.descendant(of: strip, matching: find.byType(PageDots));
    expect(dots, findsOneWidget);
    expect(tester.widget<PageDots>(dots).count, 2);
    expect(tester.widget<PageDots>(dots).index, 0);
    expect(tester.widget<PageDots>(dots).color, Colors.white);
    // 点は、矢印の間に出す。
    expect(
      tester.getCenter(dots).dx,
      inExclusiveRange(
        tester.getCenter(find.byTooltip('前の配信')).dx,
        tester.getCenter(find.byTooltip('次の配信')).dx,
      ),
    );
    // 印と推しのアイコンは、高さをそろえる。
    final liveHeight = tester.getSize(badgeBox(strip)).height;
    expect(liveHeight, 22);
    expect(
      tester
          .getSize(
            find.descendant(of: strip, matching: find.byType(AvatarImage)),
          )
          .height,
      liveHeight,
    );
    // 固定ビューアのボタンと×は出さない。右端は、ランダム再生に切り替えるボタン。
    expect(find.byTooltip('固定ビューアで流す'), findsNothing);
    expect(find.byTooltip('閉じる'), findsNothing);
    // 並びは、ホームの配信ビューアと同じ決まり（見た目の間 12、端の余白 12、点は真ん中）。
    Rect stripRect(Finder f) =>
        tester.getRect(find.descendant(of: strip, matching: f).first);
    final miniBadge = tester.getRect(badgeBox(strip));
    final miniAvatar = stripRect(find.byType(AvatarImage));
    final shuffleIcon = stripRect(find.byIcon(Icons.video_library));
    expect(miniBadge.left, 12);
    expect(miniAvatar.left - miniBadge.right, 12);
    expect(390 - shuffleIcon.right, 12);
    expect(dotsCenter(tester.getRect(dots), miniAvatar), 195);

    // 帯で次の推しに切り替えると、点も移る。
    await tester.tap(find.byTooltip('次の配信'));
    await settleFrames(tester);
    expect(tester.widget<PageDots>(dots).index, 1);

    // 下部ナビのスイッチを切ると、ホームの配信ビューアに戻し、切り替えた先の推しを音を出したまま流す。
    await tester.tap(find.bySemanticsLabel('固定ビューア'));
    await settleFrames(tester);
    expect(container.read(fixedViewerOnProvider), isFalse);
    expect(container.read(playbackProvider), isNull);
    expect(
      tester
          .widgetList<LivePlayer>(find.byType(LivePlayer))
          .map((p) => p.live.title),
      ['歌枠'],
    );
    await unmount(tester);
  });

  testWidgets('固定ビューアの帯を横に払うと、前後の配信中の推しに切り替え、端の次は反対の端に戻る', (tester) async {
    data.creators[0] = sampleCreator(live: live('朝の雑談'));
    data.creators.add(hiyori(live: live('歌枠')));
    data.follows
      ..add(sampleFollow())
      ..add(sampleFollow('hiyori'));
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tester.tap(find.byTooltip('固定ビューアで流す'));
    await settleFrames(tester);
    final container = homeContainer(tester);
    String playing() =>
        (container.read(playbackProvider)! as LivePlayback).creatorId;
    expect(playing(), 'minato');

    // 帯（次の矢印の右）を左へ払うと、次の推しへ。
    Offset strip() =>
        tester.getCenter(find.byTooltip('次の配信')) + const Offset(60, 0);
    await tester.flingFrom(strip(), const Offset(-300, 0), 1000);
    await settleFrames(tester);
    expect(playing(), 'hiyori');
    expect(miniPlayer(tester), findsOneWidget);

    // 最後の推しで、さらに左へ払うと、最初の推しに戻る。
    await tester.flingFrom(strip(), const Offset(-300, 0), 1000);
    await settleFrames(tester);
    expect(playing(), 'minato');

    // 右へ払うと、前の推し（反対の端）へ。矢印でも切り替える。
    await tester.flingFrom(strip(), const Offset(300, 0), 1000);
    await settleFrames(tester);
    expect(playing(), 'hiyori');
    await tester.tap(find.byTooltip('次の配信'));
    await settleFrames(tester);
    expect(playing(), 'minato');

    // ホームの配信ビューアと同じく、短く軽く払っても切り替える。
    await tester.flingFrom(strip(), const Offset(60, 0), 300);
    await settleFrames(tester);
    expect(playing(), 'hiyori');
    await tester.flingFrom(strip(), const Offset(-60, 0), 300);
    await settleFrames(tester);
    expect(playing(), 'minato');
    await unmount(tester);
  });

  testWidgets('固定ビューアで何か流している間は、ホームの配信ビューアでは流さない', (tester) async {
    final morning = live('朝の雑談');
    data.creators[0] = sampleCreator(live: morning);
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    expect(panelPlayers(tester), hasLength(1));

    homeContainer(
      tester,
    ).read(playbackProvider.notifier).play('minato', morning);
    await settleFrames(tester);
    expect(panelPlayers(tester), isEmpty);
    await unmount(tester);
  });

  testWidgets('投稿ビューアを開いている間も、配信ビューアの配信は止めずに流す（閉じたとき、すぐ続きを見られる）', (
    tester,
  ) async {
    data.creators[0] = sampleCreator(live: live('朝の雑談'));
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    expect(panelPlayers(tester), hasLength(1));

    await tester.ensureVisible(find.text('新しい動画').first);
    await tester.tap(find.text('新しい動画').first);
    await settleFrames(tester);
    expect(find.byType(PostViewerScreen), findsOneWidget);
    expect(panelPlayers(tester), hasLength(1));

    await tester.tap(find.byTooltip('閉じる'));
    await settleFrames(tester);
    expect(find.byType(PostViewerScreen), findsNothing);
    expect(panelPlayers(tester), hasLength(1));
    await unmount(tester);
  });

  testWidgets('推しレーンは、配信中・新着あり・それ以外の順に並べ、赤いリングは流している推しだけに付ける', (tester) async {
    final followed = DateTime.now().subtract(const Duration(days: 1));
    data.creators
      ..[0] = sampleCreator()
      ..add(
        Creator(
          id: 'kanon',
          name: '花音',
          latestPostAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      )
      ..add(hiyori(live: live('歌枠')))
      ..add(Creator(id: 'sora', name: '空', live: live('雑談')));
    data.follows
      ..add(Follow(creatorId: 'minato', followedAt: followed))
      ..add(Follow(creatorId: 'kanon', followedAt: followed))
      ..add(Follow(creatorId: 'hiyori', followedAt: followed))
      ..add(Follow(creatorId: 'sora', followedAt: followed));
    usePhoneScreen(tester);
    await pumpHome(tester);

    List<OshiAvatar> lane() => tester
        .widgetList<OshiAvatar>(find.byType(OshiAvatar))
        .where((a) => a.size == 72)
        .toList();
    expect(
      [for (final a in lane()) (a.ring, a.badge)],
      [
        (OshiRing.live, OshiBadge.live),
        (OshiRing.read, OshiBadge.live),
        (OshiRing.read, OshiBadge.newPost),
        (OshiRing.read, null),
      ],
    );
    expect(find.text('NEW'), findsOneWidget);
    expect(panelPlayers(tester).map((p) => p.live.title), ['歌枠']);

    // 流していない配信中の推しを押すと、配信ビューアをその推しに切り替え、赤いリングも移る。
    await tester.tap(find.byType(OshiAvatar).at(1));
    await settleFrames(tester);
    expect(panelPlayers(tester).map((p) => p.live.title), ['雑談']);
    expect([for (final a in lane()) a.ring].take(2), [
      OshiRing.read,
      OshiRing.live,
    ]);
    expect(find.byType(CreatorScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('全体タイムラインには、配信中の YouTube の配信枠を出さない', (tester) async {
    data.creators[0] = sampleCreator(
      live: sampleLive(
        service: SnsService.youtube,
        title: 'ゲーム配信',
        playbackUrl: 'https://www.youtube.com/embed/live1',
        link: 'https://www.youtube.com/watch?v=live1',
      ),
    );
    data.posts
      ..add(samplePost(id: 'yt:live1', text: '配信の枠'))
      ..add(samplePost(id: 'yt:old', text: '前の動画'));
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    expect(find.text('前の動画'), findsOneWidget);
    expect(find.text('配信の枠'), findsNothing);
    await unmount(tester);
  });
}
