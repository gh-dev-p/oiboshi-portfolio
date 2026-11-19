import 'package:flutter/material.dart';

import '../../../domain/models/event_draft.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_sheet.dart';

/// 公演を選ぶ（画面定義書（設定・発信者向け）2.3.14）。読み取ったページに公演が複数あるとき、登録する公演を1つ選ぶ
/// （1つのイベントは、1つの公演）。公演が1つならそれを、なければ null を、シートを出さずに返す。選ばずに閉じたら null。
Future<PerformanceDraft?> pickPerformance(
  BuildContext context,
  List<PerformanceDraft> performances,
) async {
  if (performances.length <= 1) return performances.firstOrNull;
  return showAppSheet<PerformanceDraft>(
    context,
    builder: (_) => _PerformancePickerSheet(performances: performances),
  );
}

class _PerformancePickerSheet extends StatelessWidget {
  const _PerformancePickerSheet({required this.performances});

  final List<PerformanceDraft> performances;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    return AppSheet(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.performancePickerTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              l10n.performancePickerNote,
              style: context.textStyles.hint,
            ),
          ),
          for (final p in performances)
            InkWell(
              onTap: () => Navigator.of(context).pop(p),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        l10n.creatorAdminEventDate(
                          fullDate(p.date, l10n),
                          weekdayLabel(p.date, l10n),
                        ),
                        if (p.start case final s?) clockOfDay(s.hour, s.minute),
                      ].join(' '),
                      style: TextStyle(fontSize: 15, color: c.textPrimary),
                    ),
                    if (p.venue case final venue? when venue.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(venue, style: context.textStyles.caption),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
