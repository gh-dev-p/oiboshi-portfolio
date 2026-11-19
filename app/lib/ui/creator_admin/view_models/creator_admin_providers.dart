import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_settings.dart';
import '../../../domain/models/sns_service.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../oshi/view_models/oshi_providers.dart';
import '../../schedule/view_models/schedule_providers.dart';
import '../../settings/view_models/settings_providers.dart';
import 'event_manage_viewmodel.dart';

/// 発信者向けの画面で共有する、自分の発信者と設定（機能仕様書 4.6）。
class CreatorAdminData {
  const CreatorAdminData({required this.creator, required this.displays});

  final Creator creator;
  final List<CreatorDisplay> displays;

  /// 連携済みの SNS（未確認を含む）。
  List<SnsService> get linkedServices =>
      SnsService.ordered(creator.linkedAccounts.keys);

  /// 確認済みの SNS。表示する内容を選べるのは、これだけ。
  bool isVerified(SnsService service) =>
      creator.linkedAccounts[service]?.verified ?? false;

  bool isDisplayEnabled(SnsService service, DisplayContent content) =>
      displays
          .where((d) => d.service == service && d.content == content)
          .firstOrNull
          ?.enabled ??
      true;
}

/// 指定の発信者（自分がオーナー）と、表示する内容の設定。
/// 発信者メニュー・プロフィールの編集・アカウント連携・表示する内容・イベントの登録で共有する。
/// 設定を書いたあとは、[refreshCreatorAdmin] で読み直す。
final creatorAdminDataProvider = FutureProvider.autoDispose
    .family<CreatorAdminData, String>(
      (ref, creatorId) => withSession(ref, (_) async {
        final repo = ref.watch(creatorAdminRepositoryProvider);
        final creator = await ref
            .watch(creatorRepositoryProvider)
            .fetchById(creatorId);
        if (creator == null) throw StateError('creator not found');
        return CreatorAdminData(
          creator: creator,
          displays: await repo.fetchDisplays(creatorId),
        );
      }),
    );

/// [creatorAdminDataProvider] をそのまま状態にする画面（発信者メニュー・表示する内容）の ViewModel の基底。
abstract class CreatorAdminDataNotifier
    extends AsyncNotifier<CreatorAdminData> {
  CreatorAdminDataNotifier(this.creatorId);

  final String creatorId;

  @override
  Future<CreatorAdminData> build() =>
      ref.watch(creatorAdminDataProvider(creatorId).future);
}

/// イベントを保存したあとに、予定を出している画面（イベントの管理・スケジュール・月のカレンダー・
/// 発信者ページ・ホーム）を読み直す。
void refreshCreatorSchedules(Ref ref, String creatorId) {
  ref.invalidate(eventManageViewModelProvider(creatorId));
  ref.invalidate(schedulesProvider);
}

/// 読み込めなかったときに、サインインから読み直す（「もう一度試す」）。
void retryCreatorAdmin(Ref ref, String creatorId) =>
    reloadFrom(ref, [authSessionProvider, creatorAdminDataProvider(creatorId)]);

/// 発信者の設定を書いたあとに、それを出している Provider（発信者向けの画面・設定・発信者ページ）を読み直す。
void refreshCreatorAdmin(Ref ref, String creatorId) {
  ref.invalidate(creatorAdminDataProvider(creatorId));
  ref.invalidate(ownedCreatorProvider);
  ref.invalidate(creatorProvider(creatorId));
}

/// 発信者として登録の手順1で連携した、登録待ちのアカウント（機能仕様書 4.6.1）。
/// 連携を変えたときは、`ref.invalidate` で読み直す。
final pendingAccountLinksProvider =
    FutureProvider.autoDispose<Map<SnsService, CreatorAccount>>(
      (ref) => withSession(
        ref,
        (_) => ref.watch(creatorAdminRepositoryProvider).fetchPendingLinks(),
      ),
    );

/// 取り戻せる発信者（機能仕様書 4.6.1.2）。登録待ちの連携から決まるので、連携が変わったら読み直す。
final reclaimableCreatorsProvider =
    FutureProvider.autoDispose<List<ReclaimableCreator>>((ref) async {
      await ref.watch(pendingAccountLinksProvider.future);
      return ref.read(creatorAdminRepositoryProvider).fetchReclaimable();
    });

/// 発信者として登録（画面定義書 2.2.1）の手順2（プロフィール）の入力と、規約への同意。
/// 登録の画面と、登録の手順から開いたプロフィールの編集で共有する。登録するまで、アプリの中だけで持つ。
class RegistrationDraft {
  const RegistrationDraft({
    this.profileId = '',
    this.profileName = '',
    this.profileBio = '',
    this.profileAvatar,
    this.profileCover,
    this.profileTypes = const [],
    this.agreed = false,
  });

  /// 発信者の ID。あとから変えられない。
  final String profileId;
  final String profileName;
  final String profileBio;

  /// アイコン（取り込んだもの・選んだもの）。登録したあとにアップロードする。
  final Uint8List? profileAvatar;

  /// カバー（選んだもの）。登録したあとにアップロードする。
  final Uint8List? profileCover;

  /// タイプ（任意、3つまで）。登録したあとに保存する。
  final List<String> profileTypes;
  final bool agreed;

  bool get profileDone =>
      profileName.trim().isNotEmpty && creatorIdPattern.hasMatch(profileId);

  RegistrationDraft copyWith({
    String? profileId,
    String? profileName,
    String? profileBio,
    Uint8List? profileAvatar,
    Uint8List? profileCover,
    List<String>? profileTypes,
    bool? agreed,
  }) => RegistrationDraft(
    profileId: profileId ?? this.profileId,
    profileName: profileName ?? this.profileName,
    profileBio: profileBio ?? this.profileBio,
    profileAvatar: profileAvatar ?? this.profileAvatar,
    profileCover: profileCover ?? this.profileCover,
    profileTypes: profileTypes ?? this.profileTypes,
    agreed: agreed ?? this.agreed,
  );
}

/// [RegistrationDraft] を持つ。登録の画面が開いている間だけ残る。
class RegistrationDraftNotifier extends Notifier<RegistrationDraft> {
  @override
  RegistrationDraft build() => const RegistrationDraft();

  void setProfile({
    required String id,
    required String name,
    required String bio,
    required List<String> types,
    Uint8List? avatar,
    Uint8List? cover,
  }) => state = state.copyWith(
    profileId: id,
    profileName: name,
    profileBio: bio,
    profileTypes: types,
    profileAvatar: avatar,
    profileCover: cover,
  );

  void setAgreed(bool agreed) => state = state.copyWith(agreed: agreed);
}

final registrationDraftProvider =
    NotifierProvider.autoDispose<RegistrationDraftNotifier, RegistrationDraft>(
      RegistrationDraftNotifier.new,
    );
