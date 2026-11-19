import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/post_video.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  Post video(SnsService source, PostKind kind) => samplePost(
    id: '${source.name}:1',
    creatorId: 'hiyori',
    source: source,
    kind: kind,
    text: '動画',
    permalink: 'https://example.com/1',
    thumbnailUrl: 'https://cdn.example/1.jpg',
  );

  Future<void> openViewer(WidgetTester tester, Post post) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noPostViewTracker],
        child: localizedApp(
          opener(
            (context) => PostViewerScreen.open(
              context,
              posts: [post],
              initialIndex: 0,
              authorOf: (_) => null,
            ),
          ),
        ),
      ),
    );
    await tapOpen(tester);
  }

  for (final (source, kind) in [
    (SnsService.instagram, PostKind.reel),
    (SnsService.x, PostKind.video),
  ]) {
    testWidgets('$source の動画本体が取れないときは、再生のマークと文言を出し、小窓にできない', (tester) async {
      await openViewer(tester, video(source, kind));
      expect(find.byType(PlayMark), findsOneWidget);
      expect(find.text('この動画はアプリ上では再生できません'), findsOneWidget);
      expect(find.byTooltip('固定ビューアで流す'), findsNothing);
    });
  }

  testWidgets('動画を読み込めなかったら、文言を出し、固定するボタンを隠す', (tester) async {
    final post = samplePost(
      id: 'ig:2',
      creatorId: 'hiyori',
      source: SnsService.instagram,
      kind: PostKind.reel,
      text: '動画',
      permalink: 'https://example.com/2',
      thumbnailUrl: 'https://cdn.example/2.jpg',
      videoUrl: 'https://cdn.example/2.mp4',
    );
    await openViewer(tester, post);
    // テストでは動画のプレイヤーが動かないので、読み込みに失敗する。
    expect(find.text('この動画はアプリ上では再生できません'), findsOneWidget);
    expect(find.byTooltip('固定ビューアで流す'), findsNothing);
  });
}
