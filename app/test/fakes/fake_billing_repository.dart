import 'dart:async';

import 'package:oiboshi/data/repositories/billing/billing_repository.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:oiboshi/domain/models/plan_billing.dart';

import '../helpers/samples.dart';
import 'fake_data.dart';

/// RevenueCat の代わり。価格は日本の App Store と同じ。
class FakeBillingRepository implements BillingRepository {
  FakeBillingRepository(this.data);

  final FakeData data;

  @override
  bool get available => data.billingAvailable;

  @override
  Future<void> logIn(String userId) async => data.billingUsers.add(userId);

  @override
  Future<PlanOffer> fetchOffer() async {
    data.check();
    if (data.offerFails) throw const AppException(AppErrorKind.network);
    return PlanOffer(xOption: data.xOptionPrice);
  }

  @override
  Future<PlanSubscription> fetchSubscription() async {
    data.check();
    return data.subscription;
  }

  @override
  Future<(PlanPurchaseResult, PlanSubscription?)> purchase() async {
    if (data.purchaseResult != PlanPurchaseResult.purchased) {
      return (data.purchaseResult, null);
    }
    data.purchases++;
    data.subscription = subscribed();
    return (PlanPurchaseResult.purchased, data.subscription);
  }

  @override
  Future<PlanSubscription> restore() async =>
      data.subscription = data.restorable;

  @override
  Future<void> syncServerSubscription() async {
    data.subscriptionSyncs++;
    if (data.subscriptionSyncFails) {
      throw const AppException(AppErrorKind.network);
    }
    data.onSubscriptionSync?.call();
  }

  @override
  Future<ServerPlanSubscription> fetchServerSubscription() async {
    if (data.serverSubscriptionFails) {
      throw const AppException(AppErrorKind.network);
    }
    return data.serverSubscription;
  }
}
