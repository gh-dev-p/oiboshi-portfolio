import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/share_link.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../oshi/view_models/oshi_providers.dart';
import '../../settings/view_models/settings_providers.dart';

/// ウェルカム（画面定義書 2.1.1）の操作。
class WelcomeViewModel extends Notifier<void> {
  @override
  void build() {}

  /// 「はじめる」。匿名でサインインする。失敗しても次へ進み、各画面が「読み込めない」を出す。
  Future<void> start() async {
    try {
      await ref.read(authSessionProvider.future);
    } catch (_) {
      // 推しを選ぶで「読み込めない」を出し、「もう一度試す」でサインインし直す。
    }
  }

  /// 入れたあとの引き継ぎ（届ける・広める仕様書 4.3.4）。共有のページで「App Store で入れる」を押した人の
  /// クリップボードにある共有のリンクから、発信者 ID と、誘う用のリンク（4.3.6）かを返す。引き継がないなら null。
  ///
  /// - 端末で1回だけ確かめる（確かめた印を、読む前に残す。iOS の確認を二度出さないため）。
  /// - 中身を読まずに URL らしいかを確かめ（確認は出ない）、らしいときだけ読む（iOS の「ペーストを許可」の確認が出る）。
  /// - 共有のリンクの形で、ファンに見せる発信者のときだけ返す。ほかの URL は使わず、残さない。
  Future<({String creatorId, bool invite})?> takeClipboardLink() async {
    final settings = ref.read(settingsRepositoryProvider);
    if (settings.clipboardLinkChecked) return null;
    try {
      await settings.setClipboardLinkChecked();
      final clipboard = ref.read(clipboardServiceProvider);
      if (!await clipboard.hasProbableUrl()) return null;
      final link = ShareLink.fromText(await clipboard.readText());
      if (link == null) return null;
      final shareable = await ref
          .read(creatorRepositoryProvider)
          .isShareable(link.creatorId);
      return shareable ? link : null;
    } catch (e) {
      // 読めない・確かめられないときは、ふつうの初回起動を続ける。
      debugPrint('クリップボードから引き継げない: $e');
      return null;
    }
  }

  /// 誘う用のリンク（4.3.6）から入れた人の、引き継いだ発信者をフォローする。フォローしたら、発信者の名前を返す
  /// （知らせに使う。読めなければ ID）。もうフォローしている・できなかったら null（ページはそのまま出す。ファンが押せる）。
  Future<String?> followInvited(String creatorId) async {
    try {
      final follows = await ref.read(followsProvider.future);
      if (follows.any((f) => f.creatorId == creatorId)) return null;
    } catch (_) {
      // 読めなければ、フォローを試す。
    }
    if (!await ref.read(followActionsProvider.notifier).toggle(creatorId)) {
      return null;
    }
    try {
      return (await ref.read(creatorRepositoryProvider).fetchById(creatorId))
              ?.name ??
          creatorId;
    } catch (_) {
      return creatorId;
    }
  }

  /// 「発信者の方はこちら」。サインインして、アカウント（ログイン方法）がないかを返す。
  /// ないなら、登録の前に、アカウント作成／ログイン（シート）を出す（機能仕様書 4.6.1）。
  Future<bool> needsAccount() async {
    await start();
    try {
      return (await ref.read(loginMethodsProvider.future)).isEmpty;
    } catch (_) {
      return ref.read(authRepositoryProvider).isAnonymous;
    }
  }

  /// 自分がオーナーの発信者がいるか（使ったことのあるアカウントでログインしたとき）。読めなければ false。
  Future<bool> ownsCreator() async {
    try {
      return await ref
              .read(creatorAdminRepositoryProvider)
              .fetchOwnedCreator() !=
          null;
    } catch (_) {
      return false;
    }
  }
}

final welcomeViewModelProvider = NotifierProvider<WelcomeViewModel, void>(
  WelcomeViewModel.new,
);
