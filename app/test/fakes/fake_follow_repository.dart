import 'dart:async';
import 'dart:typed_data';

import 'package:oiboshi/data/repositories/follow/follow_repository.dart';
import 'package:oiboshi/data/repositories/follow/hidden_creator_repository.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:oiboshi/domain/models/follow.dart';

import 'fake_data.dart';

class FakeFollowRepository implements FollowRepository {
  FakeFollowRepository(this.data);

  final FakeData data;

  @override
  Future<List<Follow>> fetchAll() async {
    data.check();
    return List.of(data.follows);
  }

  @override
  Future<void> follow(String creatorId) async {
    data.follows.add(Follow(creatorId: creatorId, followedAt: DateTime.now()));
  }

  @override
  Future<void> unfollow(String creatorId) async {
    if (data.unfollowFails) throw const AppException(AppErrorKind.network);
    data.follows.removeWhere((f) => f.creatorId == creatorId);
    await removeCoverImage(creatorId);
  }

  @override
  Future<void> removeCoverImage(String creatorId) async {
    data.removedCovers.add(creatorId);
  }

  Follow _replace(String creatorId, Follow Function(Follow f) update) {
    final i = data.follows.indexWhere((f) => f.creatorId == creatorId);
    if (i < 0) throw const AppException(AppErrorKind.notFound);
    return data.follows[i] = update(data.follows[i]);
  }

  @override
  Future<void> markSeen(String creatorId) async {
    _replace(
      creatorId,
      (f) => Follow(
        creatorId: f.creatorId,
        followedAt: f.followedAt,
        lastSeenAt: DateTime.now(),
        coverUrl: f.coverUrl,
        showOwnCover: f.showOwnCover,
        notify: f.notify,
      ),
    );
  }

  @override
  Future<void> setNotify(String creatorId, bool notify) async {
    _replace(
      creatorId,
      (f) => Follow(
        creatorId: f.creatorId,
        followedAt: f.followedAt,
        lastSeenAt: f.lastSeenAt,
        coverUrl: f.coverUrl,
        showOwnCover: f.showOwnCover,
        notify: notify,
      ),
    );
  }

  @override
  Future<void> setCover(String creatorId, Uint8List jpeg) async {
    _replace(
      creatorId,
      (f) => Follow(
        creatorId: f.creatorId,
        followedAt: f.followedAt,
        lastSeenAt: f.lastSeenAt,
        coverUrl: 'memory://$creatorId/${jpeg.length}',
        notify: f.notify,
      ),
    );
  }

  @override
  Future<void> setShowOwnCover(String creatorId, bool showOwnCover) async {
    _replace(creatorId, (f) => f.copyWith(showOwnCover: showOwnCover));
  }

  @override
  Future<void> resetCover(String creatorId) async {
    _replace(creatorId, (f) => f.copyWith(clearCover: true));
    data.removedCovers.add(creatorId);
  }
}

class FakeHiddenCreatorRepository implements HiddenCreatorRepository {
  FakeHiddenCreatorRepository(this.data);

  final FakeData data;

  @override
  Future<List<String>> fetchIds() async {
    data.check();
    return data.hiddenCreatorIds.reversed.toList();
  }

  @override
  Future<void> hide(String creatorId) async {
    if (data.hiddenWriteFails) throw const AppException(AppErrorKind.network);
    if (!data.hiddenCreatorIds.contains(creatorId)) {
      data.hiddenCreatorIds.add(creatorId);
    }
  }

  @override
  Future<void> unhide(String creatorId) async {
    if (data.hiddenWriteFails) throw const AppException(AppErrorKind.network);
    data.hiddenCreatorIds.remove(creatorId);
  }
}
