import 'package:oiboshi/data/repositories/reach/reach_repository.dart';
import 'package:oiboshi/domain/models/reach_overview.dart';

/// 発信者に見せる数の記録の代わり。送った記録を [records]（`種類 発信者 対象`）に残す。
class FakeReachRepository implements ReachRepository {
  final records = <String>[];

  @override
  Future<void> recordOpened(
    String creatorId, {
    String? scheduleId,
    String? liveService,
    String? liveId,
  }) async {
    final subject = scheduleId != null
        ? 'schedule:$scheduleId'
        : (liveService != null && liveId != null)
        ? 'live:$liveService:$liveId'
        : null;
    if (subject != null) records.add('opened $creatorId $subject');
  }

  @override
  Future<void> recordViewed(String creatorId, String scheduleId) async =>
      records.add('viewed $creatorId schedule:$scheduleId');

  /// 数の画面に返すもの。null なら読めない。
  ReachOverview? overview;

  @override
  Future<ReachOverview> fetchOverview(String creatorId) async {
    final o = overview;
    if (o == null) throw StateError('読めない');
    return o;
  }
}
