import 'dart:async';

import 'package:oiboshi/data/repositories/post/post_repository.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/sns_service.dart';

import 'fake_data.dart';

class FakePostRepository implements PostRepository {
  FakePostRepository(this.data);

  final FakeData data;

  @override
  Future<List<Post>> fetchTimeline(
    List<String> creatorIds, {
    int limit = 50,
    DateTime? before,
    DateTime? since,
    Post? olderThan,
  }) async {
    data.check();
    data.timelineReads.add(olderThan);
    return sortNewestFirst(
      data.posts.where(
        (p) =>
            creatorIds.contains(p.creatorId) &&
            !data.hiddenPostIds.contains(p.id) &&
            (since == null || !p.postedAt.isBefore(since)) &&
            (before == null || p.postedAt.isBefore(before)) &&
            (olderThan == null || compareNewestFirst(olderThan, p) < 0),
      ),
    ).take(limit).toList();
  }

  @override
  Future<List<Post>> fetchByCreator(String creatorId) =>
      fetchTimeline([creatorId], limit: 600);

  @override
  Future<List<Post>> fetchYoutubeVideos(
    List<String> creatorIds, {
    int limit = 600,
  }) async {
    data.check();
    return sortNewestFirst(
      data.posts.where(
        (p) =>
            creatorIds.contains(p.creatorId) &&
            !data.hiddenPostIds.contains(p.id) &&
            p.source == SnsService.youtube &&
            p.kind == PostKind.video,
      ),
    ).take(limit).toList();
  }

  @override
  Future<List<Post>> fetchHiddenByCreator(String creatorId) async {
    data.check();
    return sortNewestFirst(
      data.posts.where(
        (p) => p.creatorId == creatorId && data.hiddenPostIds.contains(p.id),
      ),
    );
  }

  @override
  Future<void> setHidden(String postId, {required bool hidden}) async {
    if (data.hidePostFails) throw const AppException(AppErrorKind.network);
    if (hidden) {
      data.hiddenPostIds.add(postId);
    } else {
      data.hiddenPostIds.remove(postId);
    }
  }
}
