/// 投稿が見られた数の、期間の合計（届ける・広める仕様書 4.2.3）。数は丸めない。
class PostViewTotals {
  const PostViewTotals({required this.opened, required this.shown});

  /// 投稿を開いた回数。
  final int opened;

  /// 投稿が画面に出た回数。
  final int shown;

  /// `post_view_totals` の1行から作る。
  factory PostViewTotals.fromRow(Map<String, dynamic> row) => PostViewTotals(
    opened: (row['opened'] as num).toInt(),
    shown: (row['shown'] as num).toInt(),
  );
}

/// アプリから送る、1つの投稿の回数。
class PostViewCount {
  const PostViewCount(this.postId, {this.opened = 0, this.shown = 0});

  final String postId;
  final int opened;
  final int shown;
}
