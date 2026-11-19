import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// サーバーの加入の状態（`plan_subscriptions`、データ設計書 3.1.11）の読み取りと、
/// 書き直し（Edge Function `sync-subscription`、機能仕様書 4.6.6）。
class SubscriptionSyncService {
  SubscriptionSyncService(this._client);

  final SupabaseClient _client;

  /// サーバーに、RevenueCat から加入の状態を引き直させ、`plan_subscriptions` に書かせる。
  Future<void> sync() async {
    await _client.functions.invoke(EdgeFunctions.syncSubscription);
  }

  /// 自分の加入の行（本人だけが読める）。加入したことがなければ null。
  Future<Map<String, dynamic>?> fetchOwn() => _client
      .from(Tables.planSubscriptions)
      .select('x_option_expires_at')
      .maybeSingle();
}
