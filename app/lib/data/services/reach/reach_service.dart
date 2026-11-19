import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// 発信者に見せる数の、アプリからの記録（関数 `record_reach`、データ設計書 3.3）。
class ReachService {
  ReachService(this._client);

  final SupabaseClient _client;

  /// [kind] は `opened`（通知から開いた）か `viewed`（予定を開いた）。[subject] は `live:…` か `schedule:…`。
  Future<void> record(String creatorId, String kind, String subject) =>
      _client.rpc<void>(
        Functions.recordReach,
        params: {
          'p_creator_id': creatorId,
          'p_kind': kind,
          'p_subject': subject,
        },
      );

  /// 直近30日の合計（`reach_totals`）。チームメンバーだけが呼べる。
  Future<Map<String, dynamic>> fetchTotals(String creatorId) async {
    final rows = await _client.rpc<PostgrestList>(
      Functions.reachTotals,
      params: {'p_creator_id': creatorId},
    );
    return rows.single;
  }

  /// 配信・予定ごとの数（`reach_by_subject`）。新しい順。
  Future<List<Map<String, dynamic>>> fetchBySubject(String creatorId) =>
      _client.rpc<PostgrestList>(
        Functions.reachBySubject,
        params: {'p_creator_id': creatorId},
      );
}
