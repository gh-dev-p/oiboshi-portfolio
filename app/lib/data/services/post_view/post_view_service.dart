import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// 投稿が見られた数（関数 `record_post_views`・`post_view_totals`、データ設計書 3.3）。
class PostViewService {
  PostViewService(this._client);

  final SupabaseClient _client;

  /// 投稿ごとの回数をまとめて足す。[items] は `{post_id, opened, shown}` の一覧（50件まで）。
  Future<void> record(List<Map<String, Object>> items) =>
      _client.rpc<void>(Functions.recordPostViews, params: {'p_items': items});

  /// 直近30日（届いた数と同じ期間）の合計。チームメンバーだけが呼べる。
  Future<Map<String, dynamic>> fetchTotals(String creatorId) async {
    final rows = await _client.rpc<PostgrestList>(
      Functions.postViewTotals,
      params: {'p_creator_id': creatorId},
    );
    return rows.single;
  }
}
