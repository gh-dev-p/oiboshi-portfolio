import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/view_models/settings_providers.dart';

import 'creator_admin_providers.dart';

/// 発信者メニュー（画面定義書 2.2.2）。連携の数と、いまのプランを出す。停止中なら、お問い合わせを案内する。
class CreatorMenuViewModel extends CreatorAdminDataNotifier {
  CreatorMenuViewModel(super.creatorId);

  /// お問い合わせの下書き（設定の「お問い合わせ」と同じ）。停止中の案内の「お問い合わせ」で使う。
  Future<ContactDraft> contactDraft({
    required String subject,
    required String Function(String userId, String version, String os) body,
    required String notSignedIn,
  }) => buildContactDraft(
    ref,
    subject: subject,
    body: body,
    notSignedIn: notSignedIn,
  );

  /// いまのユーザー ID。サインインしていなければ null。
  String? get userId => currentUserId(ref);

  /// 読み込めなかったときに、読み直す。
  void retry() => retryCreatorAdmin(ref, creatorId);
}

final creatorMenuViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CreatorMenuViewModel, CreatorAdminData, String>(
      CreatorMenuViewModel.new,
    );
