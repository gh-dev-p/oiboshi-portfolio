import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/creator_settings.dart';
import 'package:oiboshi/domain/models/plan_billing.dart';
import 'package:oiboshi/ui/creator_admin/widgets/plan_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

/// プランの画面（画面定義書 2.3.6）。RevenueCat は [FakeBillingRepository] に差し替える。
void main() {
  test('ストアがくれない金額は、ストアの価格と同じ書式で書く', () {
    PlanPrice price(String code, String formatted) =>
        PlanPrice(amount: 0, currencyCode: code, formatted: formatted);
    String yen(int amount) => '$amount円';
    expect(price('JPY', '¥500').format(240, yen: yen), '240円');
    expect(price('USD', '\$5.99').format(2, yen: yen), '\$2.00');
    expect(price('USD', '\$5.99').format(0, yen: yen), '\$0.00');
    expect(price('EUR', '5,99 €').format(2, yen: yen), '2,00 €');
    expect(price('KRW', '₩12,000').format(3000, yen: yen), '₩3000');
  });

  test('サーバーの加入の期限は、X連携プランの期限が先なら加入中とし、期限のない購入も読む', () {
    final now = DateTime.utc(2026, 10, 20);
    expect(
      ServerPlanSubscription.fromRow({
        'x_option_expires_at': '2026-10-19T00:00:00+00:00',
      }).activeAt(now),
      isFalse,
    );
    expect(
      ServerPlanSubscription.fromRow({
        'x_option_expires_at': '2026-11-19T00:00:00+00:00',
      }).activeAt(now),
      isTrue,
    );
    expect(
      ServerPlanSubscription.fromRow({
        'x_option_expires_at': 'infinity',
      }).activeAt(now),
      isTrue,
    );
    expect(
      ServerPlanSubscription.fromRow({
        'x_option_expires_at': null,
      }).activeAt(now),
      isFalse,
    );
    expect(ServerPlanSubscription.none.activeAt(now), isFalse);
  });

  test('取り戻せる発信者は、プランを読み、なければ基本プランとする', () {
    Map<String, dynamic> row([String? plan]) => {
      'id': 'left_one',
      'name': '退会した発信者',
      'avatar_url': null,
      'purge_at': '2026-12-01T00:00:00+00:00',
      'plan': ?plan,
    };
    expect(
      ReclaimableCreator.fromRow(row('complimentary')).plan,
      CreatorPlan.complimentary,
    );
    expect(ReclaimableCreator.fromRow(row()).plan, CreatorPlan.standard);
  });

  late FakeData data;

  setUp(() => data = FakeData()..creators.add(sampleCreator()));

  /// 前の画面から開く（買えても、前の画面に戻らないのを確かめるため）。
  Future<void> openPlan(
    WidgetTester tester, {
    CreatorPlan plan = CreatorPlan.standard,
  }) async {
    await pumpOpener(
      tester,
      data,
      (context) => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => PlanScreen(plan: plan))),
    );
  }

  testWidgets('基本プランは無料と出し、X の連携に加入すると、画面を閉じずに加入中の表示に変える', (tester) async {
    await openPlan(tester);
    expect(find.text('基本プラン'), findsOneWidget);
    expect(find.text('無料'), findsOneWidget);
    // この版で出さない SNS（v1.0.0 の Instagram・ツイキャス）は挙げない。
    expect(
      find.text(
        '${['YouTube', if (instagramOffered) 'Instagram', if (twitcastingOffered) 'ツイキャス', 'Twitch'].join('・')} の取得と表示',
      ),
      findsOneWidget,
    );
    expect(find.text('月290円'), findsOneWidget);
    expect(find.text('加入中'), findsNothing);
    expect(find.text('解約する'), findsNothing);

    await tester.tap(find.text('加入する'));
    await tester.pumpAndSettle();
    expect(data.purchases, 1);
    expect(data.subscriptionSyncs, 1);
    expect(find.text('開く'), findsNothing);
    expect(find.text('加入中'), findsOneWidget);
    expect(find.text('次の更新日 2026年11月14日'), findsOneWidget);
    expect(find.text('加入する'), findsNothing);
    await unmount(tester);
  });

  testWidgets('X の連携を解約済みなら、終わる日を出す', (tester) async {
    data.subscription = subscribed(willRenew: false);
    await openPlan(tester);
    expect(find.text('2026年11月14日に終了'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('購入のシートを閉じたら何もせず、失敗したらスナックバーで知らせる', (tester) async {
    data.purchaseResult = PlanPurchaseResult.cancelled;
    await openPlan(tester);
    await tester.tap(find.text('加入する'));
    await tester.pumpAndSettle();
    expect(find.text('加入する'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    data.purchaseResult = PlanPurchaseResult.failed;
    await tester.tap(find.text('加入する'));
    await tester.pumpAndSettle();
    expect(find.text('購入できませんでした。もう一度お試しください'), findsOneWidget);
    expect(data.purchases, 0);
    await unmount(tester);
  });

  testWidgets('購入を復元すると、見つかった加入を出し、なければ知らせる', (tester) async {
    await openPlan(tester);
    await tester.scrollUntilVisible(
      find.text('購入を復元'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('購入を復元'));
    await tester.pumpAndSettle();
    expect(find.text('復元できる購入がありません'), findsOneWidget);

    data.restorable = subscribed();
    await tester.tap(find.text('購入を復元'));
    await tester.pumpAndSettle();
    expect(find.text('購入を復元しました'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('加入中'),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('加入中'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('自動更新の注記と、規約・プライバシーポリシーのリンクを出す', (tester) async {
    await openPlan(tester);
    await tester.scrollUntilVisible(
      find.textContaining('自動で更新されます'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('お試し'), findsNothing);
    await tester.scrollUntilVisible(
      find.textContaining('利用規約', findRichText: true),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('利用規約', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('プライバシーポリシー', findRichText: true),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('課金を使えない端末では、いまのプランを出し、X の連携に加入できないと出す', (tester) async {
    data.billingAvailable = false;
    await openPlan(tester);
    expect(find.text('無料'), findsOneWidget);
    expect(find.text('この端末では、まだ X連携プランに加入できません'), findsOneWidget);
    expect(find.text('加入する'), findsNothing);
    await unmount(tester);
  });

  testWidgets('永年無料なら、X の連携を含むと出し、加入と解約を出さない', (tester) async {
    await openPlan(tester, plan: CreatorPlan.complimentary);
    expect(find.text('永年無料'), findsOneWidget);
    expect(find.text('料金はかかりません（X の連携を含む）'), findsOneWidget);
    expect(find.text('加入する'), findsNothing);
    expect(find.text('購入を復元'), findsNothing);
    await unmount(tester);
  });

  testWidgets('「解約する」は、確かめてから、ストアのサブスクの管理を開く', (tester) async {
    data.subscription = subscribed();
    await openPlan(tester);
    await tester.scrollUntilVisible(
      find.text('解約する'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('解約する'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('解約する'));
    await tester.pumpAndSettle();
    expect(find.text('ストアのサブスクの管理を開きます'), findsOneWidget);
    expect(find.text('解約は、ストアの画面で行います。期間の終わりまでは、X の連携を使えます。'), findsOneWidget);

    // キャンセルなら、何も開かない。
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('ページを開けませんでした'), findsNothing);

    // 開くと、ストアの画面を開く（テストでは開けないので、知らせが出る）。
    await tester.tap(find.text('解約する'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('開く')),
    );
    // URL を開く処理は、プラットフォームの応答を本当の時間で待つ。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('ページを開けませんでした'), findsOneWidget);
    await unmount(tester);
  });
}
