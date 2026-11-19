import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/domain/models/want.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/want/widgets/want_screen.dart';

import 'screen_test_helpers.dart';

/// 追いたい（画面定義書 2.3.4。機能仕様書（届ける・広める）4.5.1）。
void main() {
  setUpScreenTests();

  /// 推しを探すのヘッダーのアイコンから、追いたいを開く。
  Future<void> openWant(WidgetTester tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('推しを探す'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.campaign_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(WantScreen), findsOneWidget);
  }

  Finder inputField() => find.descendant(
    of: find.byType(WantScreen),
    matching: find.byType(TextField),
  );

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(PrimaryButton, '追いたい'));
    await tester.pumpAndSettle();
  }

  testWidgets('URL を入れると、読み取った ID を出し、押すと自分の一覧に人数と本人確認なしで出す', (tester) async {
    await openWant(tester);
    expect(find.text('まだ追いたいはありません'), findsOneWidget);
    await tester.enterText(inputField(), 'https://x.com/Mio_Star/status/1');
    await tester.pumpAndSettle();
    expect(find.text('申告する ID'), findsOneWidget);
    expect(find.text('@mio_star'), findsOneWidget);
    await submit(tester);
    expect(find.text('追いたいにしました'), findsOneWidget);
    expect(data.wants.single.service, SnsService.x);
    expect(data.wants.single.account, 'mio_star');
    expect(find.text('@mio_star'), findsOneWidget);
    expect(find.text('1人が追いたい'), findsOneWidget);
    expect(find.text('本人確認なし'), findsOneWidget);
    // 押したら、入力を空にする。
    expect(tester.widget<TextField>(inputField()).controller!.text, '');
    await unmount(tester);
  });

  testWidgets('ID だけのときは、SNS を選ぶまで申告しない', (tester) async {
    await openWant(tester);
    await tester.enterText(inputField(), '@ReiCh');
    await tester.pumpAndSettle();
    await submit(tester);
    expect(find.text('ID だけのときは、SNS を選んでください'), findsOneWidget);
    expect(data.wants, isEmpty);
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('@reich'), findsOneWidget);
    await submit(tester);
    expect(data.wants.single.account, '@reich');
    await unmount(tester);
  });

  testWidgets('読めない URL と、この版で出さない SNS は、申告しない', (tester) async {
    await openWant(tester);
    await tester.enterText(inputField(), 'https://www.tiktok.com/@mio');
    await tester.pumpAndSettle();
    await submit(tester);
    expect(find.text('この形の URL は読めません'), findsOneWidget);
    await tester.enterText(inputField(), 'https://www.instagram.com/mio.star/');
    await tester.pumpAndSettle();
    expect(find.text('申告する ID'), findsNothing);
    await submit(tester);
    expect(find.text('この形の URL は読めません'), findsWidgets);
    expect(data.wants, isEmpty);
    await unmount(tester);
  });

  testWidgets('上限に達したら、スナックバーで知らせる', (tester) async {
    data.wantResult = const WantLimit();
    await openWant(tester);
    await tester.enterText(inputField(), 'twitch.tv/mio_tv');
    await tester.pumpAndSettle();
    await submit(tester);
    expect(find.text('今日はこれ以上申告できません'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('もう追星にいる人なら、追いたいにせず、その発信者のページを開く', (tester) async {
    data.wantRegistered['x:minato_x'] = data.creators.first.id;
    await openWant(tester);
    await tester.enterText(inputField(), 'https://x.com/minato_x');
    await tester.pumpAndSettle();
    await submit(tester);
    expect(find.byType(CreatorScreen), findsOneWidget);
    expect(data.wants, isEmpty);
    await unmount(tester);
  });

  testWidgets('押した一覧は新しい順に人数を出し、取り消せる。取り消せなければ戻す', (tester) async {
    data.wants.addAll([
      Want(
        wantedAccountId: 'a',
        service: SnsService.youtube,
        account: 'UCaaaaaaaaaaaaaaaaaaaaaa',
        wantCount: 12,
        wantedAt: DateTime(2026, 11, 16),
      ),
      Want(
        wantedAccountId: 'b',
        service: SnsService.twitch,
        account: 'mio_tv',
        wantCount: 3,
        wantedAt: DateTime(2026, 11, 15),
      ),
    ]);
    await openWant(tester);
    expect(find.text('UCaaaaaaaaaaaaaaaaaaaaaa'), findsOneWidget);
    expect(find.text('12人が追いたい'), findsOneWidget);
    expect(find.text('@mio_tv'), findsOneWidget);
    expect(find.text('3人が追いたい'), findsOneWidget);
    expect(find.text('本人確認なし'), findsNWidgets(2));

    data.wantCancelFails = true;
    await tester.tap(find.text('取り消す').last);
    await tester.pumpAndSettle();
    expect(find.text('取り消せませんでした'), findsOneWidget);
    expect(find.text('@mio_tv'), findsOneWidget);

    // スナックバーが消えてから押す。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    data.wantCancelFails = false;
    await tester.tap(find.text('取り消す').last);
    await tester.pumpAndSettle();
    expect(find.text('@mio_tv'), findsNothing);
    expect(data.wants.map((w) => w.wantedAccountId), ['a']);
    await unmount(tester);
  });

  testWidgets('推しを探すで見つからなければ、入れた言葉を入れて追いたいを開ける', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('推しを探す'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://x.com/nobody_here');
    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, '追いたいで申告する'));
    await tester.pumpAndSettle();
    expect(find.byType(WantScreen), findsOneWidget);
    expect(
      tester.widget<TextField>(inputField()).controller!.text,
      'https://x.com/nobody_here',
    );
    expect(find.text('@nobody_here'), findsOneWidget);
    await unmount(tester);
  });

  test('サーバーの結果と一覧の行を読む', () {
    expect(
      (WantResult.fromServer({'result': 'wanted', 'count': 4}) as WantAdded)
          .count,
      4,
    );
    expect(
      (WantResult.fromServer({'result': 'registered', 'creator_id': 'mio'})
              as WantRegistered)
          .creatorId,
      'mio',
    );
    expect(WantResult.fromServer({'result': 'limit'}), isA<WantLimit>());
    expect(WantResult.fromServer({'result': 'invalid'}), isA<WantInvalid>());
    expect(WantResult.fromServer({'result': '?'}), isA<WantFailed>());
    final want = Want.fromRow({
      'wanted_account_id': 'id-1',
      'service': 'youtube',
      'account': '@reich',
      'want_count': 2,
      'wanted_at': '2026-11-16T01:00:00Z',
    })!;
    expect(want.displayAccount, '@reich');
    expect(want.wantCount, 2);
    expect(
      Want.fromRow({
        'wanted_account_id': 'id-2',
        'service': 'tiktok',
        'account': 'a',
        'want_count': 1,
        'wanted_at': '2026-11-16T01:00:00Z',
      }),
      isNull,
    );
    expect(displayWantAccount(SnsService.x, 'mio'), '@mio');
  });
}
