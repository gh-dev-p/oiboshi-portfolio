import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';
import 'package:oiboshi/ui/post/widgets/zoomable_media.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

/// 投稿ビューアの画像・動画ファイルの拡大（画面定義書 2.5.1）。
void main() {
  Post image(String id, String text) => samplePost(
    id: id,
    creatorId: 'hiyori',
    source: SnsService.instagram,
    kind: PostKind.image,
    text: text,
    permalink: 'https://www.instagram.com/p/$id/',
    thumbnailUrl: 'https://cdn.example/$id.jpg',
  );

  final carousel = samplePost(
    id: 'ig:c',
    creatorId: 'hiyori',
    source: SnsService.instagram,
    kind: PostKind.carousel,
    text: 'カルーセル',
    permalink: 'https://www.instagram.com/p/c/',
    thumbnailUrl: 'https://cdn.example/c1.jpg',
    media: [
      for (var i = 1; i <= 3; i++)
        PostMedia(isVideo: false, imageUrl: 'https://cdn.example/c$i.jpg'),
    ],
  );

  Future<void> openViewer(WidgetTester tester, List<Post> posts) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noPostViewTracker],
        child: localizedApp(
          opener(
            (context) => PostViewerScreen.open(
              context,
              posts: posts,
              initialIndex: 0,
              authorOf: (_) => null,
            ),
          ),
        ),
      ),
    );
    await tapOpen(tester);
  }

  /// 画面の真ん中を、ダブルタップする。
  Future<void> doubleTap(WidgetTester tester) async {
    final center = tester.getCenter(find.byType(PostViewerScreen));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
  }

  /// 表示中の拡大の倍率。
  double scaleOf(WidgetTester tester) => tester
      .widget<InteractiveViewer>(
        find.descendant(
          of: find.byType(ZoomableMedia).hitTestable(),
          matching: find.byType(InteractiveViewer),
        ),
      )
      .transformationController!
      .value
      .getMaxScaleOnAxis();

  Finder shownText(String text) => find.descendant(
    of: find.byType(PostViewerScreen),
    matching: find.text(text),
  );

  testWidgets('ダブルタップで拡大し、拡大している間は上下に払っても次の投稿へ送らない。元に戻すと送れる', (tester) async {
    await openViewer(tester, [image('ig:1', '1つ目'), image('ig:2', '2つ目')]);
    expect(scaleOf(tester), 1);

    await doubleTap(tester);
    expect(scaleOf(tester), closeTo(ZoomableMedia.doubleTapScale, 0.01));

    // 拡大している間は、上へ払っても、次の投稿へ送らず、右へ払っても閉じない。
    await tester.fling(
      find.byType(PostViewerScreen),
      const Offset(0, -600),
      1500,
    );
    await tester.pumpAndSettle();
    expect(shownText('1つ目'), findsOneWidget);
    await tester.fling(
      find.byType(PostViewerScreen),
      const Offset(300, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PostViewerScreen), findsOneWidget);

    // もう一度ダブルタップで元に戻すと、送れる。
    await doubleTap(tester);
    expect(scaleOf(tester), 1);
    await tester.fling(
      find.byType(PostViewerScreen),
      const Offset(0, -600),
      1500,
    );
    await tester.pumpAndSettle();
    expect(shownText('2つ目'), findsOneWidget);
    // 次の投稿は、元の大きさで出す。
    expect(scaleOf(tester), 1);
  });

  testWidgets('元の大きさから、2本の指で広げると拡大し、その間は次の投稿へ送らない', (tester) async {
    await openViewer(tester, [image('ig:1', '1つ目'), image('ig:2', '2つ目')]);
    final center = tester.getCenter(find.byType(PostViewerScreen));
    final a = await tester.startGesture(center + const Offset(-10, -10));
    await tester.pump();
    final b = await tester.startGesture(
      center + const Offset(10, 10),
      pointer: 2,
    );
    await tester.pump();
    for (var i = 1; i <= 10; i++) {
      await a.moveBy(const Offset(-8, -8));
      await b.moveBy(const Offset(8, 8));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), greaterThan(2));
    expect(shownText('1つ目'), findsOneWidget);

    await tester.fling(
      find.byType(PostViewerScreen),
      const Offset(0, -600),
      1500,
    );
    await tester.pumpAndSettle();
    expect(shownText('1つ目'), findsOneWidget);
  });

  testWidgets('カルーセルは、拡大している間は左右に払っても次の画像へ送らない', (tester) async {
    await openViewer(tester, [carousel]);
    expect(find.text('1/3'), findsOneWidget);

    await doubleTap(tester);
    await tester.fling(
      find.byType(PostViewerScreen),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);

    await doubleTap(tester);
    await tester.fling(
      find.byType(PostViewerScreen),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('拡大の上限は 4 倍', (tester) async {
    await openViewer(tester, [image('ig:1', '1つ目')]);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer).first,
    );
    expect(viewer.maxScale, 4);
    expect(viewer.minScale, 1);
  });
}
