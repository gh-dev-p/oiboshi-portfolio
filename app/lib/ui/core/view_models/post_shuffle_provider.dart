import 'dart:math';

import '../../../domain/models/post.dart';

/// 固定ビューアのランダム再生（試作）の順番。フォロー中の推しの動画を、次々に流す。
/// 1周で、推しを1人1本ずつ、シャッフルした順に流す（推しごとに同じくらい流し、多く投稿する推しに偏らない）。
/// 推しが2人以上なら、同じ推しを続けない（周のつなぎ目でも続けない）。
/// 推しの動画は、その推しの中でシャッフルし、全部流したら、シャッフルし直して繰り返す。
/// 戻ったぶんは、流した順を覚えておき、同じ動画をたどる。
class PostShuffle {
  PostShuffle(Iterable<Post> posts, {Random? random})
    : _random = random ?? Random() {
    for (final post in posts) {
      (_all[post.creatorId] ??= []).add(post);
    }
  }

  final Random _random;

  /// 推しごとの動画。
  final Map<String, List<Post>> _all = {};

  /// 推しごとの、まだ流していない動画（シャッフル済み。後ろから取る）。
  final Map<String, List<Post>> _left = {};

  /// この周で、まだ流していない推し（シャッフル済み。後ろから取る）。
  List<String> _round = [];

  /// 流した順。
  final List<Post> _history = [];

  /// いま流している動画の、[_history] の位置。まだ流していなければ -1。
  int _index = -1;

  /// 流せる動画がないか。
  bool get isEmpty => _all.isEmpty;

  /// いま流している動画。
  Post? get current => _index < 0 ? null : _history[_index];

  /// 前の動画があるか。
  bool get hasPrevious => _index > 0;

  /// 次の動画に進む。戻っていたら、前に流した順にたどる。
  Post? next() {
    if (isEmpty) return null;
    if (_index < _history.length - 1) return _history[++_index];
    _history.add(_draw());
    return _history[++_index];
  }

  /// まだ何も流していなければ、[postId] の動画から始める（固定ビューアを開き直して、続きから流すとき）。
  /// その動画がなければ（追星から消した・推しでなくなったなど）、何もせずに null を返す。
  /// 始めた動画の推しは、この周ではもう選ばず、その動画も、その推しの動画を一巡するまでは流さない。
  Post? startAt(String postId) {
    if (_index >= 0) return null;
    final post = _all.values
        .expand((posts) => posts)
        .where((p) => p.id == postId)
        .firstOrNull;
    if (post == null) return null;
    _round = _all.keys.where((id) => id != post.creatorId).toList()
      ..shuffle(_random);
    _left[post.creatorId] =
        _all[post.creatorId]!.where((p) => p.id != postId).toList()
          ..shuffle(_random);
    _history.add(post);
    _index = 0;
    return post;
  }

  /// 前の動画に戻る。なければ null。
  Post? previous() => hasPrevious ? _history[--_index] : null;

  /// 次に流す動画を選ぶ。
  Post _draw() {
    final last = _history.lastOrNull?.creatorId;
    if (_round.isEmpty) {
      _round = _all.keys.toList()..shuffle(_random);
      // 周のつなぎ目で、同じ推しを続けない（後ろから取るので、末尾を入れ替える）。
      if (_round.length > 1 && _round.last == last) {
        final i = _random.nextInt(_round.length - 1);
        _round[_round.length - 1] = _round[i];
        _round[i] = last!;
      }
    }
    final creatorId = _round.removeLast();
    final left = _left[creatorId] ??= [];
    if (left.isEmpty) {
      final previous = _history.reversed
          .where((p) => p.creatorId == creatorId)
          .firstOrNull;
      left.addAll(_all[creatorId]!..shuffle(_random));
      // シャッフルし直したとき、その推しの前の動画を、すぐには流さない。
      if (left.length > 1 && left.last.id == previous?.id) {
        final i = _random.nextInt(left.length - 1);
        left[left.length - 1] = left[i];
        left[i] = previous!;
      }
    }
    return left.removeLast();
  }
}
