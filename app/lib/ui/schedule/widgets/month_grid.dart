import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/month_calendar_viewmodel.dart';

/// 月の日の升目（日曜始まり）。日ごとに、配信・投稿・イベントの点を出し、押すとその日を選ぶ。
/// 点の色は、配信が青（[AppColors.now]）、投稿が緑（[AppColors.accentGreen]）、イベントが赤（[AppColors.live]）。
/// 升目の下に、3色の意味を示す小さな凡例を出す（2026-11-19 本人）。
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.data,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final MonthData data;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final weekdays = weekdayLabels(l10n);
    final first = month;
    final leading = first.weekday % 7; // 日曜始まり
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    Color weekdayColor(int col) => switch (col) {
      0 => c.live,
      6 => c.now,
      _ => c.textTertiary,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Text(
                      weekdays[(i + 6) % 7], // 日曜始まり
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: weekdayColor(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var row = 0; row < cells.length ~/ 7; row++)
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = cells[row * 7 + col];
                          if (day == null) return const SizedBox.shrink();
                          final isSelected = isSameDay(day, selected);
                          final dots = data.dotsOn(day);
                          final numberColor = isSelected
                              ? c.background
                              : switch (col) {
                                  0 => c.live,
                                  6 => c.now,
                                  _ => c.textPrimary,
                                };
                          return InkWell(
                            onTap: () => onSelect(day),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? c.textPrimary : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: numberColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  height: 5,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (final (i, color) in [
                                        if (dots.live) c.now,
                                        if (dots.post) c.accentGreen,
                                        if (dots.event) c.live,
                                      ].indexed)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: i == 0 ? 0 : 3,
                                          ),
                                          child: _Dot(
                                            isSelected ? c.unselected : color,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          // 3色の意味（控えめに、小さな点と薄い文字で）。
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              key: const ValueKey('month-dot-legend'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (i, (color, label)) in [
                  (c.now, l10n.commonLive),
                  (c.accentGreen, l10n.commonPost),
                  (c.live, l10n.commonEvent),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  _Dot(color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
