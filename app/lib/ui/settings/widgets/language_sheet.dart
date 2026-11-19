import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/user_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/choice_row.dart';
import '../../core/ui/l10n_labels.dart';
import '../view_models/settings_viewmodel.dart';

/// 言語（シート）（画面定義書 2.1.8）。表示言語を選ぶ。
Future<void> showLanguageSheet(BuildContext context) =>
    showAppSheet(context, builder: (_) => const _LanguageSheet());

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(
      settingsViewModelProvider.select((s) => s.language),
    );
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.settingsLanguage),
          for (final language in AppLanguage.values)
            ChoiceRow(
              label: l10n.appLanguage(language),
              selected: language == current,
              horizontalPadding: 20,
              fontSize: 16,
              boldWhenSelected: false,
              onTap: () {
                ref
                    .read(settingsViewModelProvider.notifier)
                    .setLanguage(language);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
