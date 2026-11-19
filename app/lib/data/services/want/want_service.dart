import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// 追いたいの読み書き（データ設計書 3.1.30・3.1.31・3.3）。押すのは関数だけ。
class WantService {
  WantService(this._client);

  final SupabaseClient _client;

  /// 追いたいを押す。サーバーの `{"result": ...}` を返す。
  Future<Map<String, dynamic>> want(String service, String account) =>
      _client.rpc<PostgrestMap>(
        Functions.wantAccount,
        params: {'p_service': service, 'p_account': account},
      );

  /// 自分が押した追いたい（新しい順。押した人数つき）。
  Future<List<Map<String, dynamic>>> fetchMine() =>
      _client.rpc<PostgrestList>(Functions.myWants);

  /// 取り消す（自分の行だけ消せる）。
  Future<void> cancel(String wantedAccountId) => _client
      .from(Tables.wants)
      .delete()
      .eq('wanted_account_id', wantedAccountId);
}
