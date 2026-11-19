import '../../../config/app_constants.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/sns_service.dart';
import '../../services/post/post_service.dart';
import '../common/error_mapping.dart';

/// 投稿を読む。発信者は、自分の投稿を隠す・また出すことができる。
class PostRepository {
  PostRepository(this._service);

  final PostService _service;

  /// 複数の発信者の投稿を混ぜたタイムライン。新しい順（同じ時刻なら ID の降順）に [limit] 件。
  /// [before] より古いものに絞れる。[olderThan] を渡すと、その投稿の次から続きを読む。
  Future<List<Post>> fetchTimeline(
    List<String> creatorIds, {
    int limit = timelineLimit,
    DateTime? before,
    DateTime? since,
    Post? olderThan,
  }) => mapErrors(() async {
    final rows = await _service.fetch(
      creatorIds,
      limit: limit,
      // この版で出さない SNS（v1.0.0 の Instagram・ツイキャス）の投稿は、読まない（機能仕様書 4.4.1）。
      excludeSources: _hiddenSources,
      since: since,
      before: before,
      olderThan: olderThan == null
          ? null
          : (postedAt: olderThan.postedAt, id: olderThan.id),
    );
    return rows.map(Post.fromRow).toList();
  });

  static final _hiddenSources = [
    for (final s in SnsService.values)
      if (!s.offered) s.name,
  ];

  /// 1人の発信者の投稿を、残してあるぶんすべて。
  Future<List<Post>> fetchByCreator(String creatorId) =>
      fetchTimeline([creatorId], limit: creatorPostsLimit);

  /// 複数の発信者の YouTube の動画（ショートは除く）。新しい順に [limit] 件。固定ビューアのランダム再生で使う。
  Future<List<Post>> fetchYoutubeVideos(
    List<String> creatorIds, {
    int limit = creatorPostsLimit,
  }) => mapErrors(() async {
    final rows = await _service.fetch(
      creatorIds,
      limit: limit,
      source: SnsService.youtube.name,
      kind: PostKind.video.name,
    );
    return rows.map(Post.fromRow).toList();
  });

  /// 自分の発信者の隠した投稿（機能仕様書 4.4.4）。新しい順。[fetchByCreator] には入らない。
  Future<List<Post>> fetchHiddenByCreator(String creatorId) =>
      mapErrors(() async {
        final rows = await _service.fetchOwnedHidden(creatorId);
        return [
          for (final row in rows.map(Post.fromRow))
            if (!_hiddenSources.contains(row.source.name)) row,
        ];
      });

  /// 自分の発信者の投稿を、隠す（[hidden] が真）・また出す（機能仕様書 4.4.4）。元の SNS の投稿は変わらない。
  /// 隠した投稿は、ファンにはどこにも出ず、次の取得でも隠したまま。
  Future<void> setHidden(String postId, {required bool hidden}) =>
      mapErrors(() => _service.setHidden(postId, hidden: hidden));
}
