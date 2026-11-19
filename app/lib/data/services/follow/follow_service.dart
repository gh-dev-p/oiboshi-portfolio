import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// フォローのテーブルの読み書き。どの行を読み書きできるかは、サーバーの RLS が本人に限っている。
class FollowService {
  FollowService(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _follows => _client.from(Tables.follows);

  Future<List<Map<String, dynamic>>> fetchAll() =>
      _follows.select().order('followed_at', ascending: true);

  Future<void> insert(String creatorId) =>
      _follows.insert({'creator_id': creatorId});

  Future<void> delete(String creatorId) =>
      _follows.delete().eq('creator_id', creatorId);

  Future<void> update(String creatorId, Map<String, dynamic> values) =>
      _follows.update(values).eq('creator_id', creatorId);
}
