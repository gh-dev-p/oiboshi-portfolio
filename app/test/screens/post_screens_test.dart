import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/post_manage_screen.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_parts.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  testWidgets('投稿を押すと全画面のビューアが開き、上下スワイプで次の投稿に移る', (tester) async {
    // 発信者ページのカバー（横3：縦1）が画面の幅で伸びるので、縦を長くして投稿まで出す。
    usePhoneScreen(tester, size: const Size(2400, 3600));
    data.posts.add(
      samplePost(
        id: 'x:2',
        source: SnsService.x,
        kind: PostKind.text,
        text: '2つ目の投稿',
        postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    );
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.ensureVisible(find.text('新しい動画'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新しい動画'));
    // 読み込み中の印は動き続けるので、落ち着くまで待たずに、開く動きの分だけ進める。
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PostViewerScreen), findsOneWidget);
    expect(find.text('開く'), findsOneWidget);
    // YouTube の動画は、公式プレイヤーで再生する。
    expect(find.byKey(const Key('fake-webview')), findsOneWidget);
    expect(FakeWebViewPlatform.loadedHtml.last, contains('"1"'));
    // 再生が始まるまでは、プレイヤーの上にサムネイルと読み込み中の印を出す。
    final loading = find.descendant(
      of: find.byType(PostViewerScreen),
      matching: find.byType(CircularProgressIndicator),
    );
    expect(loading, findsOneWidget);
    FakeWebViewPlatform.channels.last.onMessageReceived(
      const JavaScriptMessage(message: 'started'),
    );
    await tester.pumpAndSettle();
    expect(loading, findsNothing);

    await tester.fling(find.byType(PageView), const Offset(0, -600), 1500);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PostViewerScreen),
        matching: find.text('2つ目の投稿'),
      ),
      findsOneWidget,
    );
    // 表示中でないページのプレイヤーは作らない。
    expect(find.byKey(const Key('fake-webview')), findsNothing);

    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(find.byType(PostViewerScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('ビューアの固定ビューアのボタンで、動画を見ていた位置から固定ビューアに流し、ビューアを閉じる', (tester) async {
    // 発信者ページのカバー（横3：縦1）が画面の幅で伸びるので、縦を長くして投稿まで出す。
    usePhoneScreen(tester, size: const Size(2400, 3600));
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.ensureVisible(find.text('新しい動画'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新しい動画'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CreatorScreen)),
    );
    expect(container.read(playbackProvider), isNull);
    // 固定ビューアのボタンは、左下の、投稿者の行のすぐ上に出す。
    final screen = tester.getSize(find.byType(PostViewerScreen));
    final pin = tester.getRect(find.byTooltip('固定ビューアで流す'));
    final avatar = tester.getRect(
      find
          .descendant(
            of: find.byType(PostViewerPage),
            matching: find.byType(AvatarImage),
          )
          .first,
    );
    expect(pin.center.dx, lessThan(screen.width / 2));
    expect(pin.center.dy, greaterThan(screen.height / 2));
    expect(pin.bottom, lessThanOrEqualTo(avatar.top));
    expect(pin.left, avatar.left);
    // 右下の視聴数・「開く」は、小さく薄い字にする。押せる範囲は 48 四方より狭くしない。
    final open = tester.widget<Text>(find.text('開く'));
    expect(open.style!.fontSize, lessThanOrEqualTo(10));
    expect(open.style!.color!.a, lessThan(1));
    final openTap = tester.getSize(
      find.ancestor(of: find.text('開く'), matching: find.byType(InkWell)),
    );
    expect(openTap.width, greaterThanOrEqualTo(48));
    expect(openTap.height, greaterThanOrEqualTo(48));

    await tester.tap(find.byTooltip('固定ビューアで流す'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PostViewerScreen), findsNothing);
    final playback = container.read(playbackProvider);
    expect(playback, isA<PostPlayback>());
    playback as PostPlayback;
    expect(playback.post.id, 'yt:1');
    // フェイクのプレイヤーは、12.5 秒の位置と答える。
    expect(playback.start, const Duration(milliseconds: 12500));
    await unmount(tester);
  });

  testWidgets('ビューアで左へ払うと、動画を見ていた位置から固定ビューアで流す', (tester) async {
    // 発信者ページのカバー（横3：縦1）が画面の幅で伸びるので、縦を長くして投稿まで出す。
    usePhoneScreen(tester, size: const Size(2400, 3600));
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.ensureVisible(find.text('新しい動画'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新しい動画'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CreatorScreen)),
    );

    // 映像の外（上の黒いところ）で、左へ払う。
    await tester.flingFrom(const Offset(400, 120), const Offset(-300, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PostViewerScreen), findsNothing);
    final playback = container.read(playbackProvider);
    expect(playback, isA<PostPlayback>());
    expect((playback! as PostPlayback).post.id, 'yt:1');
    await unmount(tester);
  });

  testWidgets('画像の投稿は、左へ払っても閉じず（戻る）、右へ払うと閉じる', (tester) async {
    // 発信者ページのカバー（横3：縦1）が画面の幅で伸びるので、縦を長くして投稿まで出す。
    usePhoneScreen(tester, size: const Size(2400, 3600));
    data.posts
      ..clear()
      ..add(
        samplePost(
          id: 'ig:1',
          source: SnsService.instagram,
          kind: PostKind.image,
          text: '写真の投稿',
        ),
      );
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.ensureVisible(find.text('写真の投稿'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写真の投稿'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CreatorScreen)),
    );
    // 固定ビューアのボタンは出さない。
    expect(find.byTooltip('固定ビューアで流す'), findsNothing);

    await tester.flingFrom(const Offset(400, 120), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(PostViewerScreen), findsOneWidget);
    expect(container.read(playbackProvider), isNull);
    // 元の位置に戻っている。
    expect(
      tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(PostViewerScreen),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .x,
      0,
    );

    await tester.flingFrom(const Offset(400, 120), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(PostViewerScreen), findsNothing);
    await unmount(tester);
  });

  group('投稿を隠す', () {
    void addPost() => data.posts
      ..clear()
      ..add(
        samplePost(
          id: 'x:1',
          source: SnsService.x,
          kind: PostKind.text,
          text: '隠す投稿',
        ),
      );

    testWidgets('投稿ビューアには、オーナーでもメニューを出さない（投稿の管理で隠す）', (tester) async {
      // 発信者ページのカバー（横3：縦1）が画面の幅で伸びるので、スマホの大きさで確かめる。
      usePhoneScreen(tester);
      data.ownedCreatorId = 'minato';
      addPost();
      await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
      await tester.ensureVisible(find.text('隠す投稿'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('隠す投稿'));
      await tester.pumpAndSettle();
      expect(find.byType(PostViewerScreen), findsOneWidget);
      expect(_viewerMenu(), findsNothing);
      await unmount(tester);
    });

    Future<void> openManage(WidgetTester tester) async {
      data.ownedCreatorId = 'minato';
      addPost();
      await pumpScreen(
        tester,
        data,
        const PostManageScreen(creatorId: 'minato'),
      );
      expect(find.text('隠す投稿'), findsOneWidget);
    }

    testWidgets('投稿の管理に、隠しても元の SNS の投稿は消えないことを書く', (tester) async {
      await openManage(tester);
      expect(
        find.text('ここで隠しても、元の SNS の投稿は消えません。追星でファンに出さなくなるだけです。'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    Switch toggle(WidgetTester tester) =>
        tester.widget<Switch>(find.byType(Switch));

    testWidgets('トグルをオフにすると、投稿を隠して一覧に残す', (tester) async {
      await openManage(tester);
      expect(toggle(tester).value, isTrue);
      expect(find.text('隠す'), findsNothing);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('隠しました'), findsOneWidget);
      expect(data.hiddenPostIds, hasLength(1));
      expect(find.text('隠す投稿'), findsOneWidget);
      expect(toggle(tester).value, isFalse);
      await unmount(tester);
    });

    testWidgets('トグルをオンにすると、隠した投稿をまた出す', (tester) async {
      data.hiddenPostIds.add('x:1');
      await openManage(tester);
      expect(toggle(tester).value, isFalse);
      expect(find.text('また出す'), findsNothing);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('また出しました'), findsOneWidget);
      expect(data.hiddenPostIds, isEmpty);
      expect(toggle(tester).value, isTrue);
      await unmount(tester);
    });

    testWidgets('隠せなかったら、トグルをオンのままにし「隠せませんでした」', (tester) async {
      data.hidePostFails = true;
      await openManage(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('隠せませんでした'), findsOneWidget);
      expect(data.hiddenPostIds, isEmpty);
      expect(toggle(tester).value, isTrue);
      await unmount(tester);
    });

    testWidgets('トグルは「ファンに出す」と読み上げる', (tester) async {
      await openManage(tester);
      expect(find.bySemanticsLabel('ファンに出す'), findsOneWidget);
      await unmount(tester);
    });
  });
}

/// 投稿ビューアのメニュー。後ろの発信者ページにも「メニュー」（通報・表示しない）があるので、ビューアの中だけを探す。
Finder _viewerMenu() => find.descendant(
  of: find.byType(PostViewerScreen),
  matching: find.byTooltip('メニュー'),
);
