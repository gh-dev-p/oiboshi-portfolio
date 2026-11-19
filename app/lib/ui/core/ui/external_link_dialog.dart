import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/open_url.dart';
import '../../../utils/text_limits.dart';
import 'app_snack_bar.dart';
import 'confirm_dialog.dart';

/// イベントのリンクを、行き先のドメインを出して確かめてから開く（機能仕様書 4.5.3、画面定義書（スケジュール）2.1.5）。
/// `https://` で始まらないリンクは開かず、「ページを開けませんでした」と出す。
Future<void> confirmAndOpenEventLink(BuildContext context, String link) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = isHttpsUrl(link) ? Uri.tryParse(link) : null;
  if (uri == null) {
    showAppSnackBar(context, l10n.commonPageOpenFailed);
    return;
  }
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.commonLinkConfirmTitle,
    message: uri.host,
    confirmLabel: l10n.commonLinkConfirmOpen,
  );
  if (!confirmed || !context.mounted) return;
  if (!await openUrl(uri) && context.mounted) {
    showAppSnackBar(context, l10n.commonPageOpenFailed);
  }
}

/// ページ（規約・プライバシーポリシーなど）を開く。[url] が空か、開けなかったら、「ページを開けませんでした」と出す。
Future<void> openPageOrNotify(BuildContext context, String url) async {
  if (url.isEmpty || !await openUrl(Uri.parse(url))) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      AppLocalizations.of(context)!.commonPageOpenFailed,
    );
  }
}
