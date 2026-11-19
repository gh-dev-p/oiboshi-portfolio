import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../data/repositories/billing/billing_repository.dart';
import '../../../domain/models/login_method.dart';
import '../../../domain/models/plan_billing.dart';
import '../../core/view_models/app_language_provider.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import '../../core/view_models/display_mode_provider.dart';
import '../../core/view_models/guard.dart';
import '../../onboarding/view_models/onboarding_providers.dart';
import 'settings_providers.dart';

/// 退会に出すもの。
class WithdrawState {
  const WithdrawState({
    required this.ownsCreator,
    required this.appleElsewhere,
    required this.appleOnlyElsewhere,
    this.subscriptionNotice = false,
  });

  /// 発信者のオーナーか（発信者が90日残り、取り戻せると出す。機能仕様書 4.1.3）。
  final bool ownsCreator;

  /// iOS 以外の端末で、Apple とほかのログイン方法を結び付けているか
  /// （Apple のひも付けは取り消せないので、iPhone で外すように案内する。機能仕様書 4.1.3）。
  final bool appleElsewhere;

  /// iOS 以外の端末で、ログイン方法が Apple だけか（再認証ができないので、この端末では退会できない。
  /// iPhone で退会するように案内し、「退会する」を押せなくする。機能仕様書 4.1.3）。
  final bool appleOnlyElsewhere;

  /// プランに加入中か、加入中かを読み込めなかったか。ストアのサブスクは退会しても解約されないので、
  /// 先に解約するよう案内し、サブスクの管理を開くボタンを出す（機能仕様書 4.1.3）。読み込み中は出さない。
  final bool subscriptionNotice;
}

/// 自分の加入の期限（サーバーの `plan_subscriptions`）。課金を使えない端末や、ほかの OS で買った加入も分かる。
final _serverSubscriptionProvider =
    FutureProvider.autoDispose<ServerPlanSubscription>(
      (ref) => withSession(
        ref,
        (_) => ref.watch(billingRepositoryProvider).fetchServerSubscription(),
      ),
    );

/// 退会（画面定義書 2.1.4）。
class WithdrawViewModel extends Notifier<WithdrawState> {
  @override
  WithdrawState build() {
    final methods = ref.watch(loginMethodsProvider).value ?? const [];
    final hasApple = methods.any((m) => m.provider == LoginProvider.apple);
    final appleOnly =
        hasApple && methods.every((m) => m.provider == LoginProvider.apple);
    // Apple は、iOS の標準のシートでしか使えない（機能仕様書 4.1.4）。
    final elsewhere = defaultTargetPlatform != TargetPlatform.iOS;
    final subscription = ref.watch(_serverSubscriptionProvider);
    return WithdrawState(
      ownsCreator: ref.watch(ownedCreatorProvider).value != null,
      appleElsewhere: elsewhere && hasApple && !appleOnly,
      appleOnlyElsewhere: elsewhere && appleOnly,
      subscriptionNotice:
          subscription.hasError ||
          (subscription.value?.activeAt(ref.read(clockProvider)()) ?? false),
    );
  }

  /// ストアのサブスクの管理の画面（プランの「プランを解約する」と同じ。画面定義書 2.1.4）。
  Uri get manageSubscriptionsUrl => BillingRepository.managementUrl();

  /// データを削除して退会する。失敗したら false。
  /// 済んだら、端末内の保存も消えているので、初回起動に戻し、画面モード・表示言語を読み直す。
  /// 前のユーザーの状態を残さないように、サインインと再認証も作り直す（依存する Provider も、それで作り直される）。
  Future<bool> withdraw() async {
    if (!await succeeded(() => ref.read(authRepositoryProvider).withdraw())) {
      return false;
    }
    ref
      ..invalidate(onboardingDoneProvider)
      ..invalidate(displayModeProvider)
      ..invalidate(appLanguageProvider)
      ..invalidate(reauthProvider)
      ..invalidate(authSessionProvider);
    return true;
  }
}

final withdrawViewModelProvider =
    NotifierProvider.autoDispose<WithdrawViewModel, WithdrawState>(
      WithdrawViewModel.new,
    );
