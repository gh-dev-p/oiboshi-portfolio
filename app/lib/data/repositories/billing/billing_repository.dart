import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../config/app_constants.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/plan_billing.dart';
import '../../services/billing/billing_service.dart';
import '../../services/billing/subscription_sync_service.dart';
import '../common/error_mapping.dart';

/// 発信者向けの X連携プランの課金（機能仕様書 4.6.6）。RevenueCat を、この中に隠す。
class BillingRepository {
  BillingRepository(this._billing, this._sync);

  final BillingService _billing;
  final SubscriptionSyncService _sync;

  /// RevenueCat の設定の識別子（機能仕様書 4.6.6）。
  static const offeringId = 'default';
  static const xOptionPackageId = r'$rc_monthly';
  static const xOptionEntitlement = 'x_option';

  /// この端末で課金を使えるか（RevenueCat のキーがあるか）。
  bool get available => _billing.available;

  /// RevenueCat のユーザーを、サインインしたユーザーにそろえる。
  Future<void> logIn(String userId) => _map(() => _billing.logIn(userId));

  /// 買える商品と価格。商品がなければ、[AppErrorKind.notFound]。
  Future<PlanOffer> fetchOffer() => _map(() async {
    final package = await _xOptionPackage();
    if (package == null) throw const AppException(AppErrorKind.notFound);
    return PlanOffer(xOption: _price(package.storeProduct));
  });

  Future<Package?> _xOptionPackage() async {
    final offerings = await _billing.getOfferings();
    final offering = offerings.getOffering(offeringId) ?? offerings.current;
    return offering?.getPackage(xOptionPackageId);
  }

  static PlanPrice _price(StoreProduct product) => PlanPrice(
    amount: product.price,
    currencyCode: product.currencyCode,
    formatted: product.priceString,
  );

  /// いまの加入。
  Future<PlanSubscription> fetchSubscription() =>
      _map(() async => _subscription(await _billing.getCustomerInfo()));

  /// X連携プランを買う。
  Future<(PlanPurchaseResult, PlanSubscription?)> purchase() async {
    try {
      final package = await _xOptionPackage();
      if (package == null) return (PlanPurchaseResult.failed, null);
      final result = await _billing.purchase(PurchaseParams.package(package));
      return (PlanPurchaseResult.purchased, _subscription(result.customerInfo));
    } on PlatformException catch (e) {
      return (
        switch (PurchasesErrorHelper.getErrorCode(e)) {
          PurchasesErrorCode.purchaseCancelledError =>
            PlanPurchaseResult.cancelled,
          PurchasesErrorCode.paymentPendingError => PlanPurchaseResult.pending,
          _ => PlanPurchaseResult.failed,
        },
        null,
      );
    } catch (_) {
      return (PlanPurchaseResult.failed, null);
    }
  }

  /// ストアの購入を読み直す。
  Future<PlanSubscription> restore() =>
      _map(() async => _subscription(await _billing.restore()));

  /// サーバーの加入の状態を、RevenueCat から引き直させる（機能仕様書 4.6.6）。
  /// 購入・購入の復元のあとに、Webhook を待たずに、X の取得の可否を追いつかせる。
  Future<void> syncServerSubscription() => mapErrors(_sync.sync);

  /// サーバーに書いた、自分の加入の期限（データ設計書 3.1.11）。課金を使えない端末でも読める。
  /// 退会の前に、加入中かを確かめるのに使う（機能仕様書 4.1.3）。
  Future<ServerPlanSubscription> fetchServerSubscription() =>
      mapErrors(() async {
        final row = await _sync.fetchOwn();
        return row == null
            ? ServerPlanSubscription.none
            : ServerPlanSubscription.fromRow(row);
      });

  /// ストアのサブスクの管理の画面。RevenueCat が URL（[managementUrl]）を返さないときは、
  /// OS のストアの管理の画面にする。プランの「解約する」と、退会の「サブスクの管理を開く」で使う。
  static Uri managementUrl([String? managementUrl]) {
    if (managementUrl != null && managementUrl.isNotEmpty) {
      return Uri.parse(managementUrl);
    }
    return Uri.parse(
      defaultTargetPlatform == TargetPlatform.android
          ? googlePlaySubscriptionsUrl
          : appStoreSubscriptionsUrl,
    );
  }

  static PlanSubscription _subscription(CustomerInfo info) {
    final xOption = info.entitlements.active[xOptionEntitlement];
    final expiration = xOption?.expirationDate;
    return PlanSubscription(
      xOption: xOption != null,
      expiresAt: expiration == null
          ? null
          : DateTime.tryParse(expiration)?.toLocal(),
      willRenew: xOption?.willRenew ?? false,
      managementUrl: info.managementURL,
    );
  }

  Future<T> _map<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } on PlatformException catch (e) {
      throw AppException(
        PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.networkError
            ? AppErrorKind.network
            : AppErrorKind.unknown,
        e,
      );
    } catch (e) {
      throw AppException(AppErrorKind.unknown, e);
    }
  }
}
