import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/open_url.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../view_models/settings_providers.dart';

/// お問い合わせ（画面定義書（設定・発信者向け）2.1.1・2.1.9）。メールアプリを、[draft] の下書きで開く。
/// メールアプリが使えないときは、ユーザー ID をコピーできる画面（ダイアログ）と、宛先を出す。
/// 設定と、発信者メニュー（停止中の案内）から使う。
Future<void> openContactMail(
  BuildContext context, {
  required ContactDraft draft,
  required String? userId,
}) async {
  final opened = draft.to.isNotEmpty && await openUrl(draft.mailto);
  if (opened || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => _ContactFallbackDialog(draft: draft, userId: userId),
  );
}

/// メールアプリが使えないときの画面。ユーザー ID をコピーできる。
/// サインインしていなければ、メールの本文と同じ文を出し、コピーのボタンは出さない。
class _ContactFallbackDialog extends StatelessWidget {
  const _ContactFallbackDialog({required this.draft, required this.userId});

  final ContactDraft draft;

  /// いまのユーザー ID。サインインしていなければ null。
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final userId = this.userId;
    return AlertDialog(
      title: Text(l10n.commonContact),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.to.isEmpty
                ? l10n.settingsContactAddressPreparing
                : l10n.settingsContactByEmail,
            style: context.textStyles.bodySecondary,
          ),
          if (draft.to.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              draft.to,
              style: TextStyle(fontSize: 15, color: c.textPrimary),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.settingsUserId, style: context.textStyles.hint),
          const SizedBox(height: 4),
          if (userId == null)
            Text(
              l10n.commonContactNotSignedIn,
              style: TextStyle(fontSize: 13, color: c.textPrimary),
            )
          else
            SelectableText(
              userId,
              style: TextStyle(fontSize: 13, color: c.textPrimary),
            ),
        ],
      ),
      actions: [
        if (userId != null)
          AppTextButton(
            label: l10n.settingsCopyUserId,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: userId));
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        AppTextButton(
          label: l10n.commonClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
