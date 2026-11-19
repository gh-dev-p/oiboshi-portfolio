import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/post_view_totals.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/post/view_models/post_view_tracker.dart';
import 'package:oiboshi/ui/post/widgets/post_impression.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

/// 投稿が見られた数（届ける・広める仕様書 4.2.3）の、アプリでの数え方。
void main() {
  String describe(List<PostViewCount> counts) => [
    for (final c in counts) '${c.postId} 開${c.opened} 表${c.shown}',
  ].join(', ');

  PostViewTracker trackerOf(
    FakePostViewRepository repo, {
    bool Function(Post post)? isOwnPost,
  }) => PostViewTracker(
    repo,
    isOwnPost: isOwnPost ?? (_) => false,
    listenLifecycle: false,
  );

  group('ためて送る', () {
    testWidgets('表示は起動の間に1回、開いたは毎回数え、30秒後にまとめて送る', (tester) async {
      final repo = FakePostViewRepository();
      final tracker = trackerOf(repo);
      final a = samplePost(id: 'yt:a');
      final b = samplePost(id: 'yt:b');

      tracker.shown(a);
      tracker.shown(a);
      tracker.opened(a);
      tracker.opened(a);
      tracker.shown(b);
      await tester.pump(const Duration(seconds: 29));
      expect(repo.sent, isEmpty, reason: '30秒たつまでは送らない');
      await tester.pump(const Duration(seconds: 1));
      expect(repo.sent.map(describe), ['yt:a 開2 表1, yt:b 開0 表1']);

      // 送ったあとも、同じ投稿の表示は数え直さない。開いたは数える。
      tracker.shown(a);
      tracker.opened(b);
      await tester.pump(const Duration(seconds: 30));
      expect(repo.sent.map(describe).last, 'yt:b 開1 表0');
      tracker.dispose();
    });

    testWidgets('50件たまったら、待たずに送る', (tester) async {
      final repo = FakePostViewRepository();
      final tracker = trackerOf(repo);
      for (var i = 0; i < 49; i++) {
        tracker.shown(samplePost(id: 'yt:$i'));
      }
      expect(repo.sent, isEmpty);
      tracker.opened(samplePost(id: 'yt:49'));
      expect(repo.sent.single, hasLength(50));
      tracker.dispose();
    });

    testWidgets('自分のチームの発信者の投稿は数えない', (tester) async {
      final repo = FakePostViewRepository();
      final tracker = trackerOf(repo, isOwnPost: (p) => p.creatorId == 'mine');
      tracker.shown(samplePost(id: 'yt:m', creatorId: 'mine'));
      tracker.opened(samplePost(id: 'yt:m', creatorId: 'mine'));
      await tracker.flush();
      expect(repo.sent, isEmpty);
      expect(tracker.hasShown('yt:m'), isFalse);
      tracker.dispose();
    });
  });

  group('画面に出たか', () {
    Future<PostViewTracker> pumpList(WidgetTester tester) async {
      final repo = FakePostViewRepository();
      final tracker = trackerOf(repo);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postViewTrackerProvider.overrideWith((ref) {
              ref.onDispose(tracker.dispose);
              return tracker;
            }),
          ],
          child: localizedApp(
            ListView(
              children: [
                for (var i = 0; i < 5; i++)
                  PostImpression(
                    post: samplePost(id: 'yt:$i'),
                    child: SizedBox(height: 400, child: Text('投稿$i')),
                  ),
              ],
            ),
          ),
        ),
      );
      return tracker;
    }

    testWidgets('半分以上が1秒出たら数え、出ていないものは数えない', (tester) async {
      final tracker = await pumpList(tester);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tracker.hasShown('yt:0'), isFalse, reason: '1秒たつまでは数えない');
      await tester.pump(const Duration(milliseconds: 200));
      expect(tracker.hasShown('yt:0'), isTrue);
      // 画面（高さ600）に 400 のうち 200 しか出ていない2つ目は、半分ちょうどなので数える。3つ目からは出ていない。
      expect(tracker.hasShown('yt:1'), isTrue);
      expect(tracker.hasShown('yt:2'), isFalse);
    });

    testWidgets('1秒たつ前に流れたものは数えない', (tester) async {
      final tracker = await pumpList(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.drag(find.byType(ListView), const Offset(0, -1600));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(tracker.hasShown('yt:0'), isFalse);
      expect(tracker.hasShown('yt:4'), isTrue);
    });
  });

  testWidgets('投稿ビューアは、開いた投稿とスワイプで出た投稿を、1回ずつ数える', (tester) async {
    final repo = FakePostViewRepository();
    final tracker = trackerOf(repo);
    addTearDown(tracker.dispose);
    Post image(String id) => samplePost(
      id: id,
      source: SnsService.instagram,
      kind: PostKind.image,
      thumbnailUrl: 'https://cdn.example/$id.jpg',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postViewTrackerProvider.overrideWithValue(tracker)],
        child: localizedApp(
          opener(
            (context) => PostViewerScreen.open(
              context,
              posts: [image('ig:1'), image('ig:2')],
              initialIndex: 0,
              authorOf: (_) => null,
            ),
          ),
        ),
      ),
    );
    await tapOpen(tester);
    final viewer = find.byType(PostViewerScreen);
    await tester.fling(viewer, const Offset(0, -600), 1500);
    await tester.pumpAndSettle();
    await tester.fling(viewer, const Offset(0, 600), 1500);
    await tester.pumpAndSettle();
    await tracker.flush();
    expect(repo.sent.map(describe), ['ig:1 開1 表0, ig:2 開1 表0']);
  });
}
