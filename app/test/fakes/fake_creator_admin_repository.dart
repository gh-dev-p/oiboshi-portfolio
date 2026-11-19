import 'dart:async';
import 'dart:typed_data';

import 'package:oiboshi/data/repositories/creator_admin/creator_admin_repository.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/creator_settings.dart';
import 'package:oiboshi/domain/models/sns_profile.dart';
import 'package:oiboshi/domain/models/sns_service.dart';

import 'fake_data.dart';

class FakeCreatorAdminRepository implements CreatorAdminRepository {
  FakeCreatorAdminRepository(this.data);

  final FakeData data;
  final displays = <CreatorDisplay>[];

  @override
  Future<Creator?> fetchOwnedCreator() async {
    data.ownedCreatorReads++;
    data.check();
    final id = data.ownedCreatorId;
    return id == null
        ? null
        : data.creators.where((c) => c.id == id).firstOrNull;
  }

  void _setAccounts(
    String creatorId,
    void Function(Map<SnsService, CreatorAccount> accounts) change,
  ) {
    final i = data.creators.indexWhere((c) => c.id == creatorId);
    final accounts = {...data.creators[i].linkedAccounts};
    change(accounts);
    data.creators[i] = data.creators[i].copyWith(linkedAccounts: accounts);
  }

  @override
  Future<AccountLinkResult> linkAccount(
    String? creatorId,
    SnsService service,
  ) async {
    if (data.linkResult == AccountLinkResult.linked) {
      final account = CreatorAccount(
        service: service,
        account: '${service.name}_linked',
        verified: true,
      );
      if (creatorId == null) {
        data.pendingLinks[service] = account;
      } else {
        _setAccounts(creatorId, (a) => a[service] = account);
      }
    }
    return data.linkResult;
  }

  @override
  Future<RegisterResult> register({
    required String id,
    required String name,
    required String bio,
    List<String> types = const [],
    Uint8List? avatar,
    Uint8List? cover,
  }) async {
    if (data.registerResult == RegisterResult.registered) {
      final uploaded = !data.registerUploadFails;
      data.creators.add(
        Creator(
          id: id,
          name: name,
          bio: bio,
          types: types,
          avatarUrl: uploaded && avatar != null ? 'memory://avatar' : null,
          coverUrl: uploaded && cover != null ? 'memory://cover' : null,
          linkedAccounts: {...data.pendingLinks},
        ),
      );
      data.registeredAvatar = avatar;
      data.registeredCover = cover;
      data.pendingLinks.clear();
      data.ownedCreatorId = id;
      if (!uploaded && (avatar != null || cover != null)) {
        return RegisterResult.registeredPartially;
      }
    }
    return data.registerResult;
  }

  @override
  Future<List<ReclaimableCreator>> fetchReclaimable() async => [
    ...data.reclaimable,
  ];

  @override
  Future<ReclaimResult> reclaim(String creatorId) async {
    if (data.reclaimResult == ReclaimResult.reclaimed) {
      final r = data.reclaimable.firstWhere((c) => c.id == creatorId);
      data.creators.add(Creator(id: r.id, name: r.name));
      data.reclaimable.clear();
      data.pendingLinks.clear();
      data.ownedCreatorId = creatorId;
    }
    return data.reclaimResult;
  }

  @override
  Future<SnsProfileDraft> importProfile(
    String? creatorId,
    SnsService service,
  ) async {
    if (data.profileImportLimited) {
      throw const AppException(AppErrorKind.rateLimited);
    }
    final draft = data.profileDraft?.call(service);
    if (draft == null) throw const AppException(AppErrorKind.network);
    return draft;
  }

  @override
  Future<Map<SnsService, CreatorAccount>> fetchPendingLinks() async => {
    ...data.pendingLinks,
  };

  @override
  Future<void> unlinkPendingAccount(SnsService service) async =>
      data.pendingLinks.remove(service);

  @override
  Future<void> unlinkAccount(String creatorId, SnsService service) async =>
      _setAccounts(creatorId, (a) => a.remove(service));

  @override
  Future<void> updateProfile(
    String creatorId, {
    required String name,
    required String bio,
    required List<String> types,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    final i = data.creators.indexWhere((c) => c.id == creatorId);
    data.creators[i] = data.creators[i].copyWith(
      name: name,
      bio: bio,
      types: types,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
  }

  @override
  Future<String> uploadAvatar(String creatorId, Uint8List jpeg) async =>
      'memory://avatar';

  @override
  Future<String> uploadCover(String creatorId, Uint8List jpeg) async =>
      'memory://cover';

  @override
  Future<List<CreatorDisplay>> fetchDisplays(String creatorId) async =>
      List.of(displays);

  @override
  Future<void> setDisplay(
    String creatorId,
    SnsService service,
    DisplayContent content,
    bool enabled,
  ) async {
    displays
      ..removeWhere((d) => d.service == service && d.content == content)
      ..add(
        CreatorDisplay(service: service, content: content, enabled: enabled),
      );
  }
}
