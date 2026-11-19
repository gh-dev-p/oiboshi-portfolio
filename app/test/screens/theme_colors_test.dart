import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/l10n/app_localizations.dart';
import 'package:oiboshi/ui/core/themes/app_colors.dart';
import 'package:oiboshi/ui/core/themes/app_theme.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/schedule/view_models/month_calendar_viewmodel.dart';
import 'package:oiboshi/ui/schedule/widgets/month_grid.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

/// 文字の見やすさの比（WCAG）。大きな文字とアイコンの目安は 3、ふつうの文字は 4.5。
double contrast(Color a, Color b) {
  final (hi, lo) = a.computeLuminance() > b.computeLuminance()
      ? (a, b)
      : (b, a);
  return (hi.computeLuminance() + 0.05) / (lo.computeLuminance() + 0.05);
}

/// 直書きの色が画面モードで変わらなかった箇所を、ライトとダークの両方で確かめる。
void main() {
  setUpScreenTests();

  for (final (name, theme, c) in [
    ('ライト', AppTheme.light, AppColors.light),
    ('ダーク', AppTheme.dark, AppColors.dark),
  ]) {
    testWidgets('$name：丸いアイコンボタンのアイコンがテーマの色になり、読める', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: CircleIconButton(icon: Icons.add, onPressed: () {}),
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.add));
      expect(icon.color, c.textSecondary);
      expect(contrast(icon.color!, c.avatarFill), greaterThan(3));
    });

    testWidgets('$name：次の予定のカードの見出しと矢印がテーマの色になり、読める', (tester) async {
      data.schedules.add(
        sampleSchedule(
          's1',
          'お昼の配信',
          DateTime.now().add(const Duration(hours: 3)),
          service: SnsService.youtube,
        ),
      );
      await tester.pumpWidget(
        await testApp(
          data,
          const CreatorScreen(creatorId: 'minato'),
          theme: theme,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final header = tester.widget<Text>(find.textContaining('次の予定'));
      final chevron = tester.widget<Icon>(
        find.byIcon(Icons.chevron_right).first,
      );
      expect(header.style?.color, c.textSecondary);
      expect(chevron.color, c.textSecondary);
      expect(contrast(c.textSecondary, c.surface), greaterThan(4.5));
      await unmount(tester);
    });

    testWidgets('$name：月のカレンダーの点がテーマの色になる', (tester) async {
      final day = DateTime(2026, 11, 10);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: MonthGrid(
              month: DateTime(2026, 11),
              selected: DateTime(2026, 11, 20),
              data: MonthData(
                schedules: [
                  sampleSchedule(
                    'live',
                    '配信',
                    day,
                    service: SnsService.youtube,
                  ),
                  sampleSchedule('event', 'イベント', day),
                ],
                posts: [samplePost(postedAt: day)],
              ),
              onSelect: (_) {},
            ),
          ),
        ),
      );
      final dots = tester
          .widgetList<Container>(find.byType(Container))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.shape == BoxShape.circle && d.color != null)
          .map((d) => d.color)
          .toSet();
      expect(dots, containsAll([c.now, c.accentGreen, c.live]));
      // 日の点は、配信・投稿・イベントの順に並ぶ。
      final dayDots = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(InkWell),
              matching: find.byType(Container),
            ),
          )
          .where(
            (w) =>
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
                (w.decoration! as BoxDecoration).color != null &&
                (w.decoration! as BoxDecoration).color != c.textPrimary,
          )
          .map((w) => (w.decoration! as BoxDecoration).color)
          .toList();
      expect(dayDots, [c.now, c.accentGreen, c.live]);
      // 凡例を出す。
      final legend = find.byKey(const ValueKey('month-dot-legend'));
      for (final label in ['配信', '投稿', 'イベント']) {
        expect(
          find.descendant(of: legend, matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(contrast(c.accentGreen, c.background), greaterThan(3));
      expect(contrast(c.now, c.background), greaterThan(3));
      expect(contrast(c.live, c.background), greaterThan(3));
    });
  }
}
