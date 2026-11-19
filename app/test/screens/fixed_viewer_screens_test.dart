import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/last_playback.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/ui/core/themes/app_colors.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/app_bottom_nav.dart';
import 'package:oiboshi/ui/core/ui/glass_surface.dart';
import 'package:oiboshi/ui/core/ui/live_strip_layout.dart';
import 'package:oiboshi/ui/core/ui/post_video.dart';
import 'package:oiboshi/ui/core/view_models/audio_focus_provider.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/core/ui/live_player.dart';
import 'package:oiboshi/ui/creator/widgets/fixed_viewer_strip.dart';
import 'package:oiboshi/ui/creator_admin/widgets/creator_menu_screen.dart';
import 'package:oiboshi/ui/home/view_models/home_viewmodel.dart';
import 'package:oiboshi/ui/oshi/widgets/find_creators_screen.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/core/ui/post_cards.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_parts.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

/// 固定ビューアと、下部ナビのスイッチ（機能仕様書 4.3.5、画面定義書（ファン向け）2.4.3）。
void main() {
  setUpScreenTests();

  Future<void> tapSwitch(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('固定ビューア'));
    await settleFrames(tester);
  }

  testWidgets('スイッチを入れると、配信中の推しの配信を流し、切ると閉じる。切ったことは端末に残す', (tester) async {
    data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    // 前にユーザーが切っていたので、切ってある。
    expect(homeContainer(tester).read(fixedViewerOnProvider), isFalse);
    expect(homeContainer(tester).read(playbackProvider), isNull);

    // 入れると、推しの動画（YouTube の動画）があっても、配信を優先して流す。切った記録は消す。
    await tapSwitch(tester);
    expect(data.fixedViewerUserOff, isFalse);
    final playback = homeContainer(tester).read(playbackProvider);
    expect(playback, isA<LivePlayback>());
    expect((playback! as LivePlayback).live.title, '朝の雑談');

    // 切ると、閉じて、切ったことを覚える。
    await tapSwitch(tester);
    expect(data.fixedViewerUserOff, isTrue);
    expect(homeContainer(tester).read(playbackProvider), isNull);
    await unmount(tester);
  });

  group('スイッチの初めの状態（機能仕様書 4.3.5）', () {
    setUp(() => data.fixedViewerUserOff = false);

    testWidgets('推しが1人以上なら、開いたときから流す', (tester) async {
      data
        ..creators[0] = sampleCreator(live: liveTitled('朝の雑談'))
        ..follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await settleFrames(tester);
      expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
      expect(homeContainer(tester).read(playbackProvider), isA<LivePlayback>());
      await unmount(tester);
    });

    testWidgets('推しが0人なら入れず、推しを足した画面では何もせず、次にホームを開いたときに入れる', (tester) async {
      data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
      usePhoneScreen(tester);
      await pumpHome(tester);
      await settleFrames(tester);
      final container = homeContainer(tester);
      expect(container.read(fixedViewerOnProvider), isFalse);
      expect(find.byType(FixedViewerEmptyPanel), findsNothing);

      // 推しリストのタブから推しを探すを開き、1人目をフォローする。その画面では、まだ入れない。
      await tester.tap(find.byIcon(Icons.star_outline));
      await settleFrames(tester);
      await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
      await settleFrames(tester);
      await tester.tap(find.text('フォロー').first);
      await settleFrames(tester);
      expect(data.follows, hasLength(1));
      expect(container.read(fixedViewerOnProvider), isFalse);

      // ホームを開くと、入れて流す。ユーザーが切ったとは記録していない。
      await tester.tap(find.byIcon(Icons.home_outlined));
      await settleFrames(tester);
      expect(container.read(fixedViewerOnProvider), isTrue);
      expect(container.read(playbackProvider), isA<LivePlayback>());
      expect(data.fixedViewerUserOff, isFalse);
      await unmount(tester);
    });

    testWidgets('ユーザーが切ったら、開き直しても切ったまま', (tester) async {
      data
        ..creators[0] = sampleCreator(live: liveTitled('朝の雑談'))
        ..follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await settleFrames(tester);
      expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
      await tapSwitch(tester);
      expect(data.fixedViewerUserOff, isTrue);
      await unmount(tester);

      // 開き直す。
      await pumpHome(tester);
      await settleFrames(tester);
      expect(homeContainer(tester).read(fixedViewerOnProvider), isFalse);
      expect(homeContainer(tester).read(playbackProvider), isNull);
      await unmount(tester);
    });

    testWidgets('推しをまた0人に戻したら切り、切ったとは記録しない', (tester) async {
      data
        ..creators[0] = sampleCreator(live: liveTitled('朝の雑談'))
        ..follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await settleFrames(tester);
      final container = homeContainer(tester);
      expect(container.read(fixedViewerOnProvider), isTrue);

      // 推しリストで、フォローを外す。
      await tester.tap(find.byIcon(Icons.star_outline));
      await settleFrames(tester);
      await tester.tap(find.text('フォロー中'));
      await settleFrames(tester);
      expect(data.follows, isEmpty);
      expect(container.read(fixedViewerOnProvider), isFalse);
      expect(container.read(playbackProvider), isNull);
      expect(data.fixedViewerUserOff, isFalse);
      await unmount(tester);
    });
  });

  testWidgets('配信中の推しがいなければ、推しの動画をランダムに流し、帯のボタンで配信と切り替える', (tester) async {
    data.creators.add(hiyori());
    data.follows
      ..add(sampleFollow())
      ..add(sampleFollow('hiyori'));
    usePhoneScreen(tester);
    await pumpHome(tester);

    await tapSwitch(tester);
    final playback = homeContainer(tester).read(playbackProvider);
    expect(playback, isA<PostPlayback>());
    expect((playback! as PostPlayback).shuffle, isNotNull);
    // 帯には、前後の動画の矢印を出す。配信中の推しがいないので、配信に切り替えるボタンは出さない。
    expect(find.byTooltip('次の動画'), findsOneWidget);
    expect(find.byTooltip('配信に切り替える'), findsNothing);

    // 推しが配信を始めた。ホームの読み直しで分かると、帯に配信に切り替えるボタンが出る。
    data.creators[1] = hiyori(live: liveTitled('歌枠'));
    await homeContainer(tester).read(homeViewModelProvider.notifier).refresh();
    await settleFrames(tester);
    await tester.tap(find.byTooltip('配信に切り替える'));
    await settleFrames(tester);
    final playing = homeContainer(tester).read(playbackProvider);
    expect(playing, isA<LivePlayback>());
    expect((playing! as LivePlayback).creatorId, 'hiyori');

    // 配信からは、ランダム再生に切り替える。
    await tester.tap(find.byTooltip('推しの動画をランダムに流す'));
    await settleFrames(tester);
    expect(homeContainer(tester).read(playbackProvider), isA<PostPlayback>());
    await unmount(tester);
  });

  group('続きから流す（機能仕様書 4.3.5）', () {
    testWidgets('最後に流していた推しの動画を、その位置から、ランダム再生の1本目として流す（配信中の推しがいても）', (
      tester,
    ) async {
      data
        ..creators[0] = sampleCreator(live: liveTitled('朝の雑談'))
        ..follows.add(sampleFollow())
        ..lastPlayback = const LastVideo(
          postId: 'yt:1',
          position: Duration(seconds: 83),
        );
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);
      final playback =
          homeContainer(tester).read(playbackProvider)! as PostPlayback;
      expect(playback.post.id, 'yt:1');
      expect(playback.start, const Duration(seconds: 83));
      expect(playback.shuffle, isNotNull);

      // 切ると閉じるが、動画と位置は覚えたまま（次に開いたときに使う）。
      await tapSwitch(tester);
      expect(homeContainer(tester).read(playbackProvider), isNull);
      expect(data.lastPlayback, isA<LastVideo>());
      expect((data.lastPlayback! as LastVideo).postId, 'yt:1');
      await unmount(tester);
    });

    testWidgets('最後に流していた動画が、いまは流せなければ、ふだんどおり配信を流し、それを覚える', (tester) async {
      data
        ..creators[0] = sampleCreator(live: liveTitled('朝の雑談'))
        ..follows.add(sampleFollow())
        ..lastPlayback = const LastVideo(
          postId: 'yt:消した動画',
          position: Duration(seconds: 10),
        );
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);
      expect(homeContainer(tester).read(playbackProvider), isA<LivePlayback>());
      expect(data.lastPlayback, const LastLive('minato'));
      await unmount(tester);
    });

    testWidgets('最後に流していた配信がまだ配信中なら、その配信を流す。終わっていれば、ふだんどおり', (tester) async {
      data
        ..creators[0] = sampleCreator(live: liveTitled('朝の雑談'))
        ..creators.add(hiyori(live: liveTitled('歌枠')))
        ..follows.add(sampleFollow())
        ..follows.add(sampleFollow('hiyori'))
        ..lastPlayback = const LastLive('hiyori');
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);
      expect(
        (homeContainer(tester).read(playbackProvider)! as LivePlayback)
            .creatorId,
        'hiyori',
      );
      await unmount(tester);

      // ひよりの配信が終わっていれば、配信中の推し（ふだんの順）を流す。
      data
        ..creators[1] = hiyori()
        ..fixedViewerUserOff = true
        ..lastPlayback = const LastLive('hiyori');
      await pumpHome(tester);
      await tapSwitch(tester);
      expect(
        (homeContainer(tester).read(playbackProvider)! as LivePlayback)
            .creatorId,
        'minato',
      );
      await unmount(tester);
    });
  });

  testWidgets('推しの誰かが配信中の間だけ、コントローラーのアイコンの左上と、開いたときの配信のアイコンに赤い点を出す', (
    tester,
  ) async {
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    final dot = find.byKey(const ValueKey('viewer-live-dot'));
    final iconDot = find.byKey(const ValueKey('controller-live-dot'));
    final controller = find.bySemanticsLabel('固定ビューア');
    // 触れている間（ヒントを出している間）の、点の数。
    Future<int> dotsWhileTouching() async {
      final gesture = await tester.startGesture(tester.getCenter(controller));
      await tester.pump();
      final count = dot.evaluate().length;
      await gesture.cancel();
      await settleFrames(tester);
      return count;
    }

    expect(dot, findsNothing);
    expect(iconDot, findsNothing);
    expect(await dotsWhileTouching(), 0);

    // 推しが配信を始めた。ホームの読み直しで分かると、点を出す。
    data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
    await homeContainer(tester).read(homeViewModelProvider.notifier).refresh();
    await settleFrames(tester);
    // コントローラーのアイコンの左上（配信のヒントの向き）に出す。
    expect(dot, findsNothing);
    expect(iconDot, findsOneWidget);
    final icon = find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Icon &&
            (w.icon == Icons.smart_display ||
                w.icon == Icons.smart_display_outlined),
      ),
    );
    expect(tester.getCenter(iconDot).dx, lessThan(tester.getCenter(icon).dx));
    expect(tester.getCenter(iconDot).dy, lessThan(tester.getCenter(icon).dy));
    // 開いたときの、上左の配信のアイコンにも出す。
    final gesture = await tester.startGesture(tester.getCenter(controller));
    await tester.pump();
    expect(dot, findsOneWidget);
    expect(
      find.ancestor(
        of: dot,
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '配信に切り替える',
        ),
      ),
      findsOneWidget,
    );
    // アイコンは丸の真ん中のまま（点を付けても、ずれない）。
    final liveIcon = find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.byIcon(Icons.sensors),
    );
    expect(
      tester.getCenter(liveIcon),
      tester.getCenter(
        find.ancestor(of: liveIcon, matching: find.byType(GlassSurface)),
      ),
    );
    await gesture.cancel();
    await settleFrames(tester);
    expect(dot, findsNothing);

    // 配信が終わると、消す。
    data.creators[0] = sampleCreator();
    await homeContainer(tester).read(homeViewModelProvider.notifier).refresh();
    await settleFrames(tester);
    expect(iconDot, findsNothing);
    expect(await dotsWhileTouching(), 0);
    await unmount(tester);
  });

  testWidgets(
    '推しに新しい動画がある間だけ、コントローラーのアイコンの右上と、開いたときの動画シャッフルのアイコンに NEW の色の点を出す',
    (tester) async {
      // 2日前にフォローし、そのあと（1時間前）に動画が投稿された。
      data.follows.add(
        Follow(
          creatorId: 'minato',
          followedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      );
      usePhoneScreen(tester);
      await pumpHome(tester);
      final dot = find.byKey(const ValueKey('viewer-new-dot'));
      final iconDot = find.byKey(const ValueKey('controller-new-dot'));
      final controller = find.bySemanticsLabel('固定ビューア');
      expect(dot, findsNothing);
      // コントローラーのアイコンの右上（動画シャッフルのヒントの向き）に出す。
      expect(iconDot, findsOneWidget);
      expect(find.byKey(const ValueKey('controller-live-dot')), findsNothing);
      final icon = find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Icon &&
              (w.icon == Icons.smart_display ||
                  w.icon == Icons.smart_display_outlined),
        ),
      );
      expect(
        tester.getCenter(iconDot).dx,
        greaterThan(tester.getCenter(icon).dx),
      );
      expect(tester.getCenter(iconDot).dy, lessThan(tester.getCenter(icon).dy));
      final iconDotColor =
          (tester
                      .widget<Container>(
                        find.descendant(
                          of: iconDot,
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .color;
      expect(iconDotColor, AppColors.light.accentNavy);
      final gesture = await tester.startGesture(tester.getCenter(controller));
      await tester.pump();
      expect(dot, findsOneWidget);
      expect(
        find.ancestor(
          of: dot,
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '推しの動画をランダムに流す',
          ),
        ),
        findsOneWidget,
      );
      final color =
          (tester
                      .widget<Container>(
                        find.descendant(
                          of: dot,
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .color;
      expect(color, AppColors.light.accentNavy);
      await gesture.cancel();
      await settleFrames(tester);
      await unmount(tester);
    },
  );

  testWidgets('動画シャッフルには、生配信（配信中・配信予定）の枠を入れず、終わった配信のアーカイブは入れる（機能仕様書 4.3.5.1）', (
    tester,
  ) async {
    data.posts
      ..clear()
      ..add(samplePost(id: 'yt:live', text: '24時間配信', isLiveContent: true))
      ..add(samplePost(id: 'yt:soon', text: '配信予定', isLiveContent: true))
      ..add(samplePost(id: 'yt:archive', text: '昨日の配信のアーカイブ'));
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tapSwitch(tester);
    final container = homeContainer(tester);
    for (var i = 0; i < 5; i++) {
      final playback = container.read(playbackProvider)! as PostPlayback;
      expect(playback.post.id, 'yt:archive');
      container.read(playbackProvider.notifier).stepShuffle(1);
      await settleFrames(tester);
    }
    await unmount(tester);
  });

  testWidgets('流すものがなければ、推しを探す案内を出し、押すと推しを探すを開く', (tester) async {
    data.posts.clear();
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);

    await tapSwitch(tester);
    expect(homeContainer(tester).read(playbackProvider), isNull);
    expect(find.text('配信や動画を投稿している推しを見つけよう'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '推しを探す'));
    await settleFrames(tester);
    expect(find.byType(FindCreatorsScreen), findsOneWidget);

    // スイッチを切ると、案内も消す。
    await tapSwitch(tester);
    expect(find.text('配信や動画を投稿している推しを見つけよう'), findsNothing);
    await unmount(tester);
  });

  testWidgets('発信者の下部ナビは、アイコン・スイッチ・3つのタブで、設定は発信者メニューの歯車から開く', (tester) async {
    data.ownedCreatorId = 'minato';
    final semantics = tester.ensureSemantics();
    usePhoneScreen(tester);
    await pumpHome(tester);

    final buttons = find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.byType(InkWell),
    );
    expect(buttons, findsNWidgets(5));
    for (final (i, label) in [
      '発信者メニュー',
      '固定ビューア',
      'ホーム',
      'スケジュール',
      '推しリスト',
    ].indexed) {
      expect(
        tester.getSemantics(buttons.at(i)),
        isSemantics(label: label, isButton: true),
      );
    }

    await tester.tap(buttons.at(0));
    await settleFrames(tester);
    expect(find.byType(CreatorMenuScreen), findsOneWidget);
    await tester.tap(find.byTooltip('設定'));
    await settleFrames(tester);
    expect(
      tester.widget<AppBottomNav>(find.byType(AppBottomNav)).currentIndex,
      3,
    );
    semantics.dispose();
    await unmount(tester);
  });

  group('投稿ビューアを開いている間（機能仕様書 4.3.5）', () {
    for (final service in [
      SnsService.youtube,
      SnsService.twitcasting,
      SnsService.twitch,
    ]) {
      testWidgets('${service.name} の配信は、固定ビューアの下に投稿ビューアを出し、止めずに流し続ける', (
        tester,
      ) async {
        data.creators[0] = sampleCreator(
          live: liveTitled('朝の雑談', service: service),
        );
        data.posts.add(
          samplePost(
            id: 'x:1',
            source: SnsService.x,
            kind: PostKind.text,
            text: '今日のひとこと',
          ),
        );
        data.follows.add(sampleFollow());
        usePhoneScreen(tester);
        await pumpHome(tester);
        await tapSwitch(tester);
        expect(find.byType(LivePlayer), findsOneWidget);

        await tester.tap(find.text('今日のひとこと').first);
        await settleFrames(tester);
        expect(find.byType(PostViewerScreen), findsOneWidget);
        expect(find.byType(LivePlayer), findsOneWidget);
        // 投稿ビューアは、固定ビューア（映像と帯）の下から始める（固定ビューアを隠さない）。
        final viewer = find.descendant(
          of: find.byType(PostViewerScreen),
          matching: find.byType(Scaffold),
        );
        expect(
          tester.getTopLeft(viewer).dy,
          tester.getBottomLeft(find.byType(FixedViewerStrip)).dy,
        );

        await tester.tap(find.byTooltip('閉じる'));
        await settleFrames(tester);
        expect(find.byType(LivePlayer), findsOneWidget);
        await unmount(tester);
      });
    }

    // 固定ビューアでの再生を優先する。固定ビューアを開いている間は、投稿の動画は押すまで流さず、
    // 押して流している間だけ固定ビューアを一時停止する（機能仕様書 4.3.5、2026-11-19 本人）。
    Future<void> sendPostPlayer(
      WidgetTester tester,
      JavaScriptChannelParams channel,
      String message,
    ) async {
      channel.onMessageReceived(JavaScriptMessage(message: message));
      await settleFrames(tester);
    }

    testWidgets('固定ビューアを開いている間は、投稿の YouTube を自動で流さず、押して流している間だけ固定ビューアを止める', (
      tester,
    ) async {
      data.creators[0] = sampleCreator(
        live: liveTitled('朝の雑談', service: SnsService.youtube),
      );
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);
      final container = homeContainer(tester);
      expect(find.byType(LivePlayer), findsOneWidget);

      await tester.tap(find.text('新しい動画').first);
      await settleFrames(tester);
      // 開いただけでは流さない。サムネイルと再生のマークを出し、固定ビューアは流したまま。
      final playMark = find.descendant(
        of: find.byType(PostViewerScreen),
        matching: find.byType(PlayMark),
      );
      expect(playMark, findsOneWidget);
      expect(find.byType(LivePlayer), findsOneWidget);
      expect(container.read(viewerVideoPlayingProvider), isFalse);

      // 押すと流し、流れている間は、固定ビューアを止める（流すものは変えない）。
      await tester.tap(playMark);
      await settleFrames(tester);
      expect(playMark, findsNothing);
      // 投稿の動画のプレイヤーは、押したあと、いちばん新しく作った WebView。
      final post = FakeWebViewPlatform.channels.last;
      await sendPostPlayer(tester, post, 'playing');
      expect(container.read(viewerVideoPlayingProvider), isTrue);
      expect(find.byType(LivePlayer), findsNothing);
      expect(container.read(playbackProvider), isA<LivePlayback>());

      // 投稿の動画を止めたら、固定ビューアを流し直す。
      await sendPostPlayer(tester, post, 'paused');
      expect(container.read(viewerVideoPlayingProvider), isFalse);
      expect(find.byType(LivePlayer), findsOneWidget);

      // また流して、閉じたら、固定ビューアを流し直す。
      await sendPostPlayer(tester, post, 'playing');
      expect(find.byType(LivePlayer), findsNothing);
      await tester.tap(find.byTooltip('閉じる'));
      await settleFrames(tester);
      expect(container.read(viewerVideoPlayingProvider), isFalse);
      expect(find.byType(LivePlayer), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('固定ビューアを開いている間は、投稿の動画ファイルも自動で流さず、再生のマークを出す', (tester) async {
      data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
      data.posts.add(
        samplePost(
          id: 'x:video',
          source: SnsService.x,
          kind: PostKind.video,
          text: 'Xの動画',
          thumbnailUrl: 'https://example.com/v.jpg',
          videoUrl: 'https://example.com/v.mp4',
        ),
      );
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);
      await tester.tap(find.text('Xの動画').first);
      await settleFrames(tester);
      expect(
        find.descendant(
          of: find.byType(PostViewerScreen),
          matching: find.byType(PlayMark),
        ),
        findsOneWidget,
      );
      expect(homeContainer(tester).read(viewerVideoPlayingProvider), isFalse);
      expect(find.byType(LivePlayer), findsOneWidget);

      // 後ろを塞がないので、投稿ビューアを開いたまま、固定ビューアの帯のボタンを押せる。
      await tester.tap(find.byTooltip('推しの動画をランダムに流す'));
      await settleFrames(tester);
      expect(homeContainer(tester).read(playbackProvider), isA<PostPlayback>());
      expect(find.byType(PostViewerScreen), findsOneWidget);
      // 隠れたタブの画面には、モードの知らせを出さない。
      expect(find.text('動画シャッフルモードに切り替えました'), findsNothing);
      await tester.tap(find.byTooltip('閉じる'));
      await settleFrames(tester);
      await unmount(tester);
    });

    // 中身（画像・文章）を、上の閉じるボタンと、下の投稿者の行・本文・右の操作を避けた残りの、上下の真ん中に置く
    // （画面定義書 2.5.1、2026-11-19 本人）。
    for (final (kind, label) in [
      (PostKind.image, '写真の投稿'),
      (PostKind.text, '文字だけの投稿'),
    ]) {
      testWidgets('固定ビューアの下では、$labelの中身を上下の真ん中に置く', (tester) async {
        data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
        data.posts.add(
          samplePost(
            id: 'x:1',
            source: SnsService.x,
            kind: kind,
            text: label,
            viewCount: 15000,
            thumbnailUrl: kind == PostKind.image
                ? 'https://example.com/a.jpg'
                : null,
          ),
        );
        data.follows.add(sampleFollow());
        usePhoneScreen(tester);
        await pumpHome(tester);
        await tapSwitch(tester);
        await tester.tap(find.text(label).first);
        await settleFrames(tester);
        final page = find.byType(PostViewerPage);
        final pageRect = tester.getRect(page);
        // 中身：画像は読み込めないので灰色の面、文章は本文。
        final content = kind == PostKind.image
            ? find.descendant(of: page, matching: find.byType(PostThumbnail))
            : find.descendant(of: page, matching: find.text(label));
        final rect = tester.getRect(content.first);
        final close = tester.getRect(find.byTooltip('閉じる'));
        final panel = tester.getRect(
          find
              .ancestor(
                of: find
                    .descendant(of: page, matching: find.byType(AvatarImage))
                    .first,
                matching: find.byType(Positioned),
              )
              .first,
        );
        final side = tester.getRect(find.byType(PostViewerSideActions));
        // 中身は、閉じるボタンにも、下の行・右の操作にも重ならない。
        expect(rect.top, greaterThanOrEqualTo(close.bottom));
        expect(rect.bottom, lessThanOrEqualTo(panel.top));
        expect(rect.bottom, lessThanOrEqualTo(side.top));
        // 上と下の空きが同じ（上は閉じるボタンの帯 64、下は投稿者の行・本文と右の操作の高いほう）。
        final areaTop = pageRect.top + PostViewerPage.topReserve;
        final areaBottom = panel.top < side.top ? panel.top : side.top;
        expect(
          (rect.top - areaTop) - (areaBottom - rect.bottom),
          moreOrLessEquals(0, epsilon: 1),
        );
        await tester.tap(find.byTooltip('閉じる'));
        await settleFrames(tester);
        await unmount(tester);
      });
    }

    testWidgets('固定ビューアを出していなければ、画面全体に出す', (tester) async {
      data
        ..follows.add(sampleFollow())
        ..fixedViewerUserOff = true;
      usePhoneScreen(tester);
      await pumpHome(tester);
      expect(homeContainer(tester).read(playbackProvider), isNull);

      await tester.tap(find.text('新しい動画').first);
      await settleFrames(tester);
      final viewer = find.descendant(
        of: find.byType(PostViewerScreen),
        matching: find.byType(Scaffold),
      );
      expect(tester.getTopLeft(viewer).dy, 0);
      // 固定ビューアを出していなければ、今までどおり自動で流す（再生のマークを出さない）。
      expect(
        find.descendant(
          of: find.byType(PostViewerScreen),
          matching: find.byType(PlayMark),
        ),
        findsNothing,
      );
      await tester.tap(find.byTooltip('閉じる'));
      await settleFrames(tester);
      await unmount(tester);
    });
  });

  testWidgets('固定ビューアの投稿の動画をビューアで開いても、次のものに替えず、閉じたら同じ動画に戻る', (tester) async {
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tapSwitch(tester);
    final playing =
        homeContainer(tester).read(playbackProvider)! as PostPlayback;
    expect(playing.post.id, 'yt:1');

    // 帯の配信元のアイコンで、ビューアで開く。固定ビューアは止めるだけ（ビューアの動画だけを流す）。
    await tester.tap(find.byTooltip('投稿を開く'));
    await settleFrames(tester);
    expect(find.byType(PostViewerScreen), findsOneWidget);
    expect(
      (homeContainer(tester).read(playbackProvider)! as PostPlayback).post.id,
      'yt:1',
    );
    expect(find.byType(PostVideo), findsOneWidget);

    // 閉じると、同じ動画を固定ビューアで流し直す。
    await tester.tap(find.byTooltip('閉じる'));
    await settleFrames(tester);
    expect(find.byType(PostViewerScreen), findsNothing);
    expect(
      (homeContainer(tester).read(playbackProvider)! as PostPlayback).post.id,
      'yt:1',
    );
    expect(find.byType(PostVideo), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('配信モードと動画シャッフルモードが切り替わったら、スナックバーで知らせる', (tester) async {
    data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);

    // スイッチを入れて流し始めたときは、知らせない。
    await tapSwitch(tester);
    expect(homeContainer(tester).read(playbackProvider), isA<LivePlayback>());
    expect(find.text('配信モードに切り替えました'), findsNothing);

    await tester.tap(find.byTooltip('推しの動画をランダムに流す'));
    await settleFrames(tester);
    expect(find.text('動画シャッフルモードに切り替えました'), findsOneWidget);

    // 同じモードの中の切り替え（次の動画）では、知らせない。
    await tester.pump(const Duration(seconds: 5));
    await settleFrames(tester);
    await tester.tap(find.byTooltip('次の動画'));
    await settleFrames(tester);
    expect(find.text('動画シャッフルモードに切り替えました'), findsNothing);

    await tester.tap(find.byTooltip('配信に切り替える'));
    await settleFrames(tester);
    expect(find.text('配信モードに切り替えました'), findsOneWidget);
    await unmount(tester);
  });

  group('下部ナビのコントローラー（機能仕様書 4.3.5）', () {
    Finder controller() => find.bySemanticsLabel('固定ビューア');

    /// コントローラーを [offset] の向きにはじく。
    Future<void> flick(WidgetTester tester, Offset offset) async {
      await tester.timedDrag(
        controller(),
        offset,
        const Duration(milliseconds: 300),
      );
      await settleFrames(tester);
    }

    Playback? playing(WidgetTester tester) =>
        homeContainer(tester).read(playbackProvider);

    /// スナックバーが消えるまで待つ（次の知らせを見分けられるように）。
    Future<void> waitSnackBar(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await settleFrames(tester);
    }

    testWidgets('上へはじくと止め、もう一度はじくと流し直す', (tester) async {
      data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);
      expect(find.byType(LivePlayer), findsOneWidget);

      await flick(tester, const Offset(0, -50));
      expect(homeContainer(tester).read(fixedViewerPausedProvider), isTrue);
      expect(find.byType(LivePlayer), findsNothing);
      expect(find.text('停止しました'), findsOneWidget);

      await waitSnackBar(tester);
      await flick(tester, const Offset(0, -50));
      expect(homeContainer(tester).read(fixedViewerPausedProvider), isFalse);
      expect(find.byType(LivePlayer), findsOneWidget);
      expect(find.text('再生を再開しました'), findsOneWidget);
      // スイッチは入れたまま（押したことにしない）。
      expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
      await unmount(tester);
    });

    testWidgets('上右で動画シャッフル、上左で配信に切り替え、知らせる', (tester) async {
      data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);
      expect(playing(tester), isA<LivePlayback>());

      await flick(tester, const Offset(40, -40));
      expect(playing(tester), isA<PostPlayback>());
      expect(find.text('動画シャッフルモードに切り替えました'), findsOneWidget);

      await waitSnackBar(tester);
      await flick(tester, const Offset(-40, -40));
      expect(playing(tester), isA<LivePlayback>());
      expect(find.text('配信モードに切り替えました'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('右で次の動画、左で前の動画に切り替え、知らせる', (tester) async {
      data.creators.add(hiyori());
      data.posts.add(
        samplePost(id: 'yt:2', text: 'ひよりの動画', creatorId: 'hiyori'),
      );
      data.follows
        ..add(sampleFollow())
        ..add(sampleFollow('hiyori'));
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);
      String post() => (playing(tester)! as PostPlayback).post.id;
      final first = post();

      await flick(tester, const Offset(50, 0));
      expect(post(), isNot(first));
      expect(find.text('次の動画'), findsWidgets);

      await waitSnackBar(tester);
      await flick(tester, const Offset(-50, 0));
      expect(post(), first);
      expect(find.text('前の動画'), findsWidgets);
      await unmount(tester);
    });

    testWidgets('少ししか動かさないか、下へはじいたら、何もしない', (tester) async {
      data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);

      await flick(tester, const Offset(0, -25));
      await flick(tester, const Offset(0, 50));
      expect(playing(tester), isA<LivePlayback>());
      expect(homeContainer(tester).read(fixedViewerPausedProvider), isFalse);
      expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
      await unmount(tester);
    });

    testWidgets('触れたらすぐヒントを出してほかのメニューを隠し、滑らせて離した向きの操作をする', (tester) async {
      data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tapSwitch(tester);

      Finder inNav(IconData icon) => find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byIcon(icon),
      );
      Iterable<double> navOpacity() => tester
          .widgetList<AnimatedOpacity>(
            find.descendant(
              of: find.byType(AppBottomNav),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .map((w) => w.opacity);

      // 触れた瞬間（長押しを待たずに）、ヒントを出す。
      var gesture = await tester.startGesture(tester.getCenter(controller()));
      await tester.pump();
      // ヒント：上（停止）・上右（動画シャッフル）・上左（配信）・右（次）・左（前）。
      expect(inNav(Icons.pause), findsOneWidget);
      expect(inNav(Icons.video_library), findsOneWidget);
      expect(inNav(Icons.sensors), findsOneWidget);
      expect(inNav(Icons.chevron_right), findsOneWidget);
      expect(inNav(Icons.chevron_left), findsOneWidget);
      // ほかのメニュー（ホームの丸・楕円）は隠す。
      expect(navOpacity(), [0, 0]);

      // 動かさずに離したら、ヒントを消し、表示と非表示を切り替える。
      await gesture.up();
      await settleFrames(tester);
      expect(inNav(Icons.chevron_right), findsNothing);
      expect(navOpacity(), [1, 1]);
      expect(homeContainer(tester).read(fixedViewerOnProvider), isFalse);
      expect(playing(tester), isNull);

      // 上右へ滑らせて離すと、ヒントを出したまま、離した向き（動画シャッフル）の操作をする。
      gesture = await tester.startGesture(tester.getCenter(controller()));
      await tester.pump();
      await gesture.moveBy(const Offset(20, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(20, -20));
      await tester.pump();
      expect(inNav(Icons.video_library), findsOneWidget);
      await gesture.up();
      await settleFrames(tester);
      expect(inNav(Icons.video_library), findsNothing);
      expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
      expect(playing(tester), isA<PostPlayback>());
      expect(find.text('動画シャッフルモードに切り替えました'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('切っているときにはじいたら、入れてからその操作をする', (tester) async {
      data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      expect(homeContainer(tester).read(fixedViewerOnProvider), isFalse);

      await flick(tester, const Offset(40, -40));
      expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
      expect(playing(tester), isA<PostPlayback>());
      expect(find.text('動画シャッフルモードに切り替えました'), findsOneWidget);

      // 切って、上へはじくと、入れて流す（止めない）。最後に流していた動画を、続きから流す。
      await waitSnackBar(tester);
      await tapSwitch(tester);
      await flick(tester, const Offset(0, -50));
      expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
      expect(playing(tester), isA<PostPlayback>());
      expect(homeContainer(tester).read(fixedViewerPausedProvider), isFalse);
      await unmount(tester);
    });

    testWidgets('配信中の推しがいなければ、上左で「配信中の推しはいません」を出し、ランダム再生のまま', (tester) async {
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);

      // 切っているときは、入れて（ランダム再生で流し）、知らせる。
      await flick(tester, const Offset(-40, -40));
      expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
      final shuffle = playing(tester);
      expect(shuffle, isA<PostPlayback>());
      expect(find.text('配信中の推しはいません'), findsOneWidget);

      await waitSnackBar(tester);
      await flick(tester, const Offset(-40, -40));
      expect(playing(tester), same(shuffle));
      expect(find.text('配信中の推しはいません'), findsOneWidget);
      await unmount(tester);
    });
  });

  testWidgets('ランダム再生の帯を払うと、前後の動画に切り替え、払っている間は帯を動かさず、指の下だけふくらませる', (
    tester,
  ) async {
    data.creators.add(hiyori());
    data.posts.add(samplePost(id: 'yt:2', text: 'ひよりの動画', creatorId: 'hiyori'));
    data.follows
      ..add(sampleFollow())
      ..add(sampleFollow('hiyori'));
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tapSwitch(tester);
    String playing() =>
        (homeContainer(tester).read(playbackProvider)! as PostPlayback).post.id;
    final first = playing();

    // 帯（次の矢印の右）をつかんで動かしている間は、指の当たっているあたりだけ、帯の下をふくらませる。
    // 帯そのものの太さは変えない。
    final strip = find
        .ancestor(
          of: find.byTooltip('次の動画'),
          matching: find.byType(LiveStripLayout),
        )
        .first;
    final bulge = find.byKey(const ValueKey('strip-bulge'));
    expect(tester.getSize(bulge).height, 0);
    final from = tester.getCenter(find.byTooltip('次の動画')) + const Offset(60, 0);
    final stripLeft = tester.getRect(strip).left;
    final videoLeft = tester.getTopLeft(find.byType(PostVideo)).dx;
    final gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-20, 0));
    await settleFrames(tester);
    expect(tester.widget<LiveStripLayout>(strip).height, 32);
    // 帯は左右に動かさず、映像だけが指について動く。
    expect(tester.getRect(strip).left, stripLeft);
    expect(tester.getTopLeft(find.byType(PostVideo)).dx, lessThan(videoLeft));
    final bump = tester.getRect(bulge);
    expect(bump.height, 16);
    expect(bump.width, 96);
    // 指についてくる（指の真下に、帯の下の端から出る）。
    expect(bump.center.dx, moreOrLessEquals(from.dx - 40, epsilon: 1));
    expect(
      bump.top,
      moreOrLessEquals(tester.getRect(strip).bottom - 1, epsilon: 1),
    );
    await gesture.moveBy(const Offset(-200, 0));
    await gesture.up();
    await settleFrames(tester);
    // 左へ払うと、次の動画へ。離したら、ふくらみは引っ込める。
    final second = playing();
    expect(second, isNot(first));
    expect(tester.getSize(bulge).height, 0);

    // 右へ払うと、前の動画へ戻る。
    await tester.flingFrom(
      tester.getCenter(find.byTooltip('次の動画')) + const Offset(60, 0),
      const Offset(300, 0),
      1000,
    );
    await settleFrames(tester);
    expect(playing(), first);
    await unmount(tester);
  });

  /// 固定ビューアの動画の、公式プレイヤーからの知らせ（いちばん新しく作ったプレイヤー）。
  Future<void> sendPlayer(WidgetTester tester, String message) async {
    FakeWebViewPlatform.channels.last.onMessageReceived(
      JavaScriptMessage(message: message),
    );
    await tester.pump(const Duration(seconds: 2));
    await settleFrames(tester);
  }

  testWidgets('ランダム再生で続けて5回再生できなければ止まり、流れ始めるか、始め直すと数え直す', (tester) async {
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tapSwitch(tester);
    Playback? playing() => homeContainer(tester).read(playbackProvider);

    // 4回できなくても、次に進む。流れ始めたら、数え直す。
    for (var i = 0; i < 4; i++) {
      final before = playing();
      await sendPlayer(tester, 'failed');
      expect(playing(), isNot(same(before)));
    }
    await sendPlayer(tester, 'playing');
    for (var i = 0; i < 4; i++) {
      final before = playing();
      await sendPlayer(tester, 'failed');
      expect(playing(), isNot(same(before)));
    }
    // 流れ始めてから続けて5回目で、止まる。
    var before = playing();
    await sendPlayer(tester, 'failed');
    expect(playing(), same(before));

    // スイッチを入れ直すと、始め直す。また、できなければ次に進む。
    await tapSwitch(tester);
    await tapSwitch(tester);
    before = playing();
    expect(before, isA<PostPlayback>());
    await sendPlayer(tester, 'failed');
    expect(playing(), isNot(same(before)));
    await unmount(tester);
  });

  testWidgets('ランダム再生から開いた投稿ビューアで固定ビューアのボタンを押しても、ランダム再生を続ける', (tester) async {
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tapSwitch(tester);
    final shuffle =
        (homeContainer(tester).read(playbackProvider)! as PostPlayback).shuffle;
    expect(shuffle, isNotNull);

    await tester.tap(find.byTooltip('投稿を開く'));
    await settleFrames(tester);
    await tester.tap(find.byTooltip('固定ビューアで流す'));
    await settleFrames(tester);
    expect(find.byType(PostViewerScreen), findsNothing);
    final playback =
        homeContainer(tester).read(playbackProvider)! as PostPlayback;
    expect(playback.shuffle, same(shuffle));
    // 帯には、ランダム再生の矢印を出したまま。
    expect(find.byTooltip('次の動画'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('スイッチを入れて推しの動画を読めなければ、「読み込めませんでした」を出す', (tester) async {
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    data.failReads = true;
    await tapSwitch(tester);
    expect(homeContainer(tester).read(playbackProvider), isNull);
    expect(find.text('読み込めませんでした'), findsOneWidget);
    await unmount(tester);
  });
}
