import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/share_link.dart';
import '../../core/ui/qr_code_view.dart';
import '../../core/view_models/loading_overlay_provider.dart';

/// リンク（共有のリンク・アプリで開くのリンク）で開く予定の発信者 ID（届ける・広める仕様書 4.3.3）。
/// アプリの土台（`app.dart`）が起動したときから監視し続け、初回起動の画面にいるあいだに受けたリンクも残す。
/// ホームの枠が監視し、発信者ページを開いて、[consume] で消す。あとから受けたリンクで上書きする。
class PendingCreatorLink extends Notifier<String?> {
  @override
  String? build() {
    final sub = ref.watch(appLinkServiceProvider).links.listen(
      (uri) {
        final id = ShareLink.creatorIdFrom(uri);
        if (id != null) state = id;
      },
      // 読めないリンクは無視し、ふつうの起動のまま。
      onError: (Object e) => debugPrint('リンクを受け取れない: $e'),
    );
    ref.onDispose(sub.cancel);
    return null;
  }

  /// [creatorId] を開く予定にする（初回起動の引き継ぎ）。
  void set(String creatorId) => state = creatorId;

  /// 扱い終えた。
  void consume() => state = null;
}

final pendingCreatorLinkProvider =
    NotifierProvider<PendingCreatorLink, String?>(PendingCreatorLink.new);

/// リンクの共有の結果。
enum ShareLinkOutcome {
  /// 共有シートを開いた（共有したかは分からない）。
  opened,

  /// 発信者がファンに見せない状態なので、共有しなかった。
  unavailable,

  /// 確かめられなかった・共有シートを開けなかった。
  failed,
}

/// 発信者の共有のリンクを、OS の共有シートで共有する（届ける・広める仕様書 4.3.2）。
/// 発信者のチームメンバーも、ファンも使う。どこから共有しても、リンクは追星に誘う用（`?invite=1`。4.3.6）にする（2026-11-19 本人）。
class ShareLinkViewModel extends Notifier<void> {
  @override
  void build() {}

  /// [creatorId] の誘う用のリンクを、[message]（リンクを受けて、共有する文を返す）で共有シートに渡す。
  /// 先に、ファンに見せる状態かをサーバーで確かめる。
  Future<ShareLinkOutcome> share(
    String creatorId, {
    required String Function(Uri link) message,
    Rect? origin,
  }) async {
    try {
      // 確かめるあいだだけ、読み込み中を出す（共有シートが開いているあいだは出さない）。
      final shareable = await ref
          .read(loadingOverlayProvider.notifier)
          .run(
            () => ref.read(creatorRepositoryProvider).isShareable(creatorId),
          );
      if (!shareable) return ShareLinkOutcome.unavailable;
      await ref
          .read(shareSheetServiceProvider)
          .shareText(
            message(ShareLink.forCreator(creatorId, invite: true)),
            origin: origin,
          );
      return ShareLinkOutcome.opened;
    } catch (e) {
      debugPrint('リンクを共有できない: $e');
      return ShareLinkOutcome.failed;
    }
  }

  /// [creatorId] の誘う用のリンクの QR を、画像（PNG）にして共有シートに渡す（4.3.5。「画像を保存」で写真に保存できる）。
  Future<ShareLinkOutcome> shareQrImage(
    String creatorId, {
    Rect? origin,
  }) async {
    try {
      final png = await ref
          .read(loadingOverlayProvider.notifier)
          .run(
            () =>
                qrPng(ShareLink.forCreator(creatorId, invite: true).toString()),
          );
      await ref
          .read(shareSheetServiceProvider)
          .shareImage(
            png,
            fileName: 'oiboshi-$creatorId-qr.png',
            origin: origin,
          );
      return ShareLinkOutcome.opened;
    } catch (e) {
      debugPrint('QR の画像を共有できない: $e');
      return ShareLinkOutcome.failed;
    }
  }

  /// リンクから開く発信者が、開いてよい（ファンに見せる状態）か。確かめられなければ、開いてみる（発信者ページが失敗を出す）。
  Future<bool> canOpen(String creatorId) async {
    try {
      return await ref.read(creatorRepositoryProvider).isShareable(creatorId);
    } catch (e) {
      debugPrint('リンクの発信者を確かめられない: $e');
      return true;
    }
  }
}

final shareLinkViewModelProvider = NotifierProvider<ShareLinkViewModel, void>(
  ShareLinkViewModel.new,
);

/// 「リンクを共有」の画面に出す発信者と、共有できる（ファンに見せる状態）か。
final shareTargetProvider = FutureProvider.autoDispose
    .family<({Creator creator, bool shareable}), String>((
      ref,
      creatorId,
    ) async {
      final repo = ref.read(creatorRepositoryProvider);
      final creator = await repo.fetchById(creatorId);
      if (creator == null) throw StateError('発信者が見つからない: $creatorId');
      return (creator: creator, shareable: await repo.isShareable(creatorId));
    });

/// QR の画像の一辺（ピクセル）。印刷や配信画面に置いても粗くならない大きさ。
const qrImageSize = 1024;

/// [data] の QR を、白地に黒の PNG にする（余白つき）。
Future<Uint8List> qrPng(String data) async {
  final recorder = ui.PictureRecorder();
  paintQrCode(
    ui.Canvas(recorder),
    const ui.Rect.fromLTWH(0, 0, qrImageSize + 0.0, qrImageSize + 0.0),
    data,
    color: const ui.Color(0xFF000000),
    background: const ui.Color(0xFFFFFFFF),
  );
  final image = await recorder.endRecording().toImage(qrImageSize, qrImageSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}
