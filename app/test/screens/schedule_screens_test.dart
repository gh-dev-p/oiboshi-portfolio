import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/event.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/report.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/platform_chip.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/event_register_screen.dart';
import 'package:oiboshi/ui/core/ui/app_bottom_nav.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/core/ui/glass_surface.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/schedule/view_models/time_schedule_viewmodel.dart';
import 'package:oiboshi/ui/schedule/widgets/schedule_table.dart';
import 'package:oiboshi/ui/core/ui/screen_app_bar.dart';
import 'package:oiboshi/ui/core/ui/sns_style.dart';
import 'package:oiboshi/ui/schedule/widgets/month_calendar_screen.dart';
import 'package:oiboshi/ui/schedule/widgets/time_grid_items.dart';
import 'package:oiboshi/ui/schedule/widgets/week_strip.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  testWidgets('タイムスケジュールは、選んだ日の予定をブロックで出し、予定がなければカードを出す', (tester) async {
    data.follows.add(sampleFollow());
    final now = DateTime.now();
    data.schedules.add(
      sampleSchedule(
        's1',
        '今日の配信',
        DateTime(now.year, now.month, now.day, 23, 30),
        service: SnsService.youtube,
      ),
    );
    // 拡大で、2行のタイトルが入らない短い予定（はみ出さず、1行で出す）。
    data.schedules.add(
      sampleSchedule(
        's2',
        '短い予定',
        DateTime(now.year, now.month, now.day, 22, 0),
        endsAt: DateTime(now.year, now.month, now.day, 22, 10),
        service: SnsService.twitch,
      ),
    );
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    expect(find.text('終日'), findsNothing);
    expect(find.text('この日の予定はありません'), findsNothing);
    // 列の見出しは、アイコンだけ。名前は、読み上げのラベルにだけ持つ。
    expect(find.text('星野ミナト'), findsNothing);
    expect(find.bySemanticsLabel('星野ミナト'), findsOneWidget);
    // 拡大すると、予定のタイトルを出す。
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    expect(find.text('絞り込み'), findsOneWidget);
    await tester.ensureVisible(find.textContaining('で表示'));
    await tester.tap(find.textContaining('で表示'));
    await tester.pumpAndSettle();
    // 時刻のラベルをダブルタップする。現在時刻に近いラベルは隠れるので、今から離れた時刻のラベルを使う。
    final label = find.text(now.hour < 12 ? '18:00' : '6:00');
    await tester.tap(label);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(find.text('今日の配信'), findsOneWidget);
    expect(find.text('短い予定'), findsOneWidget);
    // 列の見出しのアイコンを押すと、発信者ページへ。
    // 表全体のダブルタップ（拡大・縮小）と見分けるため、タップはダブルタップの待ち時間のあとに届く。
    await tester.tap(find.bySemanticsLabel('星野ミナト'));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.byType(CreatorScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('表の要素を押すと、種類を問わず、下の詳細のパネルにカードで出す', (tester) async {
    data.follows.add(sampleFollow());
    final now = DateTime.now();
    // 今の時刻の近くは、配信中の扱いや今の時刻の線が重なるので、予定と投稿を今から離して置く。
    final hour = now.hour < 12 ? 15 : 3;
    data.schedules.add(
      sampleSchedule(
        's1',
        '朝の配信',
        DateTime(now.year, now.month, now.day, hour, 0),
        endsAt: DateTime(now.year, now.month, now.day, hour + 1, 0),
        service: SnsService.twitch,
      ),
    );
    // setUp の投稿（今の1時間前）は、走らせる時刻によって 1:00 の投稿と「+2」にまとまり、
    // Instagram のアイコンが消える。時刻に左右されないよう、この投稿だけにする。
    data.posts
      ..clear()
      ..add(
        samplePost(
          id: 'ig:1',
          source: SnsService.instagram,
          kind: PostKind.reel,
          text: '夜明けのリール',
          postedAt: DateTime(now.year, now.month, now.day, hour - 2, 0),
        ),
      );
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    Finder iconOf(SnsService service) => find.byWidgetPredicate(
      (w) => w is PlatformIcon && w.service == service,
    );
    // 予定のブロック → 予定の詳細のカード。
    // 表全体のダブルタップ（拡大・縮小）と見分けるため、タップはダブルタップの待ち時間のあとに届く。
    await tester.tap(iconOf(SnsService.twitch).first);
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.text('朝の配信'), findsOneWidget);
    expect(find.text('発信者のページを開く'), findsOneWidget);
    // 開いたまま、投稿チップを押すと、投稿のカードに切り替わる。
    await tester.tap(iconOf(SnsService.instagram).first);
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.text('星野ミナトの投稿'), findsOneWidget);
    expect(find.text('夜明けのリール'), findsOneWidget);
    expect(find.text('朝の配信'), findsNothing);
    // 閉じるボタンで閉じる。
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('星野ミナトの投稿'), findsNothing);
    await unmount(tester);
  });

  testWidgets('詳細のパネルを左右に払うと、同じ推しの中を時刻の順に送り、端で隣の推しへ移る（画面定義書（スケジュール）2.1.3）', (
    tester,
  ) async {
    data.creators.add(const Creator(id: 'sora', name: '月城ソラ'));
    data.follows
      ..add(sampleFollow())
      ..add(sampleFollow('sora'));
    final now = DateTime.now();
    // 今の時刻の近くは、配信中の扱いや今の時刻の線が重なるので、今から離して置く。
    final hour = now.hour < 12 ? 15 : 3;
    DateTime at(int h) => DateTime(now.year, now.month, now.day, h);
    // 左の列（星野ミナト）に2件、右の列（月城ソラ）に1件。押しやすいよう、プラットフォームを分ける。
    data.schedules
      ..add(
        sampleSchedule(
          'a',
          'ミナトの朝',
          at(hour),
          endsAt: at(hour + 1),
          service: SnsService.twitch,
        ),
      )
      ..add(
        sampleSchedule(
          'b',
          'ミナトの昼',
          at(hour + 2),
          endsAt: at(hour + 3),
          service: SnsService.youtube,
        ),
      )
      ..add(
        sampleSchedule(
          'c',
          'ソラの朝',
          at(hour + 1),
          endsAt: at(hour + 2),
          creatorId: 'sora',
          service: SnsService.x,
        ),
      );
    data.posts.clear();
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is PlatformIcon && w.service == SnsService.twitch,
      ),
    );
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.text('ミナトの朝'), findsOneWidget);
    Future<void> swipe(String from, double dx) async {
      await tester.drag(find.text(from), Offset(dx, 0));
      await tester.pumpAndSettle();
    }

    // 全体の最初では、右に払っても前へは送らない。
    await swipe('ミナトの朝', 200);
    expect(find.text('ミナトの朝'), findsOneWidget);
    // 左に払うと、同じ推しの次（時刻の順）。ソラの予定のほうが早くても、先にミナトの中を送る。
    await swipe('ミナトの朝', -200);
    expect(find.text('ミナトの昼'), findsOneWidget);
    expect(find.text('ミナトの朝'), findsNothing);
    // その推しの最後で左に払うと、右隣の推しの最初へ。
    await swipe('ミナトの昼', -200);
    expect(find.text('ソラの朝'), findsOneWidget);
    // 全体の最後では、それ以上は送らない。
    await swipe('ソラの朝', -200);
    expect(find.text('ソラの朝'), findsOneWidget);
    // 右に払うと、左隣の推しの最後へ戻る。
    await swipe('ソラの朝', 200);
    expect(find.text('ミナトの昼'), findsOneWidget);
    // 少し斜めでも、縦に動かしたら送らない（パネルの中の縦のスクロールに渡す）。
    await tester.drag(find.text('ミナトの昼'), const Offset(-40, -200));
    await tester.pumpAndSettle();
    expect(find.text('ミナトの昼'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ヘッダーで配信・投稿・予定のない推しを隠すと、その日に何もない推しの列を出さない', (tester) async {
    data.creators.add(const Creator(id: 'sora', name: '月城ソラ'));
    data.follows
      ..add(sampleFollow())
      ..add(sampleFollow('sora'));
    final now = DateTime.now();
    data.schedules.add(
      sampleSchedule(
        's1',
        '今日の配信',
        DateTime(now.year, now.month, now.day, 20),
        service: SnsService.youtube,
      ),
    );
    data.posts.clear();
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('月城ソラ'), findsOneWidget);
    // ヘッダーのアイコンで、押すたびに切り替える。
    await tester.tap(find.byTooltip('配信・投稿・予定のない推しを隠す'));
    await tester.pumpAndSettle();
    // 切り替えたら、スナックバーで知らせる。
    expect(find.text('配信・投稿・予定のない推しを隠しました').hitTestable(), findsOneWidget);
    expect(find.bySemanticsLabel('星野ミナト'), findsOneWidget);
    expect(find.bySemanticsLabel('月城ソラ'), findsNothing);
    // 絞り込みを適用し直しても、オンのまま。
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('で表示'));
    await tester.tap(find.textContaining('で表示'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('月城ソラ'), findsNothing);
    await tester.tap(find.byTooltip('配信・投稿・予定のない推しを隠す'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('月城ソラ'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('月のカレンダーは、選んだ日の予定と実績を出す', (tester) async {
    final now = DateTime.now();
    data.schedules.add(
      sampleSchedule(
        's1',
        'ファンミーティング',
        DateTime(now.year, now.month, now.day, 18, 30),
        venue: '東京',
        ticketUrl: 'https://example.com/ticket',
        ticketIsPromotion: true,
      ),
    );
    data.posts.add(
      samplePost(
        id: 'yt:9',
        postedAt: DateTime(now.year, now.month, now.day, 9),
      ),
    );
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(creators: data.creators, initialDay: now),
    );
    expect(find.text('星野ミナトのカレンダー'), findsOneWidget);
    // 1人のカレンダーには、絞り込みを出さない。
    expect(find.byTooltip('絞り込み'), findsNothing);
    expect(find.text('ファンミーティング'), findsOneWidget);
    expect(find.text('PR'), findsOneWidget);
    expect(find.text('この日に行われた投稿'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('みんなのカレンダーは、絞り込みで出す内容を選べる', (tester) async {
    data.creators.add(const Creator(id: 'sora', name: '月城ソラ'));
    final now = DateTime.now();
    data.posts.clear();
    data.schedules
      ..add(
        sampleSchedule(
          'l1',
          '夜の配信',
          DateTime(now.year, now.month, now.day, 21),
          service: SnsService.youtube,
        ),
      )
      ..add(
        sampleSchedule(
          'e1',
          'サイン会',
          DateTime(now.year, now.month, now.day, 13),
          creatorId: 'sora',
          venue: '大阪',
        ),
      );
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(
        creators: data.creators,
        initialDay: now,
        filterable: true,
      ),
    );
    expect(find.text('みんなのカレンダー'), findsOneWidget);
    expect(find.text('夜の配信'), findsOneWidget);
    expect(find.text('サイン会'), findsOneWidget);
    // 「配信」を外すと、配信の予定だけを出さない。
    await tester.tap(find.byTooltip('絞り込み'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('で表示'));
    await tester.tap(find.textContaining('で表示'));
    await tester.pumpAndSettle();
    expect(find.text('夜の配信'), findsNothing);
    expect(find.text('サイン会'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('終日の予定しかない日は、「終日」の帯を出し、予定なしのカードを出さない。ピルを押すと、そのピルを目立たせる', (
    tester,
  ) async {
    data.follows.add(sampleFollow());
    final now = DateTime.now();
    data.posts.clear();
    data.schedules.add(
      sampleSchedule(
        'a1',
        '誕生日',
        DateTime(now.year, now.month, now.day),
        allDay: true,
      ),
    );
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    expect(find.text('終日'), findsOneWidget);
    expect(find.text('この日の予定はありません'), findsNothing);
    final pill = find.byWidgetPredicate(
      (w) => w is FocusEffect && w.itemKey == 'schedule:a1',
    );
    expect(pill, findsOneWidget);
    // 表全体のダブルタップ（拡大・縮小）と見分けるため、タップはダブルタップの待ち時間のあとに届く。
    await tester.tap(pill);
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.text('誕生日'), findsOneWidget);
    expect(tester.widget<FocusEffect>(pill).selectedKey, 'schedule:a1');
    await unmount(tester);
  });

  testWidgets(
    '絞り込みのプラットフォームは、SNS のあとに「イベント」。SNS も「イベント」も選ばないと押せず、「イベント」は SNS に数えない',
    (tester) async {
      data.follows.add(sampleFollow());
      await pumpHome(tester);
      await tester.tap(find.byIcon(Icons.schedule_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      final chips = find.byType(PlatformChip);
      expect(
        [for (final c in tester.widgetList<PlatformChip>(chips)) c.service],
        [...SnsService.values, null],
      );
      expect(find.text('イベント'), findsOneWidget);
      // 「表示する内容」に「カレンダー予定」のスイッチはない（公演は「イベント」のチップで決める）。
      expect(find.text('カレンダー予定'), findsNothing);
      PrimaryButton apply() => tester.widget<PrimaryButton>(
        find.ancestor(
          of: find.textContaining('で表示'),
          matching: find.byType(PrimaryButton),
        ),
      );
      expect(apply().label, '1人・5つのSNSで表示');
      // SNS をすべて外しても、「イベント」が残っていれば押せる。
      for (final s in SnsService.values) {
        await tester.tap(
          find.byWidgetPredicate((w) => w is PlatformChip && w.service == s),
        );
        await tester.pumpAndSettle();
      }
      expect(apply().label, '1人・0つのSNSで表示');
      expect(apply().onPressed, isNotNull);
      // 「イベント」も外すと、押せない。
      await tester.tap(find.text('イベント'));
      await tester.pumpAndSettle();
      expect(apply().onPressed, isNull);
      // リセットで、全部オンに戻る。
      await tester.tap(find.text('リセット'));
      await tester.pumpAndSettle();
      expect(apply().label, '1人・5つのSNSで表示');
      expect(
        tester.widgetList<PlatformChip>(chips).every((c) => c.selected),
        isTrue,
      );
      await unmount(tester);
    },
  );

  testWidgets('詳細のパネルの「編集」は、イベントの公演ならイベントの編集を開く', (tester) async {
    data
      ..ownedCreatorId = 'minato'
      ..follows.add(sampleFollow());
    final now = DateTime.now();
    data.posts.clear();
    data.events['ev'] = const Event(
      id: 'ev',
      creatorId: 'minato',
      title: 'ツアー',
      links: [],
      performances: [],
    );
    data.schedules.add(
      sampleSchedule(
        'p1',
        'ツアー',
        DateTime(now.year, now.month, now.day),
        allDay: true,
        eventId: 'ev',
      ),
    );
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is FocusEffect && w.itemKey == 'schedule:p1',
      ),
    );
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    // パネルの中身はスクロールするので、ボタンを見えるところまで出してから押す。
    await tester.ensureVisible(find.text('編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.byType(EventRegisterScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('時刻未定の公演は、終日の帯のピルに「時刻未定」の印を付け、終日の予定には付けない', (tester) async {
    data.creators.add(const Creator(id: 'sora', name: '月城ソラ'));
    data.follows
      ..add(sampleFollow())
      ..add(sampleFollow('sora'));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    data.posts.clear();
    data.schedules
      ..add(sampleSchedule('p1', 'ツアー', today, allDay: true, eventId: 'ev'))
      ..add(
        // 取得した終日の予約には、印を付けない。
        sampleSchedule(
          'a1',
          '誕生日',
          today,
          creatorId: 'sora',
          allDay: true,
          service: SnsService.youtube,
          fetched: true,
        ),
      );
    final handle = tester.ensureSemantics();
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    // 縮めた表でも、読み上げでは時刻未定と伝える。
    expect(find.bySemanticsLabel(RegExp('時刻未定')), findsOneWidget);
    // 拡大すると、ピルにタイトルと印を出す。
    final label = find.text(now.hour < 12 ? '18:00' : '6:00');
    await tester.tap(label);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(find.text('ツアー'), findsOneWidget);
    expect(find.text('誕生日'), findsOneWidget);
    expect(find.text('時刻未定'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('時刻未定')), findsOneWidget);
    handle.dispose();
    await unmount(tester);
  });

  testWidgets('推しがいないタイムスケジュールでは、絞り込みと「カレンダーへ」を押せない', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    expect(find.text('推しの予定が、ここに並びます'), findsOneWidget);
    HeaderIconButton button(IconData icon) => tester.widget<HeaderIconButton>(
      find.ancestor(
        of: find.byIcon(icon),
        matching: find.byType(HeaderIconButton),
      ),
    );
    expect(button(Icons.filter_list).onPressed, isNull);
    expect(button(Icons.calendar_month).onPressed, isNull);
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();
    expect(find.byType(MonthCalendarScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('固定ビューアを出している間は、年月の帯を出さず、3つのボタンを表の右下に浮かせる（画面定義書（スケジュール）2.1.1）', (
    tester,
  ) async {
    data.follows.add(sampleFollow());
    final now = DateTime.now();
    data.schedules.add(
      sampleSchedule(
        's1',
        '今日の配信',
        // 夜の予定にしない（固定ビューアを出している間は、24:00 の線が画面の下の端に来るので、夜の予定はナビの後ろに入る）。
        // 今の時刻のタグと重ならないよう、今から離れた時刻にする（テストを流す時刻で結果が変わらないように）。
        DateTime(
          now.year,
          now.month,
          now.day,
          now.hour >= 6 && now.hour < 11 ? 14 : 8,
        ),
        service: SnsService.youtube,
      ),
    );
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    Finder header() => find.byType(TabHeader);
    Finder floating(IconData icon) => find.ancestor(
      of: find.byIcon(icon),
      matching: find.byType(GlassSurface),
    );
    // 消している間は、今のまま（年月の帯と、右上の3つ）。
    expect(header(), findsOneWidget);
    expect(floating(Icons.filter_list), findsNothing);

    homeContainer(tester).read(fixedViewerEmptyProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(header(), findsNothing);
    expect(find.byTooltip('配信・投稿・予定のない推しを隠す'), findsOneWidget);
    expect(floating(Icons.visibility_off_outlined), findsOneWidget);
    expect(floating(Icons.filter_list), findsOneWidget);
    expect(floating(Icons.calendar_month), findsOneWidget);
    // 上から「隠す」「絞り込み」「カレンダーへ」の順に縦に並べ、下部ナビより上に置く。
    final hide = tester.getRect(floating(Icons.visibility_off_outlined));
    final filter = tester.getRect(floating(Icons.filter_list));
    final calendar = tester.getRect(floating(Icons.calendar_month));
    expect(hide.center.dx, filter.center.dx);
    expect(hide.bottom, lessThan(filter.top));
    expect(filter.bottom, lessThan(calendar.top));
    final nav = tester.getRect(find.byType(AppBottomNav));
    expect(calendar.bottom, lessThan(nav.top));

    // 押したときの動きと知らせは、帯のときと同じ。
    await tester.tap(find.byTooltip('配信・投稿・予定のない推しを隠す'));
    await tester.pumpAndSettle();
    expect(find.text('配信・投稿・予定のない推しを隠しました').hitTestable(), findsOneWidget);
    expect(floating(Icons.visibility_off), findsOneWidget);

    // 詳細のパネルを開いたら、パネルの後ろに隠す。
    await tester.tap(
      find
          .byWidgetPredicate(
            (w) => w is PlatformIcon && w.service == SnsService.youtube,
          )
          .first,
    );
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.text('今日の配信'), findsOneWidget);
    expect(floating(Icons.calendar_month), findsNothing);
    // 閉じると、また出す。
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(floating(Icons.calendar_month), findsOneWidget);

    // 消すと、年月の帯に戻す。
    homeContainer(tester).read(fixedViewerEmptyProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(header(), findsOneWidget);
    expect(floating(Icons.filter_list), findsNothing);
    await unmount(tester);
  });

  testWidgets(
    '固定ビューアを出している間は、週の帯の曜日と日付を1段にまとめ、その分だけ表を上に広げる（画面定義書（スケジュール）2.1.1）',
    (tester) async {
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tester.tap(find.byIcon(Icons.schedule_outlined));
      await tester.pumpAndSettle();
      final now = DateTime.now();
      Finder date() => find.descendant(
        of: find.byType(WeekStrip),
        matching: find.text('${now.day}'),
      );
      // 今日も「今日」ではなく曜日を出す（2026-11-19 本人）。
      const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
      Finder today() => find.descendant(
        of: find.byType(WeekStrip),
        matching: find.text(weekdays[now.weekday - 1]),
      );
      expect(
        find.descendant(of: find.byType(WeekStrip), matching: find.text('今日')),
        findsNothing,
      );
      // 消している間は、今のまま2段（曜日の下に日付）。
      expect(tester.getSize(find.byType(WeekStrip)).height, WeekStrip.height);
      expect(
        tester.getCenter(today()).dy,
        lessThan(tester.getRect(date()).top),
      );
      expect(
        tester.getTopLeft(find.byType(ScheduleTable)).dy -
            tester.getTopLeft(find.byType(WeekStrip)).dy,
        WeekStrip.height,
      );

      homeContainer(tester).read(fixedViewerEmptyProvider.notifier).set(true);
      await tester.pumpAndSettle();
      // 出している間は1段（日付の右に曜日）。
      expect(
        tester.getSize(find.byType(WeekStrip)).height,
        WeekStrip.compactHeight,
      );
      expect(
        tester.getRect(today()).left,
        greaterThan(tester.getRect(date()).right),
      );
      expect(
        (tester.getCenter(today()).dy - tester.getCenter(date()).dy).abs(),
        lessThan(4),
      );
      // 表は、曜日の行の分だけ上から始まる（週の帯のすぐ下）。
      expect(
        tester.getTopLeft(find.byType(ScheduleTable)).dy -
            tester.getTopLeft(find.byType(WeekStrip)).dy,
        WeekStrip.compactHeight,
      );
      await unmount(tester);
    },
  );

  testWidgets('固定ビューアを出していて推しがいないときも、浮かせた絞り込みと「カレンダーへ」は押せない', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    homeContainer(tester).read(fixedViewerEmptyProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(find.byType(TabHeader), findsNothing);
    HeaderIconButton button(IconData icon) => tester.widget<HeaderIconButton>(
      find.descendant(
        of: find.ancestor(
          of: find.byIcon(icon),
          matching: find.byType(GlassSurface),
        ),
        matching: find.byType(HeaderIconButton),
      ),
    );
    expect(button(Icons.filter_list).onPressed, isNull);
    expect(button(Icons.calendar_month).onPressed, isNull);
    expect(button(Icons.visibility_off_outlined).onPressed, isNotNull);
    await unmount(tester);
  });

  testWidgets('表と詳細のパネルは下部ナビの後ろまで伸ばし、24:00 の線はナビより上に来る（画面定義書（スケジュール）2.1.1）', (
    tester,
  ) async {
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    final nav = tester.getRect(find.byType(AppBottomNav));
    // 表は、下部ナビの後ろ（画面のいちばん下）まで伸ばす。
    expect(
      tester.getRect(find.byType(ScheduleTable)).bottom,
      greaterThan(nav.top),
    );
    // いちばん下までスクロールしても、24:00 の線はナビより上にある。
    await tester.drag(find.byType(ScheduleTable), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('24:00')).bottom, lessThan(nav.top));
    await unmount(tester);
  });

  testWidgets(
    '固定ビューアを出している間は、初めの高さで 24:00 の線が画面のいちばん下に来る（ナビと重なってよい。画面定義書（スケジュール）2.1.1）',
    (tester) async {
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      homeContainer(tester).read(fixedViewerEmptyProvider.notifier).set(true);
      await tester.tap(find.byIcon(Icons.schedule_outlined));
      await tester.pumpAndSettle();
      // いちばん上までスクロールした所で、24:00 の線（字の上から 7 下）は、表の下の端（画面のいちばん下）にある。
      await tester.drag(find.byType(ScheduleTable), const Offset(0, 3000));
      await tester.pumpAndSettle();
      final table = tester.getRect(find.byType(ScheduleTable));
      final line24 = tester.getRect(find.text('24:00')).top + 7;
      expect(line24, moreOrLessEquals(table.bottom, epsilon: 1));
      // 終わりの余白は今のまま。いちばん下までスクロールすれば、24:00 の線はナビより上に来る。
      final nav = tester.getRect(find.byType(AppBottomNav));
      await tester.drag(find.byType(ScheduleTable), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('24:00')).bottom, lessThan(nav.top));
      await unmount(tester);
    },
  );

  testWidgets(
    '「隠す」と「絞り込み」は、オンの間、主の色の丸を敷いて、オフと見分けられるようにする（画面定義書（スケジュール）2.1.1）',
    (tester) async {
      data.follows.add(sampleFollow());
      usePhoneScreen(tester);
      await pumpHome(tester);
      await tester.tap(find.byIcon(Icons.schedule_outlined));
      await tester.pumpAndSettle();
      // オンの丸（主の色の円）が、そのボタンに敷かれているか。
      bool on(String tooltip) => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byTooltip(tooltip),
              matching: find.byType(Container),
            ),
          )
          .any(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).shape == BoxShape.circle &&
                (c.decoration! as BoxDecoration).color != null,
          );
      const hide = '配信・投稿・予定のない推しを隠す';
      const filter = '絞り込み';
      expect(on(hide), isFalse);
      expect(on(filter), isFalse);

      await tester.tap(find.byTooltip(hide));
      await tester.pumpAndSettle();
      expect(on(hide), isTrue);
      expect(on(filter), isFalse);

      // 種類を外すと、絞り込みもオン。全部に戻すとオフ。
      final vm = homeContainer(
        tester,
      ).read(timeScheduleViewModelProvider.notifier);
      final current = homeContainer(
        tester,
      ).read(timeScheduleViewModelProvider).filter;
      vm.setFilter(current.copyWith(showPosts: false));
      await tester.pumpAndSettle();
      expect(on(filter), isTrue);
      vm.setFilter(current);
      await tester.pumpAndSettle();
      expect(on(filter), isFalse);

      // 固定ビューアを出している間の、浮かせた丸でも同じ。
      homeContainer(tester).read(fixedViewerEmptyProvider.notifier).set(true);
      vm.setFilter(current.copyWith(showPosts: false));
      await tester.pumpAndSettle();
      expect(on(hide), isTrue);
      expect(on(filter), isTrue);
      await unmount(tester);
    },
  );

  testWidgets('スケジュールを開いているときに下部ナビのスケジュールをもう一度押すと、今日に戻し、今の時刻を真ん中へ移す', (
    tester,
  ) async {
    data.follows.add(sampleFollow());
    usePhoneScreen(tester);
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    final vm = homeContainer(
      tester,
    ).read(timeScheduleViewModelProvider.notifier);
    final today = vm.today;
    // 別の週の日を見ている。
    vm.selectDay(today.subtract(const Duration(days: 8)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(
      homeContainer(tester).read(timeScheduleViewModelProvider).day,
      today,
    );
    // 今の時刻の線が、表の見えている部分（列ヘッダーより下、下部ナビより上）に出ている。
    final now = DateTime.now();
    final label =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final nav = tester.getRect(find.byType(AppBottomNav));
    final table = tester.getRect(find.byType(ScheduleTable));
    final line = tester.getRect(find.text(label).last);
    expect(line.center.dy, greaterThan(table.top));
    expect(line.center.dy, lessThan(nav.top));
    // 見えている部分のおおよそ真ん中にある。ただし、0時ごろ・24時ごろは表の端で止まるので、
    // 真ん中より上（0時ごろ）か下（24時ごろ）に出ればよい。どの時刻で流しても同じ判定になるよう、
    // 端で止まったかは、時刻ではなく、表の縦のスクロールの位置で見る。
    final header = tester
        .getRect(
          find
              .descendant(
                of: find.byType(ScheduleTable),
                matching: find.byType(AvatarImage),
              )
              .first,
        )
        .bottom;
    final middle = (header + nav.top) / 2;
    final vertical = tester
        .stateList<ScrollableState>(
          find.descendant(
            of: find.byType(ScheduleTable),
            matching: find.byType(Scrollable),
          ),
        )
        .map((s) => s.position)
        .firstWhere((p) => p.axis == Axis.vertical);
    if (vertical.pixels <= vertical.minScrollExtent + 0.5) {
      expect(line.center.dy, lessThan(middle + 40));
    } else if (vertical.pixels >= vertical.maxScrollExtent - 0.5) {
      expect(line.center.dy, greaterThan(middle - 40));
    } else {
      expect((line.center.dy - middle).abs(), lessThan(40));
    }
    await unmount(tester);
  });

  testWidgets('絞り込みで推しを1人も選んでいないと、適用のボタンを押せない', (tester) async {
    data.follows.add(sampleFollow());
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('表示する推し'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('すべて外す'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(find.text('表示する推し'), findsOneWidget);
    PrimaryButton apply() => tester.widget<PrimaryButton>(
      find.ancestor(
        of: find.textContaining('で表示'),
        matching: find.byType(PrimaryButton),
      ),
    );
    expect(apply().label, startsWith('0人'));
    expect(apply().onPressed, isNull);
    // 1人選べば、押せる。
    await tester.tap(find.text('表示する推し'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('すべて選ぶ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(apply().onPressed, isNotNull);
    await unmount(tester);
  });

  testWidgets('月のカレンダーは、読み直しに失敗しても内容を残し、スナックバーで知らせる', (tester) async {
    final day = DateTime(2026, 10, 16);
    data.schedules.add(
      sampleSchedule('s1', 'ファンミーティング', day.add(const Duration(hours: 18))),
    );
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(creators: data.creators, initialDay: day),
    );
    expect(find.text('ファンミーティング'), findsOneWidget);
    data.failReads = true;
    await tester.pump(refreshInterval);
    await tester.pumpAndSettle();
    expect(find.text('更新できませんでした'), findsOneWidget);
    expect(find.text('ファンミーティング'), findsOneWidget);
    expect(find.text('読み込めませんでした'), findsNothing);
    await unmount(tester);
  });

  testWidgets('予定の詳細は、日をまたぐ予定の終了の日付を出す', (tester) async {
    final day = DateTime(2026, 10, 16);
    data.schedules.add(
      sampleSchedule(
        's1',
        '夜ふかし配信',
        day.add(const Duration(hours: 22)),
        endsAt: day.add(const Duration(hours: 26)),
        service: SnsService.youtube,
      ),
    );
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(creators: data.creators, initialDay: day),
    );
    await tester.tap(find.text('夜ふかし配信'));
    await tester.pumpAndSettle();
    expect(find.text('10月16日（金）22:00〜10月17日（土）02:00'), findsOneWidget);
    // タイムスケジュールなどから開いた月のカレンダーでは、発信者ページを開ける。
    expect(find.text('発信者のページを開く'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('予定の詳細は、終了時刻がなければ、長さを出さずに「終了時刻は未定です」と出す（2026-11-19 本人）', (
    tester,
  ) async {
    final day = DateTime(2026, 10, 16);
    data.schedules.add(
      sampleSchedule(
        's1',
        '夜の配信',
        day.add(const Duration(hours: 21)),
        service: SnsService.youtube,
      ),
    );
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(creators: data.creators, initialDay: day),
    );
    await tester.tap(find.text('夜の配信'));
    await tester.pumpAndSettle();
    expect(find.text('終了時刻は未定です'), findsOneWidget);
    expect(find.textContaining('で表示'), findsNothing);
    await unmount(tester);
  });

  testWidgets('発信者ページから開いた月のカレンダーでは、予定の詳細に「発信者のページを開く」を出さない', (tester) async {
    final now = DateTime.now();
    data.schedules.add(
      sampleSchedule(
        's1',
        'ファンミーティング',
        DateTime(now.year, now.month, now.day, 12),
      ),
    );
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.tap(find.byTooltip('月のカレンダー'));
    await tester.pumpAndSettle();
    expect(find.byType(MonthCalendarScreen), findsOneWidget);
    await tester.tap(find.text('ファンミーティング').last);
    await tester.pumpAndSettle();
    expect(find.text('イベント'), findsWidgets);
    expect(find.text('発信者のページを開く'), findsNothing);
    await unmount(tester);
  });

  testWidgets('イベントの公演の詳細に「この予定を通報する」を出し、通報できる', (tester) async {
    // 通報のシートは背が高いので、スマホの画面の大きさにする（シートの上に、スナックバーの場所を空けるため）。
    usePhoneScreen(tester);
    final day = DateTime(2026, 10, 16);
    data.schedules.addAll([
      sampleSchedule('s1', 'ファンミーティング', day.add(const Duration(hours: 12))),
      sampleSchedule(
        's2',
        '取った予約',
        day.add(const Duration(hours: 20)),
        service: SnsService.youtube,
        fetched: true,
      ),
    ]);
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(creators: data.creators, initialDay: day),
    );
    // 取得した配信の予約には出さない。
    await tester.tap(find.text('取った予約'));
    await tester.pumpAndSettle();
    expect(find.text('この予定を通報する'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ファンミーティング'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この予定を通報する'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('危険なリンク'));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, '送信'));
    await tester.pumpAndSettle();
    expect(find.text('通報しました。運営が確認します'), findsOneWidget);
    final (target, reason, _) = data.reports.single;
    expect(target, isA<ScheduleReportTarget>());
    expect((target as ScheduleReportTarget).scheduleId, 's1');
    expect(reason, ReportReason.dangerousLink);
    await unmount(tester);
  });

  testWidgets('自分がオーナーのイベントの公演には、「この予定を通報する」を出さない', (tester) async {
    data.ownedCreatorId = 'minato';
    final day = DateTime(2026, 10, 16);
    data.schedules.add(
      sampleSchedule('s1', 'ファンミーティング', day.add(const Duration(hours: 12))),
    );
    await pumpScreen(
      tester,
      data,
      MonthCalendarScreen(creators: data.creators, initialDay: day),
    );
    await tester.tap(find.text('ファンミーティング'));
    await tester.pumpAndSettle();
    expect(find.text('イベント'), findsWidgets);
    expect(find.text('この予定を通報する'), findsNothing);
    await unmount(tester);
  });
}
