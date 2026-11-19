import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/schedule_layout.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/sns_style.dart';
import 'package:oiboshi/ui/schedule/widgets/time_grid.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

/// タイムスケジュールの「+N」（画面定義書（スケジュール）2.1.1）。
void main() {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);

  /// 3:00 から1分ずつずらした、[sources] の投稿を、1つの「+N」にまとめる。
  PostCluster groupOf(List<SnsService> sources) {
    final posts = [
      for (var i = 0; i < sources.length; i++)
        samplePost(
          id: 'p$i',
          source: sources[i],
          kind: sources[i] == SnsService.youtube
              ? PostKind.video
              : PostKind.text,
          postedAt: day.add(Duration(hours: 3, minutes: i)),
        ),
    ];
    final clusters = clusterPosts(posts);
    expect(clusters, hasLength(1));
    return clusters.single;
  }

  Future<void> pumpGrid(
    WidgetTester tester,
    PostCluster cluster, {
    required bool expanded,
    double columnWidth = 120,
  }) async {
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: TimeGrid(
                hourHeight: expanded ? 80 : 22,
                columnWidth: columnWidth,
                expanded: expanded,
                day: day,
                now: day.add(const Duration(hours: 12)),
                columns: [
                  TimeGridColumn(
                    creator: sampleCreator(),
                    blocks: const [],
                    clusters: [cluster],
                  ),
                ],
                onBlockTap: (_, _) {},
                onClusterTap: (_, _) {},
                emptyHint: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder icons([SnsService? service]) => find.byWidgetPredicate(
    (w) => w is PlatformIcon && (service == null || w.service == service),
  );

  test('「+N」の SNS は、重なりを除き、決まった順に並べる', () {
    final cluster = groupOf([
      SnsService.x,
      SnsService.instagram,
      SnsService.x,
      SnsService.youtube,
    ]);
    expect(cluster.services, [
      SnsService.youtube,
      SnsService.x,
      SnsService.instagram,
    ]);
  });

  testWidgets('SNS が1種類の「+N」は、今までどおり、縮小では件数だけ、拡大ではアイコン1つと件数を出す', (
    tester,
  ) async {
    final cluster = groupOf([SnsService.youtube, SnsService.youtube]);
    await pumpGrid(tester, cluster, expanded: false);
    expect(find.text('+2'), findsOneWidget);
    expect(icons(), findsNothing);
    expect(find.bySemanticsLabel('2件の投稿（YouTube）'), findsOneWidget);

    await pumpGrid(tester, cluster, expanded: true);
    expect(find.text('+2'), findsOneWidget);
    expect(icons(SnsService.youtube), findsOneWidget);
    expect(icons(), findsOneWidget);
  });

  testWidgets('SNS が混ざった「+N」は、含まれる SNS のアイコンを並べ、読み上げに SNS と件数を入れる', (
    tester,
  ) async {
    final cluster = groupOf([SnsService.x, SnsService.instagram, SnsService.x]);
    for (final expanded in [false, true]) {
      await pumpGrid(tester, cluster, expanded: expanded);
      expect(find.text('+3'), findsOneWidget);
      expect(icons(SnsService.instagram), findsOneWidget);
      expect(icons(SnsService.x), findsOneWidget);
      expect(icons(), findsNWidgets(2));
      expect(find.bySemanticsLabel('3件の投稿（X・Instagram）'), findsOneWidget);
      // アイコンは、件数の左に並ぶ。
      expect(
        tester.getCenter(icons(SnsService.x)).dx,
        lessThan(tester.getCenter(find.text('+3')).dx),
      );
    }
  });

  testWidgets('狭い「+N」は、入るだけのアイコンを出し、2つも入らなければ件数だけを出す', (tester) async {
    final cluster = groupOf([
      SnsService.youtube,
      SnsService.instagram,
      SnsService.x,
    ]);
    final counts = <int>[];
    for (final width in [30.0, 40.0, 50.0, 60.0, 70.0, 120.0]) {
      await pumpGrid(tester, cluster, expanded: false, columnWidth: width);
      expect(tester.takeException(), isNull);
      expect(find.text('+3'), findsOneWidget);
      final shown = tester.widgetList(icons()).length;
      // 1つだけ出すと、SNS が1種類の「+N」と見分けられない。
      expect(shown, isNot(1));
      counts.add(shown);
    }
    expect(counts.first, 0);
    expect(counts.last, 3);
    // 3つは入らないが2つは入る幅では、数を減らして出す。
    expect(counts, contains(2));
    // 広くなるほど、多く出す（減ることはない）。
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
    }
  });
}
