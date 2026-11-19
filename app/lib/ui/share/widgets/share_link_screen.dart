import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/share_link.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/qr_code_view.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../core/ui/viewer_aware_header.dart';
import '../view_models/share_link_viewmodel.dart';

/// 共有の画面を開く（届ける・広める仕様書 4.3.2・4.3.6）。
/// 置き場は、発信者メニューの「追星に誘う」と、発信者ページのメニューの「リンクを共有」（自分の発信者ページ・ファンが開いた発信者ページ）。
/// [asCreator] なら、発信者の側から誘う文（「追星に誘う」の画面）。ファンなら、ファンの側の文。リンクはどちらも誘う用。
Future<void> openShareLinkScreen(
  BuildContext context,
  String creatorId, {
  bool asCreator = false,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ShareLinkScreen(creatorId: creatorId, asCreator: asCreator),
  ),
);

/// 「リンクを共有」・「追星に誘う」の画面（画面定義書（ファン向け）2.4.4、届ける・広める仕様書 4.3.2・4.3.5・4.3.6）。
/// 発信者の名前・アイコン、誘う用のリンク（`?invite=1`）の QR、リンク（押すと写す）と、共有シートへのボタンを出す。
/// どこから共有しても、リンクと QR は誘う用にする（2026-11-19 本人）。
/// 見た目は、今の画面（プラン・発信者メニュー）の部品にそろえた仮の決め（Figma は飛ばした）。
/// [asCreator] なら「追星に誘う」（発信者・チームの側の文と注記）。そうでなければ「リンクを共有」（ファンの側の文と注記）。
class ShareLinkScreen extends ConsumerWidget {
  const ShareLinkScreen({
    super.key,
    required this.creatorId,
    this.asCreator = false,
  });

  final String creatorId;
  final bool asCreator;

  /// QR の一辺（画面の上）。
  static const qrSize = 200.0;

  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
  }

  Future<void> _shareLink(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await ref
        .read(shareLinkViewModelProvider.notifier)
        .share(
          creatorId,
          message: (link) => asCreator
              ? l10n.shareInviteMessage(link.toString())
              : l10n.shareLinkMessage(name, link.toString()),
          origin: _originOf(context),
        );
    if (!context.mounted) return;
    _showOutcome(context, outcome);
  }

  Future<void> _shareQr(BuildContext context, WidgetRef ref) async {
    final outcome = await ref
        .read(shareLinkViewModelProvider.notifier)
        .shareQrImage(creatorId, origin: _originOf(context));
    if (!context.mounted) return;
    _showOutcome(context, outcome);
  }

  void _showOutcome(BuildContext context, ShareLinkOutcome outcome) {
    final l10n = AppLocalizations.of(context)!;
    switch (outcome) {
      case ShareLinkOutcome.opened:
        break;
      case ShareLinkOutcome.unavailable:
        showAppSnackBar(context, l10n.shareLinkUnavailable);
      case ShareLinkOutcome.failed:
        showAppSnackBar(context, l10n.shareLinkFailed);
    }
  }

  Future<void> _copy(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    showAppSnackBar(context, AppLocalizations.of(context)!.shareLinkCopied);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(shareTargetProvider(creatorId));
    return HeaderScaffold(
      appBar: ScreenAppBar(
        title: asCreator ? l10n.shareInviteTitle : l10n.shareLinkTitle,
      ),
      body: state.when(
        loading: () => const _ShareSkeleton(),
        error: (_, _) => StateView.error(
          onRetry: () => ref.invalidate(shareTargetProvider(creatorId)),
        ),
        data: (target) {
          if (!target.shareable) {
            return StateView(
              icon: Icons.link_off,
              title: l10n.shareLinkUnavailableTitle,
              message: l10n.shareLinkUnavailable,
            );
          }
          final creator = target.creator;
          final link = ShareLink.forCreator(
            creator.id,
            invite: true,
          ).toString();
          return ListView(
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: [
              _ShareCard(
                avatarUrl: creator.avatarUrl,
                name: creator.name,
                id: creator.id,
                link: link,
                onCopy: () => _copy(context, link),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Builder(
                  builder: (context) => PrimaryButton(
                    label: l10n.shareLinkShareButton,
                    onPressed: () => _shareLink(context, ref, creator.name),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Builder(
                  builder: (context) => TonalButton(
                    label: l10n.shareLinkSaveQr,
                    onPressed: () => _shareQr(context, ref),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  asCreator ? l10n.shareInviteNote : l10n.shareLinkNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 18 / 12,
                    color: context.colors.textTertiary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 名前・アイコン・QR・リンクをまとめた面。
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.avatarUrl,
    required this.name,
    required this.id,
    required this.link,
    required this.onCopy,
  });

  final String? avatarUrl;
  final String name;
  final String id;
  final String link;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return SurfacePanel(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          OshiAvatar(avatarUrl: avatarUrl, size: 72),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text('@$id', style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const SizedBox(height: 20),
          // QR は、ダークモードでも読み取れるよう、白地に黒で出す。
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: QrCodeView(
              data: link,
              size: ShareLinkScreen.qrSize,
              color: Colors.black,
              background: Colors.white,
              semanticLabel: l10n.shareLinkQrLabel,
            ),
          ),
          const SizedBox(height: 16),
          ShareLinkCopyRow(link: link, onCopy: onCopy),
        ],
      ),
    );
  }
}

/// リンクを1行で出し、押すと写す行（「リンクを共有」の画面）。
class ShareLinkCopyRow extends StatelessWidget {
  const ShareLinkCopyRow({super.key, required this.link, required this.onCopy});

  final String link;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: OneLineText(
                  link,
                  style: TextStyle(fontSize: 13, color: c.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.copy,
                size: 18,
                color: c.textSecondary,
                semanticLabel: AppLocalizations.of(context)!.shareLinkCopy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareSkeleton extends StatelessWidget {
  const _ShareSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: SkeletonBox(height: 400, radius: 20),
  );
}
