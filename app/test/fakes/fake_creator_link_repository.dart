import 'package:oiboshi/data/repositories/creator_link/creator_link_repository.dart';
import 'package:oiboshi/domain/models/creator_link.dart';
import 'package:oiboshi/domain/models/share_link.dart';

import 'fake_data.dart';

/// リンク集の代わり。発信者ごとのリンクを [FakeData.creatorLinks] に持つ。
/// URL に `bit.ly` を含むと短縮 URL として断る（サーバーの一覧の代わり）。
class FakeCreatorLinkRepository implements CreatorLinkRepository {
  FakeCreatorLinkRepository(this.data);

  final FakeData data;
  var _next = 0;

  List<CreatorLink> _links(String creatorId) =>
      data.creatorLinks.putIfAbsent(creatorId, () => []);

  @override
  Future<List<CreatorLink>> fetchPublic(String creatorId) async => [
    for (final l in _links(creatorId))
      CreatorLink(id: l.id, title: l.title, url: l.url),
  ];

  @override
  Future<List<CreatorLink>> fetchOwned(String creatorId) async => [
    ..._links(creatorId),
  ];

  @override
  Future<void> add(String creatorId, String title, String url) async {
    if (url.contains('bit.ly')) {
      throw const CreatorLinkException(CreatorLinkError.shortUrl);
    }
    final links = _links(creatorId);
    if (links.length >= CreatorLinkRules.maxLinks) {
      throw const CreatorLinkException(CreatorLinkError.limit);
    }
    links.add(
      CreatorLink(
        id: 'new${_next++}',
        title: title.trim(),
        url: url.trim(),
        clickCount: 0,
      ),
    );
  }

  @override
  Future<void> edit(String id, String title, String url) async {
    if (url.contains('bit.ly')) {
      throw const CreatorLinkException(CreatorLinkError.shortUrl);
    }
    for (final links in data.creatorLinks.values) {
      final i = links.indexWhere((l) => l.id == id);
      if (i < 0) continue;
      final old = links[i];
      links[i] = CreatorLink(
        id: id,
        title: title.trim(),
        url: url.trim(),
        clickCount: old.url == url.trim() ? old.clickCount : 0,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    for (final links in data.creatorLinks.values) {
      links.removeWhere((l) => l.id == id);
    }
  }

  @override
  Future<void> reorder(String creatorId, List<String> ids) async {
    final links = _links(creatorId);
    final byId = {for (final l in links) l.id: l};
    links
      ..clear()
      ..addAll([for (final id in ids) byId[id]!]);
  }

  @override
  Future<void> recordClick(String linkId) async => data.linkClicks.add(linkId);

  /// サーバーの `short_link_counts` の代わり。作った短い URL の数を、[FakeData.shortLinkClicks] から返す。
  @override
  Future<Map<String, int>> shortLinkCounts(
    String creatorId,
    List<String> urls,
  ) async {
    if (data.shortLinksFail) throw Exception('通信の失敗');
    return {
      for (final url in urls)
        if (data.shortLinkIds.containsKey(url))
          url: data.shortLinkClicks[url] ?? 0,
    };
  }

  /// サーバーの `short_links_for` の代わり。同じ URL は同じ ID。`evil` を含む URL は、転送先にできないので返さない。
  @override
  Future<Map<String, String>> shortLinks(
    String creatorId,
    List<String> urls,
  ) async {
    if (data.shortLinksFail) throw Exception('通信の失敗');
    return {
      for (final url in urls)
        if (!url.contains('evil'))
          url: ShareLink.forShortId(
            data.shortLinkIds.putIfAbsent(
              url,
              () => 'short${data.shortLinkIds.length}'.padRight(12, 'x'),
            ),
          ).toString(),
    };
  }
}
