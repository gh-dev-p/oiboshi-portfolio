import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat の SDK（`purchases_flutter`）のラッパー。[apiKey] は、その端末のストアの公開用のキー。
class BillingService {
  const BillingService(this.apiKey);

  final String apiKey;

  /// 課金を使えるか（キーがあるか）。
  bool get available => apiKey.isNotEmpty;

  /// RevenueCat のユーザーを [userId] にする。初めてなら、そのユーザーで初期化する。
  Future<void> logIn(String userId) async {
    if (!await Purchases.isConfigured) {
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = userId,
      );
      return;
    }
    if (await Purchases.appUserID == userId) return;
    await Purchases.logIn(userId);
  }

  Future<Offerings> getOfferings() => Purchases.getOfferings();

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  Future<PurchaseResult> purchase(PurchaseParams params) =>
      Purchases.purchase(params);

  Future<CustomerInfo> restore() => Purchases.restorePurchases();
}
