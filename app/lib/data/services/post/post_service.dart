import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/server_time.dart';
import '../common/supabase_names.dart';

/// 投稿のテーブルの読み取りと、投稿を隠す・また出す。
class PostService {
  PostService(this._client);

  final SupabaseClient _client;

  /// [creatorIds] の投稿を、新しい順（同じ時刻なら ID の降順）に [limit] 件まで。
  /// [since] 以降、[before] より前に絞れる。[olderThan] は続きを読む位置で、その投稿より後ろの順のものに絞る。
  /// [source] と [kind] で、SNS と投稿の種類に絞れる。[excludeSources] の SNS の投稿は除く。
  Future<List<Map<String, dynamic>>> fetch(
    List<String> creatorIds, {
    required int limit,
    String? source,
    String? kind,
    List<String> excludeSources = const [],
    DateTime? since,
    DateTime? before,
    ({DateTime postedAt, String id})? olderThan,
  }) async {
    if (creatorIds.isEmpty) return const [];
    var query = _client
        .from(Tables.posts)
        .select()
        .inFilter('creator_id', creatorIds);
    if (source != null) query = query.eq('source', source);
    if (kind != null) query = query.eq('kind', kind);
    if (excludeSources.isNotEmpty) {
      query = query.not('source', 'in', excludeSources);
    }
    if (since != null) {
      query = query.gte('posted_at', since.toServerTime());
    }
    if (before != null) {
      query = query.lt('posted_at', before.toServerTime());
    }
    if (olderThan != null) {
      // 同じ時刻の投稿を取りこぼさないように、時刻と ID の組で続きを読む。
      final at = _quote(olderThan.postedAt.toServerTime());
      final id = _quote(olderThan.id);
      query = query.or('posted_at.lt.$at,and(posted_at.eq.$at,id.lt.$id)');
    }
    return query
        .order('posted_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
  }

  /// 投稿を、隠す（[hidden] が真）・また出す（`set_post_hidden`）。オーナーだけが呼べる。
  Future<void> setHidden(String postId, {required bool hidden}) =>
      _client.rpc<void>(
        Functions.setPostHidden,
        params: {'p_post_id': postId, 'p_hidden': hidden},
      );

  /// オーナーに、自分の発信者の隠した投稿（`owned_hidden_posts`）。新しい順。
  /// 隠した投稿は、[fetch] では読めない（だれにも読ませない）。
  Future<List<Map<String, dynamic>>> fetchOwnedHidden(String creatorId) =>
      _client.rpc<PostgrestList>(
        Functions.ownedHiddenPosts,
        params: {'p_creator_id': creatorId},
      );

  /// PostgREST の or の値を、二重引用符で囲む（`:`・`.`・`,` を含むため）。
  static String _quote(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}
