import 'package:flutter/foundation.dart';

import '../../../domain/models/post_view_totals.dart';
import '../../services/post_view/post_view_service.dart';
import '../common/error_mapping.dart';

/// 投稿が見られた数（届ける・広める仕様書 4.2.3）。誰が見たかは送らず、投稿ごとの回数だけを送る。
class PostViewRepository {
  PostViewRepository(this._service);

  final PostViewService _service;

  /// 投稿ごとの回数を送る。送れなかったときは捨てる（送り直さない）。
  Future<void> record(List<PostViewCount> counts) async {
    if (counts.isEmpty) return;
    try {
      await _service.record([
        for (final c in counts)
          {'post_id': c.postId, 'opened': c.opened, 'shown': c.shown},
      ]);
    } catch (e) {
      debugPrint('投稿の数を送れない（捨てる）: $e');
    }
  }

  /// 届いた数の画面に出す、直近30日の合計。
  Future<PostViewTotals> fetchTotals(String creatorId) => mapErrors(
    () async => PostViewTotals.fromRow(await _service.fetchTotals(creatorId)),
  );
}
