import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/edge_functions.dart';
import '../common/supabase_names.dart';

/// 発信者のテーブルの読み書き。
class CreatorService {
  CreatorService(this._client);

  final SupabaseClient _client;

  /// 発信者に付けて読む、配信中の情報と SNS のアカウント。
  /// 予定のデフォルトの長さ（`creator_event_lengths`・`default_event_minutes`）は、設定を無くしたので読まない
  /// （2026-11-19 本人。表と列は v1.0.0 のアプリが使うので残し、あとの版で消す）。
  static const _summaryColumns =
      '*, lives(*), ${Tables.creatorAccounts}(service, account, verified_at, handle, '
      'profile_name, profile_username, profile_image_url)';

  /// 発信者に、最新の投稿日時、配信中の情報、SNS のアカウントを付けて読む。
  PostgrestFilterBuilder<PostgrestList> get _summaries =>
      _client.from(Tables.creatorSummaries).select(_summaryColumns);

  /// 一度に読む件数（おすすめ・探す）。
  static const _maxCount = 20;

  /// 推しを探す・推しを選ぶの「おすすめ」（`recommend_creators`、機能仕様書 4.2.2.2）。サーバーが選んだ順。
  Future<List<Map<String, dynamic>>> recommend() => _client
      .rpc<PostgrestList>(
        Functions.recommendCreators,
        params: {'max_count': _maxCount},
      )
      .select(_summaryColumns);

  /// 発信者のタイプの一覧（並び順）。
  Future<List<Map<String, dynamic>>> fetchTypes() =>
      // order は既定が降順なので、昇順を明示する（一覧の並び順は小さい順。データ設計書 3.1.2）。
      _client
          .from(Tables.creatorTypes)
          .select()
          .order('position', ascending: true)
          .order('id', ascending: true);

  Future<Map<String, dynamic>?> fetchById(String id) =>
      _summaries.eq('id', id).maybeSingle();

  Future<List<Map<String, dynamic>>> fetchMany(List<String> ids) =>
      ids.isEmpty ? Future.value(const []) : _summaries.inFilter('id', ids);

  /// 名前・ID・確認済みの SNS のアカウントで探す（`search_creators`）。合い方の順。
  Future<List<Map<String, dynamic>>> search(String query) => _client
      .rpc<PostgrestList>(
        Functions.searchCreators,
        params: {'query': query, 'max_count': _maxCount},
      )
      .select(_summaryColumns);

  /// 共有のリンクで見せてよい発信者か（`shared_creator`、届ける・広める仕様書 4.3.1）。
  /// ファンに見せない発信者（確認済みのアカウントがない・停止中・オーナーが退会した）・ない発信者なら false。
  Future<bool> isShareable(String id) async {
    final rows = await _client.rpc<PostgrestList>(
      Functions.sharedCreator,
      params: {'p_creator_id': id},
    );
    return rows.isNotEmpty;
  }

  /// 自分がオーナーの発信者の ID。発信者でなければ null。
  Future<String?> fetchOwnedCreatorId() async {
    final row = await _client
        .from(Tables.creatorOwners)
        .select('creator_id')
        .maybeSingle();
    return row?['creator_id'] as String?;
  }

  Future<void> update(String id, Map<String, dynamic> values) =>
      _client.from(Tables.creators).update(values).eq('id', id);

  /// 発信者として登録する（Edge Function `register-creator`）。結果の文字列を返す。
  /// サーバーが、基本プランの加入を RevenueCat に問い合わせて確かめてから登録する。
  Future<String?> register(String id, String name, String bio) =>
      _client.functions.invokeResult<String?>(
        EdgeFunctions.registerCreator,
        body: {'id': id, 'name': name, 'bio': bio},
      );

  /// 連携を解除する（オーナーだけ。`unlink_creator_account`）。内容は90日残る。
  Future<void> unlinkAccount(String creatorId, String service) =>
      _client.rpc<void>(
        Functions.unlinkCreatorAccount,
        params: {'p_creator_id': creatorId, 'p_service': service},
      );

  /// 取り戻せる発信者（`reclaimable_creators`）。登録待ちの連携から決まる。
  Future<List<Map<String, dynamic>>> fetchReclaimable() =>
      _client.rpc<PostgrestList>(Functions.reclaimableCreators);

  /// オーナーが退会した発信者を取り戻す（Edge Function `reclaim-creator`）。結果の文字列を返す。
  Future<String?> reclaim(String creatorId) =>
      _client.functions.invokeResult<String?>(
        EdgeFunctions.reclaimCreator,
        body: {'creatorId': creatorId},
      );

  Future<List<Map<String, dynamic>>> fetchDisplays(String creatorId) =>
      _client.from(Tables.creatorDisplays).select().eq('creator_id', creatorId);

  Future<void> upsertDisplay(Map<String, dynamic> row) =>
      _client.from(Tables.creatorDisplays).upsert(row);
}
