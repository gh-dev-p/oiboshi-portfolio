import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/ui/home/view_models/home_viewmodel.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/core/ui/live_player.dart';
import 'package:oiboshi/ui/home/widgets/home_live_panel.dart';
import 'package:oiboshi/ui/oshi/view_models/oshi_providers.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  setUp(() {
    data.creators[0] = sampleCreator(live: sampleLive());
    data.follows.add(sampleFollow());
  });

  /// 1分ごとの読み直しと同じく、配信が終わった発信者を読み直す。
  Future<void> endLive(WidgetTester tester) async {
    data.creators[0] = sampleCreator();
    homeContainer(tester).invalidate(creatorProvider('minato'));
    await settleFrames(tester);
  }

  testWidgets('発信者ページを閉じたあと、固定ビューアの配信が終わったら、知らせて、次に流すもの（推しの動画）に移る', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tester.tap(find.byType(OshiAvatar).first);
    await settleFrames(tester);
    // ページの「固定ビューアで見る」で固定ビューアに流す。ページを閉じても、流し続ける。
    await tester.tap(find.text('固定ビューアで見る'));
    await settleFrames(tester);
    Navigator.of(tester.element(find.byType(CreatorScreen))).pop();
    await settleFrames(tester);
    expect(find.byType(CreatorScreen), findsNothing);
    expect(homeContainer(tester).read(playbackProvider), isA<LivePlayback>());

    await endLive(tester);
    await settleFrames(tester);
    // ランダム再生に移ったので、知らせは1つにまとめる。
    expect(find.text('配信が終わりました。動画シャッフルモードに切り替えました'), findsOneWidget);
    // スイッチは入れたままなので、次に流すものを選ぶ。配信中の推しがいないので、推しの動画のランダム再生。
    expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
    expect(homeContainer(tester).read(playbackProvider), isA<PostPlayback>());
    // 配信のプレイヤーは消える。ホームの配信ビューアは数えない。
    expect(
      find.byElementPredicate(
        (e) =>
            e.widget is LivePlayer &&
            e.findAncestorWidgetOfExactType<HomeLivePanel>() == null,
      ),
      findsNothing,
    );
    await unmount(tester);
  });

  testWidgets('発信者ページを開いているあいだに配信が終わったら、「LIVE」の印と「固定ビューアで見る」を消し、知らせは出さない', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tester.tap(find.byType(OshiAvatar).first);
    await settleFrames(tester);
    expect(find.text('固定ビューアで見る'), findsOneWidget);

    await endLive(tester);
    expect(find.text('固定ビューアで見る'), findsNothing);
    expect(find.text('歌とゲームの配信をしています'), findsOneWidget);
    expect(homeContainer(tester).read(playbackProvider), isNull);
    expect(find.text('配信が終わりました'), findsNothing);
    await unmount(tester);
  });

  /// 3人目の推し。
  Creator kanade({Live? live}) =>
      Creator(id: 'kanade', name: '月見かなで', live: live);

  /// 配信が終わった推しを、1分ごとの読み直しと同じく読み直す。
  Future<void> endLiveOf(WidgetTester tester, String creatorId) async {
    final i = data.creators.indexWhere((c) => c.id == creatorId);
    data.creators[i] = switch (creatorId) {
      'minato' => sampleCreator(),
      'hiyori' => hiyori(),
      _ => kanade(),
    };
    homeContainer(tester).invalidate(creatorProvider(creatorId));
    await settleFrames(tester);
    await settleFrames(tester);
  }

  Future<void> tapSwitch(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('固定ビューア'));
    await settleFrames(tester);
  }

  /// スナックバーが消えるまで待つ。
  Future<void> waitSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await settleFrames(tester);
  }

  testWidgets('配信の終わりが2回続いても、2回目の「配信が終わりました」を出す', (tester) async {
    data.creators
      ..add(hiyori())
      ..add(kanade());
    data.follows
      ..add(sampleFollow('hiyori'))
      ..add(sampleFollow('kanade'));
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tapSwitch(tester);
    expect(homeContainer(tester).read(playbackProvider), isA<LivePlayback>());

    // 1回目：ほかに配信中の推しがいないので、ランダム再生に移り、知らせは1つにまとめる。
    await endLiveOf(tester, 'minato');
    expect(find.text('配信が終わりました。動画シャッフルモードに切り替えました'), findsOneWidget);
    await waitSnackBar(tester);

    // ほかの2人が配信を始めた。配信に切り替える。
    data.creators[1] = hiyori(live: liveTitled('歌枠'));
    data.creators[2] = kanade(live: liveTitled('雑談'));
    await homeContainer(tester).read(homeViewModelProvider.notifier).refresh();
    await settleFrames(tester);
    await tester.tap(find.byTooltip('配信に切り替える'));
    await settleFrames(tester);
    final playing =
        homeContainer(tester).read(playbackProvider)! as LivePlayback;
    await waitSnackBar(tester);

    // 2回目：もう1人の配信に移る。知らせは「配信が終わりました」。
    await endLiveOf(tester, playing.creatorId);
    expect(find.text('配信が終わりました'), findsOneWidget);
    final next = homeContainer(tester).read(playbackProvider);
    expect(next, isA<LivePlayback>());
    expect((next! as LivePlayback).creatorId, isNot(playing.creatorId));
    await unmount(tester);
  });

  testWidgets('終わったばかりの配信は、帯の矢印・点の行き先に入れない', (tester) async {
    data.creators.add(hiyori(live: liveTitled('歌枠')));
    data.follows.add(sampleFollow('hiyori'));
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tapSwitch(tester);
    final first = homeContainer(tester).read(playbackProvider)! as LivePlayback;
    // 配信中の推しが2人なので、帯に矢印を出す。
    expect(find.byTooltip('次の配信'), findsOneWidget);

    // 流している配信が終わった。ホームの推しの情報は古いまま（まだ配信中に見える）。
    await endLiveOf(tester, first.creatorId);
    final next = homeContainer(tester).read(playbackProvider)! as LivePlayback;
    expect(next.creatorId, isNot(first.creatorId));
    // 終わったばかりの配信へは移れないので、矢印を出さない。
    expect(find.byTooltip('次の配信'), findsNothing);
    await unmount(tester);
  });
}
