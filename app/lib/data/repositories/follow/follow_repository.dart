import 'dart:typed_data';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/follow.dart';
import '../../../utils/server_time.dart';
import '../../services/auth/auth_service.dart';
import '../../services/follow/cover_storage_service.dart';
import '../../services/follow/follow_service.dart';
import '../common/error_mapping.dart';

/// サインイン中のユーザーのフォロー（推し）を読み書きする。
class FollowRepository {
  FollowRepository(this._service, this._covers, this._auth);

  final FollowService _service;
  final CoverStorageService _covers;
  final AuthService _auth;

  /// フォローした順。
  Future<List<Follow>> fetchAll() => mapErrors(() async {
    final rows = await _service.fetchAll();
    return rows.map(Follow.fromRow).toList();
  });

  Future<void> follow(String creatorId) =>
      mapErrors(() => _service.insert(creatorId));

  /// フォローを解除し、その推しのカバーに選んだ自分の写真も消す（機能仕様書 4.2.4）。
  /// 写真を消せなくても、解除はできたものとする（画像は、退会のときに消える）。
  Future<void> unfollow(String creatorId) => mapErrors(() async {
    await _service.delete(creatorId);
    await removeCoverImage(creatorId);
  });

  /// その推しのカバーに選んだ自分の写真を、Storage から消す。消せなくても、失敗にしない。
  /// フォローの行を消すとき（解除・表示しない）に使う。
  Future<void> removeCoverImage(String creatorId) async {
    final uid = _auth.userId;
    if (uid == null) return;
    try {
      await _covers.remove(uid, creatorId);
    } catch (_) {}
  }

  /// 推しのページを開いたときに呼ぶ。以降は、これより新しい投稿だけを新着にする。
  Future<void> markSeen(String creatorId) => mapErrors(
    () => _service.update(creatorId, {
      'last_seen_at': DateTime.now().toServerTime(),
    }),
  );

  Future<void> setNotify(String creatorId, bool notify) =>
      mapErrors(() => _service.update(creatorId, {'notify': notify}));

  /// 推しのページのカバーを、自分の写真（JPEG）に変える。
  Future<void> setCover(String creatorId, Uint8List jpeg) =>
      mapErrors(() async {
        final uid = _auth.userId;
        if (uid == null) throw const AppException(AppErrorKind.auth);
        final url = await _covers.upload(uid, creatorId, jpeg);
        // 選んだ直後は、裏（自分の写真）を出す。
        await _service.update(creatorId, {
          'cover_url': url,
          'show_own_cover': true,
        });
      });

  /// カバーで、自分の写真（裏）と発信者のカバー（表）のどちらを出すかを覚える。
  Future<void> setShowOwnCover(String creatorId, bool showOwnCover) =>
      mapErrors(
        () => _service.update(creatorId, {'show_own_cover': showOwnCover}),
      );

  /// 「推しが設定したカバーに戻す」。自分の写真を消してから、URL を空にする。
  /// 先に画像を消すので、途中で失敗しても、もう一度押せば続きから消せる。
  Future<void> resetCover(String creatorId) => mapErrors(() async {
    final uid = _auth.userId;
    if (uid == null) throw const AppException(AppErrorKind.auth);
    await _covers.remove(uid, creatorId);
    await _service.update(creatorId, {'cover_url': null});
  });
}
