import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_settings.dart';
import '../../../domain/models/sns_service.dart';
import '../../core/view_models/guard.dart';
import '../../oshi/view_models/oshi_providers.dart';
import '../../settings/view_models/settings_providers.dart';
import 'creator_admin_providers.dart';

/// 発信者として登録の画面に出すもの。手順1（連携）は登録待ちの連携、手順2（プロフィール）は登録の下書きから決める。
/// 読めるまで待たずに「まだ」として出す。プランの加入は要らない（基本プランは無料。機能仕様書 4.6.1）。
class CreatorRegisterState {
  const CreatorRegisterState({
    required this.linkedServices,
    required this.profileDone,
    required this.profileName,
    required this.profileId,
    required this.agreed,
    this.reclaimable,
  });

  /// 手順1で連携した SNS。1つ以上で、手順1が済む。
  final List<SnsService> linkedServices;

  /// 手順2（名前と ID の入力）が済んだか。
  final bool profileDone;
  final String profileName;
  final String profileId;

  /// 発信者向けの利用規約に同意したか。
  final bool agreed;

  /// 取り戻せる発信者（手順1で連携したアカウントが、オーナーが退会した発信者のものだったとき）。
  final ReclaimableCreator? reclaimable;

  bool get linkDone => linkedServices.isNotEmpty;

  /// 2つの手順と、規約への同意が済むと、登録できる。
  bool get canRegister => linkDone && profileDone && agreed;
}

/// 発信者として登録（画面定義書 2.2.1）。登録と、オーナーが退会した発信者の取り戻し。
class CreatorRegisterViewModel extends Notifier<CreatorRegisterState> {
  @override
  CreatorRegisterState build() {
    final draft = ref.watch(registrationDraftProvider);
    final pending =
        ref.watch(pendingAccountLinksProvider).value ??
        const <SnsService, CreatorAccount>{};
    return CreatorRegisterState(
      linkedServices: SnsService.ordered(pending.keys),
      profileDone: draft.profileDone,
      profileName: draft.profileName,
      profileId: draft.profileId,
      agreed: draft.agreed,
      reclaimable: ref.watch(reclaimableCreatorsProvider).value?.firstOrNull,
    );
  }

  void setAgreed(bool agreed) =>
      ref.read(registrationDraftProvider.notifier).setAgreed(agreed);

  /// アカウント（ログイン方法）があるか。なければ、登録・取り戻しはしない（機能仕様書 4.6.1・4.1.4）。
  Future<bool> hasLoginMethod() async =>
      (await ref.read(loginMethodsProvider.future)).isNotEmpty;

  /// 登録する。済んだら、オーナーの発信者・登録待ちの連携を読み直す。
  Future<RegisterResult> register() async {
    final draft = ref.read(registrationDraftProvider);
    final result = await guard(
      () => ref
          .read(creatorAdminRepositoryProvider)
          .register(
            id: draft.profileId,
            name: draft.profileName,
            bio: draft.profileBio,
            types: draft.profileTypes,
            avatar: draft.profileAvatar,
            cover: draft.profileCover,
          ),
      onError: RegisterResult.failed,
    );
    if (result.isRegistered && ref.mounted) {
      ref.invalidate(ownedCreatorProvider);
      ref.invalidate(pendingAccountLinksProvider);
    }
    return result;
  }

  /// オーナーが退会した発信者を取り戻す。済んだら、オーナーの発信者・登録待ちの連携・おすすめを読み直す。
  Future<ReclaimResult> reclaim(String creatorId) async {
    final result = await guard(
      () => ref.read(creatorAdminRepositoryProvider).reclaim(creatorId),
      onError: ReclaimResult.failed,
    );
    if (result == ReclaimResult.reclaimed && ref.mounted) {
      ref.invalidate(ownedCreatorProvider);
      ref.invalidate(pendingAccountLinksProvider);
      ref.invalidate(recommendedCreatorsProvider);
    }
    return result;
  }
}

final creatorRegisterViewModelProvider =
    NotifierProvider.autoDispose<
      CreatorRegisterViewModel,
      CreatorRegisterState
    >(CreatorRegisterViewModel.new);
