import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/open_url.dart';
import 'app_snack_bar.dart';

/// ストアのサブスクの管理の画面（[url]）を開く。開けなければ、スナックバー「ページを開けませんでした」を出す。
/// プランの「解約する」（画面定義書 2.3.6）と、退会の「サブスクの管理を開く」（2.1.4）で使う。
/// URL は、各画面の ViewModel から受け取る。
Future<void> openSubscriptionManagement(BuildContext context, Uri url) async {
  if (await openUrl(url) || !context.mounted) return;
  showAppSnackBar(context, AppLocalizations.of(context)!.commonPageOpenFailed);
}
