import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/post_view_totals.dart';
import '../../../domain/models/reach_overview.dart';

/// 数の画面（届いた数）に出すもの（発信者ごと。届ける・広める仕様書 4.2.2）。
final reachOverviewProvider = FutureProvider.autoDispose
    .family<ReachOverview, String>(
      (ref, creatorId) =>
          ref.read(reachRepositoryProvider).fetchOverview(creatorId),
    );

/// 数の画面の、投稿が見られた数の直近30日の合計（届ける・広める仕様書 4.2.3）。
/// ほかの数とは別に読む（読めなくても、ほかの数は出す）。
final postViewTotalsProvider = FutureProvider.autoDispose
    .family<PostViewTotals, String>(
      (ref, creatorId) =>
          ref.read(postViewRepositoryProvider).fetchTotals(creatorId),
    );
