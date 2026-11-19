// 【仮】Instagram の DM での確認（機能仕様書 4.6.2.1）のテスト。
// Meta の審査が通って仕組みを外すときに、このファイルも消す。
// v1.0.0 は Instagram を出さない（instagramOffered が false）ので、飛ばす。次の版で動かす。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/instagram_dm.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/creator_admin/widgets/account_link_screen.dart';

import 'screen_test_helpers.dart';

/// Instagram の行の中の [text]。
Finder inInstagramRow(String text) => find.descendant(
  of: find
      .ancestor(of: find.text('Instagram'), matching: find.byType(Row))
      .first,
  matching: find.text(text),
);

void main() {
  if (!instagramOffered) {
    test(
      'Instagram の DM での確認',
      () {},
      skip: 'v1.0.0 は Instagram を出さない',
    );
    return;
  }
  setUpScreenTests();

  setUp(() {
    data.creators[0] = Creator(
      id: 'minato',
      name: '星野ミナト',
      linkedAccounts: const {
        SnsService.youtube: CreatorAccount(
          service: SnsService.youtube,
          account: 'UC123',
          verified: true,
        ),
      },
    );
  });

  testWidgets('受け先があれば、Instagram を DM で確かめる。コードを出し、確認待ちになり、取り消せる', (
    tester,
  ) async {
    data.instagramDmAccount = 'oiboshi.official';
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    await tester.tap(inInstagramRow('連携する'));
    await tester.pumpAndSettle();
    expect(find.text('Instagram を DM で確認'), findsOneWidget);
    expect(find.textContaining('@oiboshi.official'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '@Minato_IG');
    await tester.pumpAndSettle();
    await tester.tap(find.text('コードを出す'));
    await tester.pumpAndSettle();
    expect(find.text('3F9A21C7'), findsOneWidget);
    expect(find.text('確かめるアカウント：@minato_ig'), findsOneWidget);
    expect(find.text('送り先：@oiboshi.official'), findsOneWidget);
    expect(find.text('Instagram で DM を送る'), findsOneWidget);
    expect(find.textContaining('2026年11月2日'), findsOneWidget);

    // シートを閉じると、行は確認待ちになる。
    await tester.tapAt(const Offset(200, 50));
    await tester.pumpAndSettle();
    expect(inInstagramRow('確認待ち'), findsOneWidget);
    expect(inInstagramRow('@minato_ig'), findsOneWidget);

    // 確認待ちの行を押すと、コードをもう一度見られる。取り消すと、連携するに戻る。
    await tester.tap(inInstagramRow('確認待ち'));
    await tester.pumpAndSettle();
    expect(find.text('3F9A21C7'), findsOneWidget);
    await tester.tap(find.text('取り消す'));
    await tester.pumpAndSettle();
    expect(find.text('Instagram を DM で確認'), findsNothing);
    expect(inInstagramRow('連携する'), findsOneWidget);
    expect(data.instagramDmRequests, isEmpty);
    await unmount(tester);
  });

  testWidgets('ほかの発信者で確認済み・ユーザー名の形が違うときは、コードを出さない', (tester) async {
    data.instagramDmAccount = 'oiboshi.official';
    data.instagramDmResult = InstagramDmRequestResult.duplicate;
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    await tester.tap(inInstagramRow('連携する'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'コードを出す'))
          .onPressed,
      isNull,
      reason: 'ユーザー名が空のあいだは押せない',
    );
    await tester.enterText(find.byType(TextField), 'taken');
    await tester.pumpAndSettle();
    await tester.tap(find.text('コードを出す'));
    await tester.pumpAndSettle();
    expect(find.text('このアカウントは、ほかの発信者で連携されています'), findsOneWidget);

    data.instagramDmResult = InstagramDmRequestResult.invalid;
    await tester.tap(find.text('コードを出す'));
    await tester.pumpAndSettle();
    expect(find.text('Instagram のユーザー名を確かめてください'), findsOneWidget);
    expect(data.instagramDmRequests, isEmpty);
    await unmount(tester);
  });

  testWidgets('DM の状態を読めなければ、OAuth に替えず、読めなかったことと「再試行」を出す', (
    tester,
  ) async {
    data.instagramDmAccount = 'oiboshi.official';
    data.instagramDmFails = true;
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    expect(inInstagramRow('読み込めませんでした'), findsOneWidget);
    expect(inInstagramRow('連携する'), findsNothing);
    // 再試行で読めたら、DM の手順に戻る。
    data.instagramDmFails = false;
    await tester.tap(inInstagramRow('再試行'));
    await tester.pumpAndSettle();
    expect(inInstagramRow('連携する'), findsOneWidget);
    await tester.tap(inInstagramRow('連携する'));
    await tester.pumpAndSettle();
    expect(find.text('Instagram を DM で確認'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('受け先がなければ、Instagram はこれまでどおり OAuth で連携する', (tester) async {
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    await tester.tap(inInstagramRow('連携する'));
    await tester.pumpAndSettle();
    expect(find.text('Instagram を DM で確認'), findsNothing);
    expect(inInstagramRow('@instagram_linked'), findsOneWidget);
    expect(inInstagramRow('確認済み'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('確認済みの Instagram は、DM の手順のときも確認済みのまま出す', (tester) async {
    data.instagramDmAccount = 'oiboshi.official';
    data.creators[0] = data.creators[0].copyWith(
      linkedAccounts: const {
        SnsService.instagram: CreatorAccount(
          service: SnsService.instagram,
          account: 'minato_ig',
          verified: true,
        ),
      },
    );
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    expect(inInstagramRow('確認済み'), findsOneWidget);
    expect(inInstagramRow('連携する'), findsNothing);
    await unmount(tester);
  });
}
