import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator_link.dart';
import '../../../domain/models/report.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/open_url.dart';
import '../../../utils/text_limits.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/sns_style.dart';
import '../../report/widgets/report_sheet.dart';
import '../view_models/creator_links_provider.dart';

/// 発信者ページのリンク集（画面定義書（ファン向け）2.4.1、届ける・広める仕様書 4.6.2）。
/// つないだ SNS の下に、リンクを1件1つの横いっぱいのボタンで、並び順に縦に並べる。
/// つないだ SNS のアカウントのページを指すリンク（[snsAccounts]）は出さない。SNS ごとのフォロワー数の所から開けるため（2026-11-19 本人）。
/// 出すリンクがない・読めないときは、何も出さない。
class CreatorLinkButtons extends ConsumerWidget {
  const CreatorLinkButtons({
    super.key,
    required this.creatorId,
    required this.canReport,
    this.snsAccounts = const {},
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  });

  final String creatorId;

  /// 確かめのダイアログに「このリンクを通報する」を出すか。自分がオーナーの発信者では出さない。
  final bool canReport;

  /// 発信者の確認済みの SNS のアカウント（[Creator.accounts]）。
  final Map<SnsService, String> snsAccounts;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref
        .watch(creatorLinksProvider(creatorId))
        .value
        ?.where((l) => !CreatorLinkRules.isSnsProfileLink(snsAccounts, l.url))
        .toList();
    if (links == null || links.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final link in links)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LinkButton(
                link: link,
                onTap: () => confirmAndOpenCreatorLink(
                  context,
                  ref,
                  link,
                  canReport: canReport,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.link, required this.onTap});

  final CreatorLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      key: ValueKey('creator-link-button-${link.id}'),
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          // 左に、行き先のサービスの公式アイコン（分からない行き先は、ふつうのリンクの印）。題名は真ん中（4.6.7）。
          child: Row(
            children: [
              // 24：Spotify の決まりの最小（21px）を満たす。すき間 12：アイコンの高さの半分の余白（Spotify）。
              LinkServiceIcon(url: link.url, size: 24, color: c.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: OneLineText(
                  link.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              // 題名を真ん中に置くため、右にもアイコンと同じ幅を空ける。
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }
}

/// 何を押したか（確かめのダイアログ）。
enum _LinkAction { open, report }

/// リンク集のリンクを、行き先のドメインを出して確かめてから開く（画面定義書（ファン向け）2.4.1）。
/// 「開く」で外部のブラウザで開き、押された数を送る（オーナー自身の分は、サーバーが数えない）。
/// [canReport] なら「このリンクを通報する」を置き、押すと通報のシートを出す。
/// `https://` で始まらないリンクは開かず、「ページを開けませんでした」と出す。
Future<void> confirmAndOpenCreatorLink(
  BuildContext context,
  WidgetRef ref,
  CreatorLink link, {
  required bool canReport,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = isHttpsUrl(link.url) ? Uri.tryParse(link.url) : null;
  if (uri == null) {
    showAppSnackBar(context, l10n.commonPageOpenFailed);
    return;
  }
  final repo = ref.read(creatorLinkRepositoryProvider);
  final action = await showDialog<_LinkAction>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.commonLinkConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(link.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(uri.host),
          if (canReport) ...[
            const SizedBox(height: 12),
            AppTextButton(
              key: const ValueKey('creator-link-report'),
              label: l10n.creatorLinkReport,
              fontSize: 13,
              color: context.colors.textSecondary,
              onPressed: () => Navigator.of(context).pop(_LinkAction.report),
            ),
          ],
        ],
      ),
      actions: [
        AppTextButton(
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppTextButton(
          key: const ValueKey('creator-link-open'),
          label: l10n.commonLinkConfirmOpen,
          onPressed: () => Navigator.of(context).pop(_LinkAction.open),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  switch (action) {
    case _LinkAction.open:
      // 数えるのは待たない（数えられなくても、リンクは開く）。
      repo.recordClick(link.id);
      if (!await openUrl(uri) && context.mounted) {
        showAppSnackBar(context, l10n.commonPageOpenFailed);
      }
    case _LinkAction.report:
      await showReportSheet(
        context,
        LinkReportTarget(linkId: link.id, title: link.title),
      );
    case null:
      break;
  }
}
