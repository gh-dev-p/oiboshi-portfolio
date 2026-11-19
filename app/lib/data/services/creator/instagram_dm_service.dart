// 【仮】Instagram の DM での確認（機能仕様書 4.6.2.1）。
// Meta の審査が通るまでの、一時的な仕組み。通ったら、このファイルごと外す。
import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// DM の確認のコードの読み書き（データ設計書 3.1.7）。
class InstagramDmService {
  InstagramDmService(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _requests =>
      _client.from(Tables.instagramDmRequests);

  /// DM の受け先の Instagram のユーザー名。空なら null。
  Future<String?> fetchDmAccount() =>
      _client.rpc<String?>(Functions.instagramDmAccount);

  /// [creatorId] のコード。null なら、登録の手順のコード。
  Future<Map<String, dynamic>?> fetchRequest(String? creatorId) {
    final query = _requests.select('id, creator_id, account, code, created_at');
    return (creatorId == null
            ? query.isFilter('creator_id', null)
            : query.eq('creator_id', creatorId))
        .maybeSingle();
  }

  /// コードを出す。サーバーの `{"result": ...}` を返す。
  Future<Map<String, dynamic>> request(String? creatorId, String account) =>
      _client.rpc<PostgrestMap>(
        Functions.requestInstagramDm,
        params: {'p_creator_id': creatorId, 'p_account': account},
      );

  /// コードを消す（取り消し。本人の行だけ消せる）。
  Future<void> delete(String id) => _requests.delete().eq('id', id);
}
