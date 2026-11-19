import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_settings.dart';
import '../../../domain/models/creator_type.dart';
import '../../../domain/models/sns_profile.dart';
import '../../../domain/models/sns_service.dart';
import '../../../utils/text_limits.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../oshi/view_models/oshi_providers.dart';
import 'creator_admin_providers.dart';

/// プロフィールの編集の画面に出すもの。
class ProfileEditState {
  const ProfileEditState({
    required this.creator,
    required this.initialName,
    required this.initialBio,
    required this.initialTypes,
    required this.importSources,
    required this.types,
    this.initialAvatar,
    this.initialCover,
    this.initialId,
  });

  /// 編集する発信者。登録の手順のとき（まだ発信者がいない）は null。
  final Creator? creator;

  /// 入力欄の初期値。
  final String initialName;
  final String initialBio;
  final List<String> initialTypes;

  /// 登録の手順で、取り込んだ・選んだアイコン。
  final Uint8List? initialAvatar;

  /// 登録の手順で、選んだカバー。
  final Uint8List? initialCover;

  /// 登録の手順のときの ID。入力できる。登録のあとは null（変えられない）。
  final String? initialId;

  /// 下書きを取り込める SNS。確認済みの SNS（登録の手順からは、登録待ちの連携）。
  final List<SnsService> importSources;

  /// 発信者のタイプの一覧。読み込めなくても、ほかの項目は編集できる。
  final AsyncValue<List<CreatorType>> types;
}

/// プロフィールを保存できなかった理由。
enum ProfileSaveError {
  /// 名前が空か、100文字を超えている。
  nameInvalid,

  /// ID が、英小文字・数字・_・- の1〜40文字でない。
  idInvalid,

  /// 保存に失敗した。
  failed,
}

/// プロフィールの編集（画面定義書 2.3.1）。名前・アイコン・カバー・プロフィール文・タイプを編集する。
/// [creatorId] が null のとき（発信者として登録の手順から開いた）は、入力を登録の下書きに持つ。
class ProfileEditViewModel extends AsyncNotifier<ProfileEditState> {
  ProfileEditViewModel(this.creatorId);

  /// 登録の手順から開いたときは null（まだ発信者がいない）。
  final String? creatorId;

  /// 名前の上限（見た目の1文字（書記素）で数えた文字数）。
  static const maxNameLength = 100;

  /// 取り込んだ名前を、見た目の1文字（書記素）で [maxNameLength] 文字に収まるように切る（機能仕様書 4.6.4）。
  /// 入力欄・保存のときと同じ数え方で収め、絵文字の途中では切らない。
  static String clampName(String name) => clampGraphemes(name, maxNameLength);

  @override
  Future<ProfileEditState> build() async {
    final types = ref.watch(creatorTypesProvider);
    final id = creatorId;
    if (id == null) {
      final draft = ref.watch(registrationDraftProvider);
      // 登録待ちの連携は、読めるまで待たずに出す（連携がなくても入力できる）。
      final pending =
          ref.watch(pendingAccountLinksProvider).value ??
          const <SnsService, CreatorAccount>{};
      return ProfileEditState(
        creator: null,
        initialName: draft.profileName,
        initialBio: draft.profileBio,
        initialAvatar: draft.profileAvatar,
        initialCover: draft.profileCover,
        initialTypes: draft.profileTypes,
        initialId: draft.profileId,
        // X は、X連携プランに加入している発信者だけ。登録の途中は、まだ加入していないので出さない。
        importSources: SnsService.ordered(
          pending.keys.where((s) => s != SnsService.x),
        ),
        types: types,
      );
    }
    final data = await ref.watch(creatorAdminDataProvider(id).future);
    return ProfileEditState(
      creator: data.creator,
      initialName: data.creator.name,
      initialBio: data.creator.bio,
      initialTypes: data.creator.types,
      // 取り込めるのは、確認済みの SNS だけ。X は、X連携プランに加入している発信者だけ（API に費用がかかるため）。
      importSources: [
        for (final service in data.linkedServices)
          if (data.isVerified(service) &&
              (service != SnsService.x || data.creator.xOption))
            service,
      ],
      types: types,
    );
  }

  /// 読み込めなかったときに、読み直す。
  void retry() {
    final id = creatorId;
    if (id == null) {
      reloadFrom(ref, [authSessionProvider, pendingAccountLinksProvider]);
    } else {
      retryCreatorAdmin(ref, id);
    }
  }

  /// タイプの一覧を読み込めなかったときに、読み直す。
  void retryTypes() =>
      reloadFrom(ref, [authSessionProvider, creatorTypesProvider]);

  /// 端末の写真から1枚を選び、長辺 [maxSide] に縮めて返す。選ばなければ null。
  Future<Uint8List?> pickImage({required double maxSide}) =>
      ref.read(imagePickerServiceProvider).pickImage(maxSide: maxSide);

  /// [service] から、プロフィールの下書きを取る。失敗したら [draft] が null。
  /// 回数の上限を超えたときは、[limited] が true。
  Future<({SnsProfileDraft? draft, bool limited})> importProfile(
    SnsService service,
  ) async {
    try {
      final draft = await ref
          .read(creatorAdminRepositoryProvider)
          .importProfile(creatorId, service);
      return (draft: draft, limited: false);
    } on AppException catch (e) {
      return (draft: null, limited: e.kind == AppErrorKind.rateLimited);
    } catch (_) {
      return (draft: null, limited: false);
    }
  }

  /// 入力を確かめて、保存する。保存できたら null、できなければ理由。
  /// 登録の手順では、登録の下書きに入れるだけ（[id] を受け取る。画像は登録のあとにアップロードする）。
  /// 登録のあとは、画像を先にアップロードして保存する。
  Future<ProfileSaveError?> save({
    required String name,
    required String bio,
    required List<String> types,
    Uint8List? avatar,
    Uint8List? cover,
    String? id,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || graphemeLength(trimmedName) > maxNameLength) {
      return ProfileSaveError.nameInvalid;
    }
    final creatorId = this.creatorId;
    if (creatorId == null) {
      final profileId = (id ?? '').trim();
      if (!creatorIdPattern.hasMatch(profileId)) {
        return ProfileSaveError.idInvalid;
      }
      final draft = ref.read(registrationDraftProvider);
      ref
          .read(registrationDraftProvider.notifier)
          .setProfile(
            id: profileId,
            name: trimmedName,
            bio: bio.trim(),
            types: [...types],
            avatar: avatar ?? draft.profileAvatar,
            cover: cover ?? draft.profileCover,
          );
      return null;
    }
    final repo = ref.read(creatorAdminRepositoryProvider);
    try {
      final avatarUrl = avatar == null
          ? null
          : await repo.uploadAvatar(creatorId, avatar);
      final coverUrl = cover == null
          ? null
          : await repo.uploadCover(creatorId, cover);
      await repo.updateProfile(
        creatorId,
        name: trimmedName,
        bio: bio.trim(),
        types: [...types],
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );
    } catch (_) {
      return ProfileSaveError.failed;
    }
    if (ref.mounted) refreshCreatorAdmin(ref, creatorId);
    return null;
  }
}

final profileEditViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ProfileEditViewModel, ProfileEditState, String?>(
      ProfileEditViewModel.new,
    );
