import 'dart:async';

import 'package:oiboshi/data/repositories/creator/creator_repository.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/creator_search.dart';
import 'package:oiboshi/domain/models/creator_type.dart';

import 'fake_data.dart';

class FakeCreatorRepository implements CreatorRepository {
  FakeCreatorRepository(this.data);

  final FakeData data;

  /// サーバー（`recommend_creators`）と同じく、フォロー済み・休止中を除き、推しのタイプに合う発信者を先に、
  /// 次に優先のフラグの付いた発信者を出す。テストで順番を決めるため、ランダムの代わりに名前順にする。
  @override
  Future<List<Creator>> recommend() async {
    data.check();
    data.recommendCount++;
    final followed = {for (final f in data.follows) f.creatorId};
    final oshiTypes = {
      for (final c in data.creators)
        if (followed.contains(c.id)) ...c.types,
    };
    int rank(Creator c) => c.types.any(oshiTypes.contains)
        ? 0
        : data.featured.contains(c.id)
        ? 1
        : 2;
    return data.creators
        .where(
          (c) =>
              !followed.contains(c.id) && !data.hiddenCreatorIds.contains(c.id),
        )
        .toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
  }

  @override
  Future<List<CreatorType>> fetchTypes() async {
    data.check();
    return [...data.creatorTypes];
  }

  @override
  Future<Creator?> fetchById(String id) async {
    data.check();
    return data.creators.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<bool> isShareable(String id) async {
    data.check();
    return data.creators.any((c) => c.id == id) &&
        !data.unshareableCreatorIds.contains(id);
  }

  @override
  Future<List<Creator>> fetchMany(List<String> ids) async {
    data.check();
    return [for (final id in ids) ...data.creators.where((c) => c.id == id)];
  }

  @override
  Future<List<Creator>> search(String query) async {
    data.check();
    data.searches.add(query);
    return filterCreators(
      data.creators
          .where((c) => !data.hiddenCreatorIds.contains(c.id))
          .toList(),
      query,
    );
  }
}
