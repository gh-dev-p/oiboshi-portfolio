import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// 表示しない発信者のテーブルの読み書き。どの行を読み書きできるかは、サーバーの RLS が本人に限っている。
class HiddenCreatorService {
  HiddenCreatorService(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _hidden => _client.from(Tables.hiddenCreators);

  /// 表示しないにした順（新しい順）。
  Future<List<Map<String, dynamic>>> fetchAll() => _hidden
      .select('creator_id, hidden_at')
      .order('hidden_at', ascending: false);

  /// 表示しない発信者に足す。ユーザー ID は、サーバーが自分にする。
  Future<void> insert(String creatorId) =>
      _hidden.insert({'creator_id': creatorId});

  Future<void> delete(String creatorId) =>
      _hidden.delete().eq('creator_id', creatorId);
}
