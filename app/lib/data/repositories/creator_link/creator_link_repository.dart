import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/creator_link.dart';
import '../../../domain/models/share_link.dart';
import '../../services/creator/creator_link_service.dart';
import '../common/error_mapping.dart';

/// リンク集（届ける・広める仕様書 4.6）。
class CreatorLinkRepository {
  CreatorLinkRepository(this._service);

  final CreatorLinkService _service;

  /// ファンに見せるリンク（発信者ページ）。
  Future<List<CreatorLink>> fetchPublic(String creatorId) => mapErrors(
    () async => (await _service.fetchPublic(
      creatorId,
    )).map(CreatorLink.fromRow).toList(),
  );

  /// オーナーが見る、押された回数つきのリンク（リンク集の画面）。
  Future<List<CreatorLink>> fetchOwned(String creatorId) => mapErrors(
    () async => (await _service.fetchOwned(
      creatorId,
    )).map(CreatorLink.fromRow).toList(),
  );

  /// 足す。短縮 URL・10件を超えるときは [CreatorLinkException] を投げる。
  Future<void> add(String creatorId, String title, String url) =>
      _guard(() => _service.insert(creatorId, title.trim(), url.trim()));

  /// 直す。短縮 URL のときは [CreatorLinkException] を投げる。
  Future<void> edit(String id, String title, String url) =>
      _guard(() => _service.update(id, title.trim(), url.trim()));

  Future<void> delete(String id) => mapErrors(() => _service.delete(id));

  /// 並べ直す。並びが古ければ [CreatorLinkException]（[CreatorLinkError.stale]）を投げる。
  Future<void> reorder(String creatorId, List<String> ids) =>
      _guard(() => _service.reorder(creatorId, ids));

  /// 告知の共有の文に入れる、[urls] の短い URL（`https://oiboshi.perrii.app/s/{ID}`。届ける・広める仕様書 4.4.2）。
  /// 元の URL → 短い URL。転送先にできない URL は入らない（元の URL のまま使う）。
  Future<Map<String, String>> shortLinks(String creatorId, List<String> urls) =>
      mapErrors(() async {
        if (urls.isEmpty) return const {};
        return {
          for (final row in await _service.shortLinks(creatorId, urls))
            row['url'] as String: ShareLink.forShortId(
              row['id'] as String,
            ).toString(),
        };
      });

  /// 告知の共有の文の、[urls] の短い URL の押された回数（元の URL → 回数。届ける・広める仕様書 4.4.2）。
  Future<Map<String, int>> shortLinkCounts(
    String creatorId,
    List<String> urls,
  ) => mapErrors(() async {
    if (urls.isEmpty) return const {};
    return {
      for (final row in await _service.shortLinkCounts(creatorId, urls))
        row['url'] as String: (row['click_count'] as num).toInt(),
    };
  });

  /// 押されたことを送る。送れなくても、操作は止めない（届ける・広める仕様書 4.6.3）。
  Future<void> recordClick(String linkId) async {
    try {
      await _service.recordClick(linkId);
    } catch (e) {
      debugPrint('リンクの押された数を送れない（捨てる）: $e');
    }
  }

  /// サーバーが決まりで断った（トリガー・関数の `raise exception`）ものを、[CreatorLinkException] に変える。
  Future<void> _guard(Future<void> Function() action) => mapErrors(() async {
    try {
      await action();
    } on PostgrestException catch (e) {
      final error = switch (e.message) {
        'short_url' => CreatorLinkError.shortUrl,
        'link_limit' => CreatorLinkError.limit,
        'stale_links' => CreatorLinkError.stale,
        _ => null,
      };
      if (error == null) rethrow;
      throw CreatorLinkException(error);
    }
  });
}
