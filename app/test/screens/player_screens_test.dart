import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/core/ui/post_video.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  Finder inViewer(Finder matching) =>
      find.descendant(of: find.byType(PostViewerScreen), matching: matching);

  /// ビューアの「固定する」で、投稿の動画を小窓に流す。
  Future<void> minimizeViewer(WidgetTester tester) async {
    await tester.tap(inViewer(find.byTooltip('固定ビューアで流す')));
    await settleFrames(tester);
    expect(find.byType(PostViewerScreen), findsNothing);
  }

  /// 投稿の動画の小窓を押して、ビューアで開き直す。
  Future<void> openMini(WidgetTester tester) async {
    // YouTube の映像を押しても開かない（YouTube の規約）ので、映像の下の帯を押す。
    final video = tester.getRect(find.byType(PostVideo));
    await tester.tapAt(Offset(video.left + 20, video.bottom + 16));
    await settleFrames(tester);
    expect(find.byType(PostViewerScreen), findsOneWidget);
  }

  /// ビューアの、下のアイコン・名前を押せるか。
  bool authorTappable(WidgetTester tester) =>
      tester
          .widget<GestureDetector>(
            find
                .ancestor(
                  of: inViewer(find.text('星野ミナト')),
                  matching: find.byType(GestureDetector),
                )
                .first,
          )
          .onTap !=
      null;

  testWidgets('配信中の発信者ページから開いたビューアで固定ビューアのボタンを押すと、投稿の動画を固定ビューアで流す', (
    tester,
  ) async {
    data.creators[0] = sampleCreator(live: sampleLive());
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tester.tap(find.byType(OshiAvatar).first);
    await settleFrames(tester);
    final page = find.byType(CreatorScreen);
    expect(page, findsOneWidget);

    await tester.ensureVisible(find.text('新しい動画').first);
    await tester.tap(find.text('新しい動画').first);
    await settleFrames(tester);
    expect(find.byType(PostViewerScreen), findsOneWidget);
    await minimizeViewer(tester);

    // 投稿の動画を固定ビューアで流し、スイッチも入れる。
    expect(homeContainer(tester).read(playbackProvider), isA<PostPlayback>());
    expect(homeContainer(tester).read(fixedViewerOnProvider), isTrue);
    expect(find.byType(PostVideo), findsOneWidget);
    expect(page, findsOneWidget);
    // 帯には、配信に切り替えるボタンと、ランダム再生に切り替えるボタンを出す。
    expect(find.byTooltip('配信に切り替える'), findsOneWidget);
    expect(find.byTooltip('推しの動画をランダムに流す'), findsOneWidget);

    // 配信に切り替えるボタンで、配信中の推しの配信を流す。
    await tester.tap(find.byTooltip('配信に切り替える'));
    await settleFrames(tester);
    expect(homeContainer(tester).read(playbackProvider), isA<LivePlayback>());
    expect(find.byType(PostVideo), findsNothing);
    await unmount(tester);
  });

  testWidgets('小窓から開き直したビューアで、投稿者を押せるのは、ホームから小窓にしたときだけ', (tester) async {
    data.follows.add(sampleFollow());
    // 発信者ページの投稿が、下部ナビに隠れずに押せるよう、縦を長くする。
    usePhoneScreen(tester, size: const Size(1170, 3300));
    await pumpHome(tester);

    // ホームから開いたビューア：押せる。
    await tester.tap(find.text('新しい動画').first);
    await settleFrames(tester);
    expect(authorTappable(tester), isTrue);
    await minimizeViewer(tester);
    await openMini(tester);
    expect(authorTappable(tester), isTrue);
    await tester.tap(inViewer(find.byTooltip('閉じる')));
    await settleFrames(tester);

    // 発信者ページから開いたビューア：押せない。
    await tester.tap(find.byType(OshiAvatar).first);
    await settleFrames(tester);
    expect(find.byType(CreatorScreen), findsOneWidget);
    await tester.ensureVisible(find.text('新しい動画').first);
    await tester.tap(find.text('新しい動画').first);
    await settleFrames(tester);
    expect(authorTappable(tester), isFalse);
    await minimizeViewer(tester);
    await openMini(tester);
    expect(authorTappable(tester), isFalse);
    await tester.tap(inViewer(find.byTooltip('閉じる')));
    await settleFrames(tester);
    await unmount(tester);
  });
}
