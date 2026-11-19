import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/follow/hidden_creator_service.dart';
import '../common/error_mapping.dart';

/// サインイン中のユーザーが表示しないにした発信者（機能仕様書 4.2.6）。本人にだけ効く。
class HiddenCreatorRepository {
  HiddenCreatorRepository(this._service);

  final HiddenCreatorService _service;

  /// 表示しない発信者の ID（表示しないにした順。新しい順）。
  Future<List<String>> fetchIds() => mapErrors(() async {
    final rows = await _service.fetchAll();
    return [for (final row in rows) row['creator_id'] as String];
  });

  /// 表示しない発信者に足す。フォローは、先に `FollowRepository.unfollow` で外す
  /// （ファンのカバー画像は Storage にあり、SQL からは消せないため）。
  /// すでに表示しないにしていれば、そのまま済んだものとする。
  Future<void> hide(String creatorId) => mapErrors(() async {
    try {
      await _service.insert(creatorId);
    } on PostgrestException catch (e) {
      if (e.code != PgCodes.uniqueViolation) rethrow;
    }
  });

  /// 表示するように戻す。フォローは戻さない。
  Future<void> unhide(String creatorId) =>
      mapErrors(() => _service.delete(creatorId));
}
