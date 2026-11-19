import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import 'auth_session_provider.dart';

/// RevenueCat のユーザー ID を、サインインしたユーザーの ID にそろえる（機能仕様書 4.6.6）。
/// ログイン・ログアウト・ユーザーの切り替え・退会で [authSessionProvider] が作り直されると、これも作り直す。
/// アプリの土台（`app.dart`）が監視し続ける。課金を使えない端末では、何もせず null。
final billingUserProvider = FutureProvider<String?>(
  (ref) => withSession(ref, (userId) async {
    final repo = ref.watch(billingRepositoryProvider);
    if (!repo.available) return null;
    await repo.logIn(userId);
    return userId;
  }),
);
