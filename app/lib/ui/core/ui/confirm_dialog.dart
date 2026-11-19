import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../themes/app_colors.dart';
import 'app_buttons.dart';

/// 確認のダイアログ。「キャンセル」と、[confirmLabel] の2つのボタンを出し、決定を押したら true を返す
/// （キャンセル・ダイアログの外を押して閉じたら false）。[title] が null なら、見出しを出さない。
/// [destructive] なら、決定のボタンを、消すなどの操作の色（[AppColors.live]）にする。
Future<bool> showConfirmDialog(
  BuildContext context, {
  String? title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        AppTextButton(
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppTextButton(
          label: confirmLabel,
          color: destructive ? context.colors.live : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return confirmed == true;
}
