import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../data/repositories/post_view/post_view_repository.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/post_view_totals.dart';
import '../../settings/view_models/settings_providers.dart';

/// 投稿が見られた数（届ける・広める仕様書 4.2.3）を、アプリの中でためて、まとめて送る。
/// - 表示された数：同じ投稿は、アプリを起動してから1回だけ数える。
/// - 開いた数：開くたびに数える（同じビューアの中で同じ投稿を数え直さないのは、ビューアの側）。
/// - 送るのは、最初に数えてから [interval] 後・[maxItems] 件たまったとき・アプリが裏に回ったとき。
/// - 自分のチームの発信者の投稿は、数えない（サーバーでも外す）。
class PostViewTracker {
  PostViewTracker(
    this._repository, {
    required bool Function(Post post) isOwnPost,
    this.interval = const Duration(seconds: 30),
    bool listenLifecycle = true,
  }) : _isOwnPost = isOwnPost {
    if (listenLifecycle) {
      _lifecycle = AppLifecycleListener(onHide: flush);
    }
  }

  /// 1回の送信の上限（サーバーの上限と同じ）。
  static const maxItems = 50;

  final PostViewRepository _repository;
  final bool Function(Post post) _isOwnPost;
  final Duration interval;
  AppLifecycleListener? _lifecycle;

  final _shownOnce = <String>{};
  final _opened = <String, int>{};
  final _shown = <String>{};
  Timer? _timer;

  /// この起動の間に、もう表示された数に数えたか。
  bool hasShown(String postId) => _shownOnce.contains(postId);

  /// 投稿のカードが、数える決まりを満たして画面に出た。
  void shown(Post post) {
    if (_isOwnPost(post) || !_shownOnce.add(post.id)) return;
    _shown.add(post.id);
    _queued();
  }

  /// 投稿ビューアで投稿が出た。
  void opened(Post post) {
    if (_isOwnPost(post)) return;
    _opened.update(post.id, (n) => n + 1, ifAbsent: () => 1);
    _queued();
  }

  void _queued() {
    if ({..._opened.keys, ..._shown}.length >= maxItems) {
      flush();
    } else {
      _timer ??= Timer(interval, flush);
    }
  }

  /// ためた分を送る。
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    final ids = {..._opened.keys, ..._shown};
    if (ids.isEmpty) return Future.value();
    final counts = [
      for (final id in ids)
        PostViewCount(
          id,
          opened: _opened[id] ?? 0,
          shown: _shown.contains(id) ? 1 : 0,
        ),
    ];
    _opened.clear();
    _shown.clear();
    return _repository.record(counts);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _lifecycle?.dispose();
  }
}

/// アプリの間ずっと持つ、投稿の数の係。
final postViewTrackerProvider = Provider<PostViewTracker>((ref) {
  // 自分のチームの発信者が分かるまでは、数えて送る（サーバーが外す）。
  ref.listen(ownedCreatorProvider, (_, _) {});
  final tracker = PostViewTracker(
    ref.watch(postViewRepositoryProvider),
    isOwnPost: (post) =>
        ref.read(ownedCreatorProvider).value?.id == post.creatorId,
  );
  ref.onDispose(tracker.dispose);
  return tracker;
});
