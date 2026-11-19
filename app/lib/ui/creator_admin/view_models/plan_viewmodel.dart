import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../data/repositories/billing/billing_repository.dart';
import '../../../domain/models/plan_billing.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/billing_user_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../settings/view_models/settings_providers.dart';
import 'creator_admin_providers.dart';

/// プランの画面に出すもの。
class PlanState {
  const PlanState({this.offer, this.subscription = PlanSubscription.none});

  /// 課金を使えない端末。
  static const unavailable = PlanState();

  /// 買える商品と価格。課金を使えない端末では null。
  final PlanOffer? offer;
  final PlanSubscription subscription;

  bool get available => offer != null;
}

/// プラン（画面定義書 2.3.6）。X連携プランに加入中かどうかは、サーバーではなくストアの購入から決める
/// （サーバーは Webhook の分だけ遅れる）。購入のあとは、サーバーに加入を書き直させてから、発信者の値を読み直す。
class PlanViewModel extends AsyncNotifier<PlanState> {
  @override
  Future<PlanState> build() async {
    final repo = ref.watch(billingRepositoryProvider);
    if (!repo.available) return PlanState.unavailable;
    await ref.watch(billingUserProvider.future);
    final (offer, subscription) = await (
      repo.fetchOffer(),
      repo.fetchSubscription(),
    ).wait;
    return PlanState(offer: offer, subscription: subscription);
  }

  /// 読み込めなかったときに、読み直す。
  void retry() {
    reloadFrom(ref, [authSessionProvider, billingUserProvider]);
    ref.invalidateSelf();
  }

  /// X連携プランを買う。買えたら、加入を読み直す。
  Future<PlanPurchaseResult> purchase() async {
    final current = state.value;
    if (current == null || !current.available) return PlanPurchaseResult.failed;
    final (result, subscription) = await ref
        .read(billingRepositoryProvider)
        .purchase();
    if (result == PlanPurchaseResult.purchased && subscription != null) {
      await _updated(subscription);
    }
    return result;
  }

  /// ストアの購入を読み直す。X連携プランの加入が見つかれば true。失敗したら null。
  Future<bool?> restore() async {
    final PlanSubscription subscription;
    try {
      subscription = await ref.read(billingRepositoryProvider).restore();
    } catch (_) {
      return null;
    }
    await _updated(subscription);
    return subscription.xOption;
  }

  /// ストアのサブスクの管理の画面。
  Uri get manageSubscriptionsUrl =>
      BillingRepository.managementUrl(state.value?.subscription.managementUrl);

  Future<void> _updated(PlanSubscription subscription) async {
    if (!ref.mounted) return;
    final offer = state.value?.offer;
    state = AsyncData(PlanState(offer: offer, subscription: subscription));
    // Webhook を待たずに、サーバーの加入を書き直させる。できなくても、読み直す（Webhook で追いつく）。
    final billing = ref.read(billingRepositoryProvider);
    try {
      await billing.syncServerSubscription();
    } catch (_) {}
    if (!ref.mounted) return;
    // サーバーの加入から決まる発信者の値（X の連携）を読み直す。
    ref.invalidate(ownedCreatorProvider);
    ref.invalidate(creatorAdminDataProvider);
  }
}

final planViewModelProvider =
    AsyncNotifierProvider.autoDispose<PlanViewModel, PlanState>(
      PlanViewModel.new,
    );

/// X連携プランの、ストアの月額。表示するコンテンツの X の注記に出す（画面定義書 2.3.3）。
/// 課金を使えない端末・読み込めないときは null（アプリに持つ月額を出す）。
final xOptionPriceProvider = FutureProvider.autoDispose<PlanPrice?>((
  ref,
) async {
  final repo = ref.watch(billingRepositoryProvider);
  if (!repo.available) return null;
  try {
    await ref.watch(billingUserProvider.future);
    return (await repo.fetchOffer()).xOption;
  } catch (_) {
    return null;
  }
});
