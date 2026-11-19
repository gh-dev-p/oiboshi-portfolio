import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_settings.dart';
import '../../../domain/models/sns_service.dart';
import '../../services/creator/account_link_service.dart';
import '../../services/creator/creator_image_storage_service.dart';
import '../../services/creator/profile_import_service.dart';
import '../../../domain/models/sns_profile.dart';
import '../../services/creator/creator_service.dart';
import '../common/error_mapping.dart';

/// 発信者本人が行う、アカウント連携・プロフィール・表示する内容・予定の長さの読み書き。
class CreatorAdminRepository {
  CreatorAdminRepository(this._service, this._images, this._link, this._import);

  final CreatorService _service;
  final CreatorImageStorageService _images;
  final AccountLinkService _link;
  final ProfileImportService _import;

  /// 自分がオーナーの発信者。発信者でなければ null。
  Future<Creator?> fetchOwnedCreator() => mapErrors(() async {
    final id = await _service.fetchOwnedCreatorId();
    if (id == null) return null;
    final row = await _service.fetchById(id);
    return row == null ? null : Creator.fromRow(row);
  });

  Future<void> updateProfile(
    String creatorId, {
    required String name,
    required String bio,
    required List<String> types,
    String? avatarUrl,
    String? coverUrl,
  }) => mapErrors(
    () => _service.update(creatorId, {
      'name': name,
      'bio': bio,
      'types': types,
      'avatar_url': ?avatarUrl,
      'cover_url': ?coverUrl,
    }),
  );

  /// SNS のアカウントを、OAuth で連携する（機能仕様書 4.6.2）。
  /// [creatorId] が null なら、発信者として登録の手順からの連携（登録待ちの連携に入る）。
  Future<AccountLinkResult> linkAccount(
    String? creatorId,
    SnsService service,
  ) => mapErrors(() async {
    final url = await _link.startUrl(creatorId, service.name);
    return AccountLinkResult.fromServer(await _link.authenticate(url));
  });

  /// 発信者として登録する（機能仕様書 4.6.1）。済んだら、アイコンとカバーをアップロードし、タイプとあわせて保存する。
  /// どれかに失敗しても、登録は済んでいる。そのときは registeredPartially を返す（プロフィールの編集で直してもらう）。
  Future<RegisterResult> register({
    required String id,
    required String name,
    required String bio,
    List<String> types = const [],
    Uint8List? avatar,
    Uint8List? cover,
  }) => mapErrors(() async {
    final result = RegisterResult.fromServer(
      await _service.register(id, name, bio),
    );
    if (result != RegisterResult.registered) return result;
    var partial = false;
    Future<String?> upload(String kind, Uint8List? jpeg) async {
      if (jpeg == null) return null;
      try {
        return await _images.upload(id, kind, jpeg);
      } catch (_) {
        partial = true;
        return null;
      }
    }

    final values = {
      'avatar_url': ?await upload('avatar', avatar),
      'cover_url': ?await upload('cover', cover),
      if (types.isNotEmpty) 'types': types,
    };
    if (values.isNotEmpty) {
      try {
        await _service.update(id, values);
      } catch (_) {
        partial = true;
      }
    }
    return partial ? RegisterResult.registeredPartially : result;
  });

  /// 連携を解除する。取得した内容は90日残り、同じアカウントを連携し直すと戻る（機能仕様書 4.6.2）。
  Future<void> unlinkAccount(String creatorId, SnsService service) =>
      mapErrors(() => _service.unlinkAccount(creatorId, service.name));

  /// 取り戻せる発信者（機能仕様書 4.6.1.2）。
  Future<List<ReclaimableCreator>> fetchReclaimable() => mapErrors(() async {
    final rows = await _service.fetchReclaimable();
    return rows.map(ReclaimableCreator.fromRow).toList();
  });

  /// オーナーが退会した発信者を取り戻す（機能仕様書 4.6.1.2）。
  Future<ReclaimResult> reclaim(String creatorId) => mapErrors(
    () async => ReclaimResult.fromServer(await _service.reclaim(creatorId)),
  );

  /// 発信者として登録の手順で連携した、登録待ちのアカウント（4.6.1）。
  Future<Map<SnsService, CreatorAccount>> fetchPendingLinks() => mapErrors(
    () async {
      final rows = await _link.fetchPending();
      return {
        for (final a in rows.map(CreatorAccount.fromRow).nonNulls) a.service: a,
      };
    },
  );

  Future<void> unlinkPendingAccount(SnsService service) =>
      mapErrors(() => _link.deletePending(service.name));

  /// 確認済みの SNS から、プロフィールの下書きを取る（機能仕様書 4.6.4）。
  /// [creatorId] が null なら、登録待ちの連携から取る。アイコンが取れなくても、名前とプロフィール文は返す。
  Future<SnsProfileDraft> importProfile(
    String? creatorId,
    SnsService service,
  ) => mapErrors(() async {
    final Map<String, dynamic> json;
    try {
      json = await _import.fetch(creatorId, service.name);
    } on FunctionException catch (e) {
      // 取り込みの回数の上限（機能仕様書 4.6.4）。
      if (e.status == 429) throw AppException(AppErrorKind.rateLimited, e);
      rethrow;
    }
    final avatarUrl = json['avatarUrl'] as String?;
    Uint8List? avatar;
    if (avatarUrl != null) {
      try {
        avatar = await _import.download(avatarUrl);
      } catch (_) {
        avatar = null;
      }
    }
    return SnsProfileDraft(
      service: service,
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      avatar: avatar,
    );
  });

  Future<String> uploadAvatar(String creatorId, Uint8List jpeg) =>
      mapErrors(() => _images.upload(creatorId, 'avatar', jpeg));

  Future<String> uploadCover(String creatorId, Uint8List jpeg) =>
      mapErrors(() => _images.upload(creatorId, 'cover', jpeg));

  Future<List<CreatorDisplay>> fetchDisplays(String creatorId) =>
      mapErrors(() async {
        final rows = await _service.fetchDisplays(creatorId);
        return rows.map(CreatorDisplay.fromRow).toList();
      });

  Future<void> setDisplay(
    String creatorId,
    SnsService service,
    DisplayContent content,
    bool enabled,
  ) => mapErrors(
    () => _service.upsertDisplay({
      'creator_id': creatorId,
      'service': service.name,
      'content': content.name,
      'enabled': enabled,
    }),
  );
}
