import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_type.dart';
import '../../services/creator/creator_service.dart';
import '../common/error_mapping.dart';

/// 発信者を読む。書き込みはサーバー（Edge Functions）と、発信者本人（creator_admin）が行う。
class CreatorRepository {
  CreatorRepository(this._service);

  final CreatorService _service;

  /// おすすめの発信者（機能仕様書 4.2.2.2）。サーバーが選んだ順。読むたびに変わる。
  Future<List<Creator>> recommend() => mapErrors(() async {
    final rows = await _service.recommend();
    return rows.map(Creator.fromRow).toList();
  });

  /// 発信者のタイプの一覧（機能仕様書 4.6.4）。並び順。
  Future<List<CreatorType>> fetchTypes() => mapErrors(() async {
    final rows = await _service.fetchTypes();
    return rows.map(CreatorType.fromRow).toList();
  });

  Future<Creator?> fetchById(String id) => mapErrors(() async {
    final row = await _service.fetchById(id);
    return row == null ? null : Creator.fromRow(row);
  });

  /// [query] に合う発信者（機能仕様書 4.2.2）。サーバーで探し、合い方の順に返す。
  Future<List<Creator>> search(String query) => mapErrors(() async {
    final rows = await _service.search(query);
    return rows.map(Creator.fromRow).toList();
  });

  /// 共有のリンクで見せてよい発信者か（届ける・広める仕様書 4.3.1）。リンクから開く・共有する前に確かめる。
  Future<bool> isShareable(String id) =>
      mapErrors(() => _service.isShareable(id));

  /// [ids] の発信者。並び順は [ids] の順。
  Future<List<Creator>> fetchMany(List<String> ids) => mapErrors(() async {
    final rows = await _service.fetchMany(ids);
    final byId = {
      for (final row in rows) row['id'] as String: Creator.fromRow(row),
    };
    return [for (final id in ids) ?byId[id]];
  });
}
