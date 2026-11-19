import 'package:oiboshi/data/repositories/post_view/post_view_repository.dart';
import 'package:oiboshi/ui/post/view_models/post_view_tracker.dart';
import 'package:oiboshi/domain/models/post_view_totals.dart';

/// 投稿が見られた数の代わり。送った回数を [sent]（送るたびに1つ）に残す。
class FakePostViewRepository implements PostViewRepository {
  final sent = <List<PostViewCount>>[];

  /// 数の画面に返すもの。null なら読めない。
  PostViewTotals? totals = const PostViewTotals(opened: 0, shown: 0);

  @override
  Future<void> record(List<PostViewCount> counts) async => sent.add(counts);

  @override
  Future<PostViewTotals> fetchTotals(String creatorId) async {
    final t = totals;
    if (t == null) throw StateError('読めない');
    return t;
  }
}

/// 投稿の数を数えない係（Repository を差し替えずに ProviderScope を作るテスト用）。
final noPostViewTracker = postViewTrackerProvider.overrideWith((ref) {
  final tracker = PostViewTracker(
    FakePostViewRepository(),
    isOwnPost: (_) => false,
    listenLifecycle: false,
  );
  ref.onDispose(tracker.dispose);
  return tracker;
});
