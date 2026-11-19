import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/page_dots.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  final carousel = samplePost(
    id: 'ig:1',
    creatorId: 'hiyori',
    source: SnsService.instagram,
    kind: PostKind.carousel,
    text: 'カルーセル',
    permalink: 'https://www.instagram.com/p/1/',
    thumbnailUrl: 'https://cdn.example/1.jpg',
    media: [
      for (var i = 1; i <= 3; i++)
        PostMedia(isVideo: false, imageUrl: 'https://cdn.example/$i.jpg'),
    ],
  );

  Future<void> openViewer(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noPostViewTracker],
        child: localizedApp(
          opener(
            (context) => PostViewerScreen.open(
              context,
              posts: [carousel],
              initialIndex: 0,
              authorOf: (_) => null,
            ),
          ),
        ),
      ),
    );
    await tapOpen(tester);
  }

  Finder pageDots() => find.byType(PageDots);

  testWidgets('カルーセルは、左右のスワイプで画像を送り、何枚目かと点を出す', (tester) async {
    await openViewer(tester);
    expect(find.text('1/3'), findsOneWidget);
    expect(tester.widget<PageDots>(pageDots()).count, 3);
    expect(tester.widget<PageDots>(pageDots()).index, 0);

    await tester.fling(
      find.byType(PostViewerScreen),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    expect(tester.widget<PageDots>(pageDots()).index, 1);
    // 中の画像を送っても、ビューアは閉じない。
    expect(find.byType(PostViewerScreen), findsOneWidget);
  });

  testWidgets('カルーセルの最後の枚で、さらに左へスワイプすると閉じる', (tester) async {
    await openViewer(tester);
    for (var i = 0; i < 2; i++) {
      await tester.fling(
        find.byType(PostViewerScreen),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('3/3'), findsOneWidget);
    await tester.drag(find.byType(PostViewerScreen), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.byType(PostViewerScreen), findsNothing);
  });

  testWidgets('カルーセルの最初の枚で、右へスワイプすると閉じる', (tester) async {
    await openViewer(tester);
    await tester.drag(find.byType(PostViewerScreen), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(find.byType(PostViewerScreen), findsNothing);
  });
}
