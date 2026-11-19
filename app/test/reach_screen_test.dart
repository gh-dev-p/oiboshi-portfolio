import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/post_view_totals.dart';
import 'package:oiboshi/domain/models/reach_overview.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/creator_admin/widgets/reach_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

/// 届いた数（届ける・広める仕様書 4.2.2）。
void main() {
  test('関数の行から作る', () {
    final o = ReachOverview.fromRows(
      {
        'from_day': '2026-10-17',
        'to_day': '2026-11-15',
        'delivered': 9,
        'opened': 3,
        'viewed': 3,
        'followed': 3,
        'unfollowed': 1,
        'followers': 11,
      },
      [
        {
          'subject': 'live:twitch:L1',
          'service': 'twitch',
          'title': '雑談',
          'starts_at': '2026-11-14T11:00:00+00:00',
          'delivered': 4,
          'opened': 2,
          'viewed': 0,
        },
        {
          'subject': 'schedule:s1',
          'service': null,
          'title': null,
          'starts_at': null,
          'delivered': 1,
          'opened': 0,
          'viewed': 0,
        },
      ],
    );
    expect(o.fromDay, DateTime(2026, 10, 17));
    expect(o.followers, 11);
    expect(o.subjects.first.isLive, isTrue);
    expect(o.subjects.first.service, SnsService.twitch);
    expect(o.subjects.last.isLive, isFalse);
    expect(o.subjects.last.title, '');
  });

  group('画面', () {
    late FakeData data;
    late FakeReachRepository reach;
    late FakePostViewRepository postViews;

    setUp(() {
      data = FakeData()..creators.add(sampleCreator());
      reach = FakeReachRepository();
      postViews = FakePostViewRepository();
    });

    Future<void> pumpReach(WidgetTester tester) => pumpScreen(
      tester,
      data,
      const ReachScreen(creatorId: 'minato'),
      reach: reach,
      postViews: postViews,
    );

    testWidgets('直近30日の合計と、配信・予定ごとの数を丸めずに出す', (tester) async {
      reach.overview = ReachOverview(
        fromDay: DateTime(2026, 10, 17),
        toDay: DateTime(2026, 11, 15),
        delivered: 1234,
        opened: 3,
        viewed: 1,
        followed: 5,
        unfollowed: 2,
        followers: 42,
        subjects: [
          ReachSubject(
            subject: 'live:twitch:L1',
            title: '雑談',
            startsAt: DateTime(2026, 11, 14, 20),
            service: SnsService.twitch,
            delivered: 4,
            opened: 1,
            viewed: 0,
          ),
          const ReachSubject(
            subject: 'schedule:s1',
            title: '',
            startsAt: null,
            service: null,
            delivered: 2,
            opened: 0,
            viewed: 1,
          ),
        ],
      );
      await pumpReach(tester);
      expect(find.text('直近30日（10/17〜11/15）'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('30日で +3（フォロー 5・解除 2）'), findsOneWidget);
      expect(find.text('雑談'), findsOneWidget);
      expect(find.text('届けた 4・来た 1'), findsOneWidget);
      // 消された予定は、名前の代わりに「消された予定」。予定は「見た」も出す。
      expect(find.text('消された予定'), findsOneWidget);
      expect(find.text('届けた 2・来た 0・見た 1'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('配信・予定ごとの数がなければ、案内を出す', (tester) async {
      reach.overview = ReachOverview(
        fromDay: DateTime(2026, 10, 17),
        toDay: DateTime(2026, 11, 15),
        delivered: 0,
        opened: 0,
        viewed: 0,
        followed: 0,
        unfollowed: 0,
        followers: null,
        subjects: const [],
      );
      await pumpReach(tester);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('まだありません。配信開始や予定の通知を送ると、ここに数が出ます。'), findsOneWidget);
      await unmount(tester);
    });

    ReachOverview empty() => ReachOverview(
      fromDay: DateTime(2026, 10, 17),
      toDay: DateTime(2026, 11, 15),
      delivered: 0,
      opened: 0,
      viewed: 0,
      followed: 0,
      unfollowed: 0,
      followers: 7,
      subjects: const [],
    );

    testWidgets('投稿が表示された回数と開いた回数を、丸めずに出す（4.2.3）', (tester) async {
      reach.overview = empty();
      postViews.totals = const PostViewTotals(opened: 12, shown: 5678);
      await pumpReach(tester);
      expect(find.text('投稿'), findsOneWidget);
      expect(find.text('投稿が表示された回数'), findsOneWidget);
      expect(find.text('5,678'), findsOneWidget);
      expect(find.text('投稿を開いた回数'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('投稿の数が読めなくても、ほかの数は出し、投稿の数は「—」', (tester) async {
      reach.overview = empty();
      postViews.totals = null;
      await pumpReach(tester);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      await unmount(tester);
    });

    testWidgets('読めなければ、もう一度試せる', (tester) async {
      await pumpReach(tester);
      expect(find.text('もう一度試す'), findsOneWidget);
      await unmount(tester);
    });
  });
}
