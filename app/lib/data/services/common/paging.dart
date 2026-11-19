/// サーバーが1回に返す行の上限（`supabase/config.toml` の `max_rows`）。
const serverMaxRows = 1000;

/// [page] で、[pageSize] 行ずつ続きを読み、全部をつないで返す。
/// [page] は、0 から数えた行の範囲（`range(from, to)`。to を含む）を読む。
/// 返った行が [pageSize] に満たなければ、そこで終わり。並びが毎回同じになる順（一意な列まで）で読むこと。
Future<List<T>> fetchAllPages<T>(
  Future<List<T>> Function(int from, int to) page, {
  int pageSize = serverMaxRows,
}) async {
  final all = <T>[];
  while (true) {
    final rows = await page(all.length, all.length + pageSize - 1);
    all.addAll(rows);
    if (rows.length < pageSize) return all;
  }
}
