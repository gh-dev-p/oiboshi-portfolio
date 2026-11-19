import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// リンク集（届ける・広める仕様書 4.6、データ設計書 3.1.32・3.3）。
class CreatorLinkService {
  CreatorLinkService(this._client);

  final SupabaseClient _client;

  /// ファンに見せるリンク（並び順）。押された回数の列は、ファンには読めないので取らない。
  Future<List<Map<String, dynamic>>> fetchPublic(String creatorId) => _client
      .from(Tables.creatorLinks)
      .select('id, title, url')
      .eq('creator_id', creatorId)
      // order は既定が降順なので、昇順を明示する（並び順は小さい順）。
      .order('position', ascending: true)
      .order('created_at', ascending: true);

  /// オーナーが読む、押された回数つきのリンク（`owned_creator_links`）。
  Future<List<Map<String, dynamic>>> fetchOwned(String creatorId) =>
      _client.rpc<PostgrestList>(
        Functions.ownedCreatorLinks,
        params: {'p_creator_id': creatorId},
      );

  /// 足す。並び順は、サーバーがいちばん下にする。
  Future<void> insert(String creatorId, String title, String url) => _client
      .from(Tables.creatorLinks)
      .insert({'creator_id': creatorId, 'title': title, 'url': url});

  /// 題名と URL を直す。
  Future<void> update(String id, String title, String url) => _client
      .from(Tables.creatorLinks)
      .update({'title': title, 'url': url})
      .eq('id', id);

  Future<void> delete(String id) =>
      _client.from(Tables.creatorLinks).delete().eq('id', id);

  /// [ids] の順に並べ直す（`reorder_creator_links`）。
  Future<void> reorder(String creatorId, List<String> ids) => _client.rpc<void>(
    Functions.reorderCreatorLinks,
    params: {'p_creator_id': creatorId, 'p_ids': ids},
  );

  /// [urls] の短い URL の ID を、URL ごとに返す（`short_links_for`。無ければサーバーが作る）。
  /// 転送先にできない URL の行は返らない（届ける・広める仕様書 4.4.2）。
  Future<List<Map<String, dynamic>>> shortLinks(
    String creatorId,
    List<String> urls,
  ) => _client.rpc<PostgrestList>(
    Functions.shortLinksFor,
    params: {'p_creator_id': creatorId, 'p_urls': urls},
  );

  /// [urls] の短い URL の押された回数（`short_link_counts`）。チームメンバーでなければ空。
  Future<List<Map<String, dynamic>>> shortLinkCounts(
    String creatorId,
    List<String> urls,
  ) => _client.rpc<PostgrestList>(
    Functions.shortLinkCounts,
    params: {'p_creator_id': creatorId, 'p_urls': urls},
  );

  /// 押された回数を1足す（`record_link_click`）。オーナー自身の分は、サーバーが数えない。
  Future<void> recordClick(String linkId) => _client.rpc<void>(
    Functions.recordLinkClick,
    params: {'p_link_id': linkId},
  );
}
