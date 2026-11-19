import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/ui/core/ui/app_bottom_nav.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/core/ui/post_cards.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/home/view_models/home_shell_viewmodel.dart';
import 'package:oiboshi/ui/home/widgets/home_body.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';
import 'package:oiboshi/ui/oshi/widgets/find_creators_screen.dart';
import 'package:oiboshi/ui/oshi/widgets/oshi_list_body.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';
import 'package:oiboshi/ui/schedule/widgets/event_list_screen.dart';
import 'package:oiboshi/ui/settings/widgets/settings_screen.dart';
import 'package:oiboshi/utils/formatters.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  testWidgets('ホームのヘッダーには、「追星」の文字の代わりにロゴを出し、読み上げは「追星」にする', (tester) async {
    await pumpHome(tester);
    final logo = find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == 'assets/logo/home_logo.png',
    );
    expect(logo, findsOneWidget);
    expect(find.text('追星'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '追星' &&
            w.properties.header == true &&
            w.excludeSemantics,
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('推しがいなければ、ホームに「推しを探しましょう」を出す', (tester) async {
    await pumpHome(tester);
    expect(find.text('推しを探しましょう'), findsOneWidget);
    await tester.tap(find.text('推しを探す'));
    await tester.pumpAndSettle();
    expect(find.text('おすすめ'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しがいれば、ホームに推しの行・次の予定・投稿を出す', (tester) async {
    data.follows.add(sampleFollow());
    data.schedules.add(
      sampleSchedule(
        's1',
        '夜の雑談配信',
        laterToday(1),
        service: SnsService.twitcasting,
      ),
    );
    await pumpHome(tester);
    expect(find.text('星野ミナト'), findsWidgets);
    expect(find.text('次の予定'), findsOneWidget);
    expect(find.text('夜の雑談配信'), findsOneWidget);
    expect(find.text('新しい動画'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('「次の予定」の左端は、推しが配信中でも、予定の開始時刻を出す', (tester) async {
    final starts = laterToday(1);
    data.creators[0] = sampleCreator(
      live: sampleLive(
        service: SnsService.twitch,
        title: '24時間配信',
        link: 'https://example.com/live',
      ),
    );
    data.follows.add(sampleFollow());
    data.schedules.add(
      sampleSchedule('s1', '夜の雑談配信', starts, service: SnsService.twitch),
    );
    // 配信ビューアの映像の下に「次の予定」が来るので、縦に長い画面で見る。
    usePhoneScreen(tester, size: const Size(1170, 3600));
    await pumpHome(tester);
    final row = find.widgetWithText(InkWell, '夜の雑談配信').last;
    expect(
      find.descendant(of: row, matching: find.text(clockTime(starts))),
      findsOneWidget,
    );
    expect(find.descendant(of: row, matching: find.text('LIVE')), findsNothing);
    // 時刻は、欄からはみ出さずに出す（前は、欄が狭く、「09:00」の最後の数字が欄の外にはみ出して見えなかった）。
    // 文字が、1行で出すのに要る幅を、そのままもらえていること（はみ出すときは、縮めて欄に収める）。
    final time = tester.renderObject<RenderParagraph>(
      find.text(clockTime(starts)),
    );
    expect(
      time.size.width,
      greaterThanOrEqualTo(time.getMaxIntrinsicWidth(double.infinity) - 0.5),
    );
    expect(
      tester.getRect(find.text(clockTime(starts))).right,
      lessThanOrEqualTo(
        tester
            .getRect(
              find.descendant(of: row, matching: find.byType(AvatarImage)),
            )
            .left,
      ),
    );
    await unmount(tester);
  });

  testWidgets('予定もイベントもなくても、「次の予定」と「イベント」の面を出し、ないことを知らせる', (tester) async {
    data.follows.add(sampleFollow());
    await pumpHome(tester);
    expect(find.text('次の予定'), findsOneWidget);
    expect(find.text('今日はこれからの予定はありません'), findsOneWidget);
    expect(find.text('イベント'), findsOneWidget);
    expect(find.text('これからのイベントはありません'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('イベントは、次の予定ではなく、その下の「イベント」に出す', (tester) async {
    data.follows.add(sampleFollow());
    data.schedules.addAll([
      sampleSchedule(
        's1',
        '夜の雑談配信',
        laterToday(1),
        service: SnsService.twitcasting,
      ),
      sampleSchedule(
        'e1',
        'ワンマンライブ',
        DateTime.now().add(const Duration(days: 20)),
        venue: '渋谷クアトロ',
      ),
      sampleSchedule(
        'e0',
        '終わったイベント',
        DateTime.now().subtract(const Duration(hours: 5)),
        endsAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ]);
    await pumpHome(tester);
    expect(find.text('次の予定'), findsOneWidget);
    expect(find.text('イベント'), findsOneWidget);
    expect(find.text('ワンマンライブ'), findsOneWidget);
    // 行は、イベント一覧と同じ形（日付のブロック、「曜日 時刻・会場」、推しの名前）。
    expect(find.textContaining('・渋谷クアトロ'), findsOneWidget);
    expect(find.text('星野ミナト'), findsWidgets);
    expect(find.text('終わったイベント'), findsNothing);
    // イベントは、次の予定の面の中ではなく、その下に出る。
    expect(
      tester.getTopLeft(find.text('ワンマンライブ')).dy,
      greaterThan(tester.getTopLeft(find.text('夜の雑談配信')).dy),
    );
    expect(
      tester.getTopLeft(find.text('イベント')).dy,
      greaterThan(tester.getTopLeft(find.text('夜の雑談配信')).dy),
    );
    await unmount(tester);
  });

  /// これからの予定を [schedules] 件、これからのイベントを [events] 件、足す。
  void addSchedules({required int schedules, required int events}) {
    final now = DateTime.now();
    for (var i = 0; i < schedules; i++) {
      data.schedules.add(
        sampleSchedule(
          's$i',
          '配信$i',
          laterToday(i + 1, of: schedules),
          service: SnsService.youtube,
        ),
      );
    }
    for (var i = 0; i < events; i++) {
      data.schedules.add(
        sampleSchedule('e$i', 'ライブ$i', now.add(Duration(days: i + 1))),
      );
    }
  }

  testWidgets('「次の予定」「イベント」が2件以下なら、「ほか N 件」を出さない', (tester) async {
    data.follows.add(sampleFollow());
    addSchedules(schedules: 2, events: 2);
    await pumpHome(tester);
    expect(find.text('配信1'), findsOneWidget);
    expect(find.text('ライブ1'), findsOneWidget);
    expect(find.textContaining('ほか'), findsNothing);
    await unmount(tester);
  });

  testWidgets('「次の予定」の「ほか N 件」を押すと、スケジュールのタブへ移る', (tester) async {
    data.follows.add(sampleFollow());
    addSchedules(schedules: 5, events: 0);
    await pumpHome(tester);
    expect(find.text('配信1'), findsOneWidget);
    expect(find.text('配信2'), findsNothing);
    expect(find.text('ほか 3 件'), findsOneWidget);
    // 「ほか N 件」は、面の下ではなく、見出しと同じ段の右に出す。
    expect(
      tester.getCenter(find.text('ほか 3 件')).dy,
      closeTo(tester.getCenter(find.text('次の予定')).dy, 1),
    );
    expect(
      tester.getCenter(find.text('ほか 3 件')).dx,
      greaterThan(tester.getCenter(find.text('次の予定')).dx),
    );
    await tester.tap(find.text('ほか 3 件'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppBottomNav>(find.byType(AppBottomNav)).currentIndex,
      1,
    );
    expect(find.byTooltip('絞り込み').hitTestable(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('スケジュールのタブで別の画面を開いたままでも、「ほか N 件」で24時間のタイムスケジュールを出す', (
    tester,
  ) async {
    data.follows.add(sampleFollow());
    addSchedules(schedules: 5, events: 0);
    await pumpHome(tester);
    // スケジュールのタブで、別の画面（月のカレンダーなど）を開いたまま、ホームに戻る。
    await tester.tap(find.bySemanticsLabel('スケジュール'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byTooltip('絞り込み'))).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('別の画面')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('ホーム'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ほか 3 件'));
    await tester.pumpAndSettle();
    expect(find.text('別の画面'), findsNothing);
    expect(find.byTooltip('絞り込み').hitTestable(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('タイムラインの続きを読めなければ、印を止めて「再試行」を出し、押すと読み直す', (tester) async {
    data.follows.add(sampleFollow());
    // 1ページ（50件）ぶん読み込み、続きがある状態にする。
    for (var i = 0; i < 60; i++) {
      data.posts.add(
        samplePost(
          id: 'yt:p$i',
          text: '動画$i',
          postedAt: DateTime.now().subtract(Duration(hours: i + 1)),
        ),
      );
    }
    usePhoneScreen(tester);
    await pumpHome(tester);
    data.failReads = true;
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -40000),
    );
    await settleFrames(tester);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -40000),
    );
    await settleFrames(tester);
    expect(find.text('読み込めませんでした'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // 下までスクロールしても、ひとりでには読み直さない。「再試行」で読み直す。
    data.failReads = false;
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -2000),
    );
    await settleFrames(tester);
    expect(find.text('読み込めませんでした'), findsOneWidget);
    await tester.tap(find.text('再試行'));
    await settleFrames(tester);
    expect(find.text('読み込めませんでした'), findsNothing);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -40000),
    );
    await settleFrames(tester);
    expect(find.text('過去90日ぶんを、すべて表示しました'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('「イベント」の「ほか N 件」を押すと、ホームのタブの中で推し全員のイベント一覧を開く', (tester) async {
    data.creators.add(const Creator(id: 'sora', name: '天野ソラ'));
    data.follows.addAll([sampleFollow(), sampleFollow('sora')]);
    addSchedules(schedules: 0, events: 4);
    await pumpHome(tester);
    expect(find.text('ライブ1'), findsOneWidget);
    expect(find.text('ライブ2'), findsNothing);
    final more = find.text('ほか 2 件');
    expect(more, findsOneWidget);
    expect(
      tester.getCenter(more).dy,
      closeTo(tester.getCenter(find.text('イベント')).dy, 1),
    );
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    final list = tester.widget<EventListScreen>(find.byType(EventListScreen));
    expect({for (final c in list.creators) c.id}, {'minato', 'sora'});
    expect(find.text('みんなのイベント'), findsOneWidget);
    // 一覧には、面に出しきれなかったイベントも出す。
    expect(find.text('ライブ3'), findsOneWidget);
    // ホームのタブの中で開き、戻るとホームに戻る（画面定義書 5.1.8）。
    expect(currentTab(tester), 0);
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(find.byType(EventListScreen), findsNothing);
    expect(currentTab(tester), 0);
    expect(find.text('ライブ1'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ホームを開いているときに下部ナビのホームを押すと、いちばん上まで戻る', (tester) async {
    data.follows.add(sampleFollow());
    for (var i = 0; i < 10; i++) {
      data.posts.add(
        samplePost(
          id: 'x:$i',
          source: SnsService.x,
          kind: PostKind.text,
          text: '投稿$i',
          postedAt: DateTime.now().subtract(Duration(minutes: 10 + i)),
        ),
      );
    }
    await pumpHome(tester);
    final scrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    final position = tester.state<ScrollableState>(scrollable.first).position;
    position.jumpTo(600);
    await tester.pump();
    expect(position.pixels, 600);
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(position.pixels, 0);
    await unmount(tester);
  });

  testWidgets('初めて読み込めなければ、「読み込めませんでした」と「もう一度試す」を出す', (tester) async {
    data.failReads = true;
    await pumpHome(tester);
    expect(find.text('読み込めませんでした'), findsOneWidget);
    data.failReads = false;
    await tester.tap(find.text('もう一度試す'));
    await tester.pumpAndSettle();
    expect(find.text('推しを探しましょう'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('タイムラインと投稿ビューアの、投稿者のアイコン・名前から発信者ページへ行ける', (tester) async {
    data.follows.add(sampleFollow());
    data.posts.add(
      samplePost(
        id: 'ig:2',
        source: SnsService.instagram,
        kind: PostKind.text,
        text: 'Instagramの投稿',
        postedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    );
    await pumpHome(tester);

    // Instagram の投稿の、名前の行を押すと、発信者ページへ（X の投稿は、X の表示の決まりで X のプロフィールへ）。
    await tester.tap(
      find.descendant(
        of: find.byType(PostCard).first,
        matching: find.textContaining('星野ミナト'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('歌とゲームの配信をしています'), findsOneWidget);
    // 推しのタブで開く（画面定義書 5.1.8）。戻ると、推しリストに出る。
    expect(currentTab(tester), 2);
    Navigator.of(tester.element(find.text('歌とゲームの配信をしています'))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(OshiListBody), findsOneWidget);
    // ホームは、下部ナビで戻る。
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    // YouTube の投稿の、アイコンを押すと、発信者ページへ。
    await tester.dragUntilVisible(
      find.text('新しい動画'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('新しい動画'),
          matching: find.byType(PostCard),
        ),
        matching: find.byType(AvatarImage),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('歌とゲームの配信をしています'), findsOneWidget);
    expect(find.byType(PostViewerScreen), findsNothing);
    Navigator.of(tester.element(find.text('歌とゲームの配信をしています'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    // 投稿のほかの場所はビューアを開き、ビューアの名前を押すと、閉じて発信者ページへ。
    await tester.tap(find.text('新しい動画'));
    await tester.pumpAndSettle();
    expect(find.byType(PostViewerScreen), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(PostViewerScreen),
        matching: find.text('星野ミナト'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PostViewerScreen), findsNothing);
    expect(find.text('歌とゲームの配信をしています'), findsOneWidget);
    expect(currentTab(tester), 2);
    await unmount(tester);
  });

  testWidgets('ほかのタブから開くと、推しのタブを最初の画面まで戻してから開き、同じ発信者なら重ねない', (tester) async {
    data.creators.add(const Creator(id: 'sora', name: '天野ソラ'));
    data.follows.addAll([sampleFollow(), sampleFollow('sora')]);
    await pumpHome(tester);

    // 推しのタブで、推しを探す → ミナトのページまで開いておく。
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    FindCreatorsScreen.open(tester.element(find.byType(OshiListBody)));
    await tester.pumpAndSettle();
    CreatorScreen.open(
      tester.element(find.byType(FindCreatorsScreen)),
      'minato',
    );
    await tester.pumpAndSettle();
    expect(find.byType(CreatorScreen), findsOneWidget);

    // ホームからソラを開くと、推しのタブへ移り、推しリスト → ソラ になる。
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    CreatorScreen.open(tester.element(find.byType(HomeBody)), 'sora');
    await tester.pumpAndSettle();
    expect(currentTab(tester), 2);
    expect(
      tester.widget<CreatorScreen>(find.byType(CreatorScreen)).creatorId,
      'sora',
    );
    Navigator.of(tester.element(find.byType(CreatorScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(CreatorScreen), findsNothing);
    expect(find.byType(FindCreatorsScreen), findsNothing);
    expect(find.byType(OshiListBody), findsOneWidget);

    // いちばん上に同じ発信者が出ていれば、タブを移るだけで、重ねない。
    CreatorScreen.open(tester.element(find.byType(OshiListBody)), 'sora');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    CreatorScreen.open(tester.element(find.byType(HomeBody)), 'sora');
    await tester.pumpAndSettle();
    expect(currentTab(tester), 2);
    Navigator.of(tester.element(find.byType(CreatorScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(OshiListBody), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('下部ナビは、ホーム・スケジュール・推しリストの順で、横に払ってもタブは移らない', (tester) async {
    await pumpHome(tester);
    final icons = [
      Icons.home,
      Icons.schedule_outlined,
      Icons.star_outline,
    ].map((i) => tester.getCenter(find.byIcon(i)).dx).toList();
    expect(icons[0] < icons[1] && icons[1] < icons[2], isTrue);
    // ホームから左へ払っても、ホームのまま。
    await tester.fling(
      find.byType(PageView).first,
      const Offset(-500, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    // 下部ナビを押すと、スケジュールへ。
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('キーボードを出しても、一覧は縮むのが1回だけで、ナビはキーボードの後ろに残る', (tester) async {
    // 推しを探すの「おすすめ」に出す、フォローしていない発信者（0人なら見出しを出さない）。
    data
      ..creators.add(hiyori())
      ..follows.add(sampleFollow());
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    final navBottom = tester.getBottomLeft(find.byIcon(Icons.star)).dy;

    // キーボード（画面の下 300）を出す。
    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(find.text('星野ミナト'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('星野ミナト')).dy,
      lessThan(screenHeight - 300),
    );
    // 一覧は、キーボードのすぐ上まで使う（2回縮まない）。
    final list = tester.getRect(find.byType(CustomScrollView).first);
    expect(list.bottom, moreOrLessEquals(screenHeight - 300, epsilon: 1));
    // ナビは動かない（キーボードの後ろに残る）。
    expect(tester.getBottomLeft(find.byIcon(Icons.star)).dy, navBottom);

    // キーボードを出したまま、推しを探すを開いても、推しリストのタブのまま。
    await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
    await tester.pumpAndSettle();
    expect(find.text('おすすめ'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('英語では、ホームと設定を英語で出す', (tester) async {
    data.onboardingDone = true;
    await pumpScreen(
      tester,
      data,
      const HomeShell(),
      locale: const Locale('en'),
    );
    expect(find.text('Find your favorites'), findsOneWidget);
    expect(find.text('推しを探しましょう'), findsNothing);
    await unmount(tester);

    await pumpScreen(
      tester,
      data,
      const SettingsScreen(),
      locale: const Locale('en'),
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Use device setting'), findsWidgets);
    expect(find.text('Register as a creator'), findsOneWidget);
    // 検索も、表示言語の名前で探す。
    await tester.enterText(find.byType(TextField), 'lang');
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    await unmount(tester);
  });

  testWidgets('設定は、下部ナビのタブで開く（ホームのヘッダーに歯車は置かない）', (tester) async {
    await pumpHome(tester);
    expect(find.byIcon(Icons.settings), findsNothing);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(currentTab(tester), 3);
    // タブの本体なので、戻るは出さない。下部ナビは出したまま。
    expect(find.byTooltip('戻る'), findsNothing);
    expect(find.byType(AppBottomNav), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('発信者でなければ、下部ナビに発信者のタブの丸を出さない', (tester) async {
    await pumpHome(tester);
    expect(find.bySemanticsLabel('発信者メニュー'), findsNothing);
    expect(
      tester.widget<AppBottomNav>(find.byType(AppBottomNav)).creator,
      isNull,
    );
    await unmount(tester);
  });

  testWidgets('ログインの処理を通らずに、セッションが発信者のオーナーに切り替わっても、発信者のタブを出す', (tester) async {
    await pumpHome(tester);
    expect(find.bySemanticsLabel('発信者メニュー'), findsNothing);
    // ログインのシートが失敗扱いにしたのに、セッションだけ切り替わったときなど。
    data.ownedCreatorId = 'minato';
    data.switchSessionUser('owner-1');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('発信者メニュー'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('セッションのユーザーが同じままなら、読み直さない', (tester) async {
    await pumpHome(tester);
    data.ownedCreatorId = 'minato';
    data.switchSessionUser(data.userId ?? 'user-a');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('発信者メニュー'), findsNothing);
    await unmount(tester);
  });

  testWidgets('縮小しても、下部ナビは3つのタブのまま小さくなり、押せる', (tester) async {
    await pumpHome(tester);
    homeContainer(
      tester,
    ).read(homeShellViewModelProvider.notifier).setNavCollapsed(true);
    await tester.pumpAndSettle();
    final buttons = find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.byType(InkWell),
    );
    expect(buttons, findsNWidgets(5));
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    expect(currentTab(tester), 2);
    await unmount(tester);
  });

  testWidgets('下部ナビのタブには、読み上げの名前がある', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);
    final tabs = find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.byType(InkWell),
    );
    // 左から、ホーム・固定ビューアのスイッチ（コントローラー）・楕円（スケジュール・推しリスト・設定）。
    expect(tabs, findsNWidgets(5));
    for (final (i, label) in [
      'ホーム',
      '固定ビューア',
      'スケジュール',
      '推しリスト',
      '設定',
    ].indexed) {
      expect(
        tester.getSemantics(tabs.at(i)),
        isSemantics(label: label, isButton: true),
      );
    }
    semantics.dispose();
    await unmount(tester);
  });
}

int currentTab(WidgetTester tester) =>
    tester.widget<AppBottomNav>(find.byType(AppBottomNav)).currentIndex;
