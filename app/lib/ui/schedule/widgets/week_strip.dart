import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';

/// 週ストリップ。1週間（日〜土）を横に並べる。
/// [compact] なら、曜日の行をなくし、日付の右に曜日を小さく並べて1段にする（固定ビューアを出している間。画面定義書（スケジュール）2.1.1）。
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.weekStart,
    required this.selected,
    required this.today,
    required this.onSelect,
    required this.onTodayReselected,
    this.compact = false,
  });

  final DateTime weekStart;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  /// 今日を選んでいるときに、今日をもう一度押した。
  final VoidCallback onTodayReselected;

  /// 曜日と日付を1段にまとめるか。
  final bool compact;

  /// 2段のときと、1段のときの高さ。1段では、曜日の行（文字と間）の分だけ低くする。
  static const height = 68.0;
  static const compactHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? compactHeight : height,
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 200) return;
          onSelect(selected.add(Duration(days: v < 0 ? 7 : -7)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = weekStart.add(Duration(days: i));
                      final isSelected = isSameDay(day, selected);
                      final isToday = isSameDay(day, today);
                      return InkWell(
                        onTap: () => isToday && isSelected
                            ? onTodayReselected()
                            : onSelect(day),
                        borderRadius: BorderRadius.circular(12),
                        child: compact
                            ? _compactDay(context, day, isSelected, isToday)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _weekday(context, day, isToday),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: _mark(
                                      context,
                                      isSelected,
                                      isToday,
                                      BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: _date(
                                      context,
                                      day,
                                      isSelected,
                                      isToday,
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
      ),
    );
  }

  /// 1段のときの1日。日付の右に曜日を小さく並べ、選んだ日・今日の印は横長の丸で付ける。
  Widget _compactDay(
    BuildContext context,
    DateTime day,
    bool isSelected,
    bool isToday,
  ) => Center(
    child: Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: _mark(context, isSelected, isToday, BoxShape.rectangle),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _date(context, day, isSelected, isToday),
            const SizedBox(width: 3),
            _weekday(context, day, isToday, onMark: isSelected),
          ],
        ),
      ),
    ),
  );

  /// 曜日（今日も、ほかの日と同じく曜日を出す。今日は、色と太さで分ける。2026-11-19 本人）。[onMark] なら、選んだ日の印の上に置く色にする。
  Widget _weekday(
    BuildContext context,
    DateTime day,
    bool isToday, {
    bool onMark = false,
  }) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Text(
      weekdayLabel(day, l10n),
      style: TextStyle(
        fontSize: compact ? 10 : 11,
        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        color: onMark
            ? (isToday ? c.onPrimary : c.background)
            : isToday
            ? c.primary
            : c.textTertiary,
      ),
    );
  }

  Widget _date(
    BuildContext context,
    DateTime day,
    bool isSelected,
    bool isToday,
  ) {
    final c = context.colors;
    return Text(
      '${day.day}',
      style: TextStyle(
        fontSize: 15,
        fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? (isToday ? c.onPrimary : c.background)
            : isToday
            ? c.primary
            : c.textPrimary,
      ),
    );
  }

  /// 選んだ日（塗り）と今日（枠）の印。
  BoxDecoration _mark(
    BuildContext context,
    bool isSelected,
    bool isToday,
    BoxShape shape,
  ) {
    final c = context.colors;
    return BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.rectangle
          ? BorderRadius.circular(16)
          : null,
      color: isSelected ? (isToday ? c.primary : c.textPrimary) : null,
      border: isToday && !isSelected
          ? Border.all(color: c.primary, width: 1.5)
          : null,
    );
  }
}
