import '../../utils/search_text.dart';
import 'creator.dart';

/// 名前・ID・確認済みの SNS のアカウント（ハンドルを含む）で、手元の一覧を絞り込む（機能仕様書 4.2.2）。推しリストで使う（推しを選ぶ・推しを探すは、サーバーで探す）。
/// 表記の揺れは [normalizeForSearch] でそろえ、言葉の先頭に続く `@` は、サーバーの検索（`search_creators`）と同じく、すべて無視する。
List<Creator> filterCreators(List<Creator> creators, String query) {
  var q = normalizeForSearch(query.trim());
  q = q.replaceFirst(RegExp('^@+'), '');
  if (q.isEmpty) return creators;
  return creators
      .where(
        (c) => [
          c.name,
          c.id,
          for (final a in c.linkedAccounts.values)
            if (a.verified) ...[a.account, ?a.handle],
        ].any((text) => normalizeForSearch(text).contains(q)),
      )
      .toList();
}
