import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/user_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/settings_row.dart';
import '../view_models/settings_viewmodel.dart';

/// 画面モード（シート）（画面定義書 2.1.3）。ライト・ダークを選ぶ。
Future<void> showDisplayModeSheet(BuildContext context) =>
    showAppSheet(context, builder: (_) => const _DisplayModeSheet());

class _DisplayModeSheet extends ConsumerWidget {
  const _DisplayModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(
      settingsViewModelProvider.select((s) => s.displayMode),
    );
    final vm = ref.read(settingsViewModelProvider.notifier);
    final followSystem = mode == DisplayMode.system;
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final effectiveDark = followSystem
        ? platformDark
        : mode == DisplayMode.dark;
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.settingsDisplayMode),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
            child: Row(
              children: [
                for (final (label, dark) in [
                  (l10n.displayMode(DisplayMode.light), false),
                  (l10n.displayMode(DisplayMode.dark), true),
                ])
                  Expanded(
                    child: InkWell(
                      onTap: followSystem
                          ? null
                          : () => vm.setDisplayMode(
                              dark ? DisplayMode.dark : DisplayMode.light,
                            ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Opacity(
                          opacity: followSystem ? 0.6 : 1,
                          child: Column(
                            children: [
                              _Preview(dark: dark),
                              const SizedBox(height: 10),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                effectiveDark == dark
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 24,
                                color: effectiveDark == dark
                                    ? c.primary
                                    : c.unselected,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: c.divider, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.displayMode(DisplayMode.system),
                    style: TextStyle(fontSize: 16, color: c.textPrimary),
                  ),
                ),
                AppSwitch(
                  value: followSystem,
                  onChanged: (v) => vm.setDisplayMode(
                    v
                        ? DisplayMode.system
                        : (platformDark ? DisplayMode.dark : DisplayMode.light),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 画面の小さなプレビュー（76×152）。
class _Preview extends StatelessWidget {
  const _Preview({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    // 端末の設定によらず、ライト・ダークそれぞれの配色で描く。
    final p = dark ? AppColors.dark : AppColors.light;
    final bg = p.background;
    final block = p.surface;
    final bar = p.textPrimary.withValues(alpha: dark ? 0.3 : 0.18);
    Widget row(double y) => Positioned(
      left: 8,
      top: y,
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
    return Container(
      width: 76,
      height: 152,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.light.disabled),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 22,
            child: ColoredBox(color: block),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 28,
            height: 42,
            child: ColoredBox(color: block),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 76,
            height: 30,
            child: ColoredBox(color: block),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 18,
            child: ColoredBox(color: block),
          ),
          Positioned(
            left: 8,
            top: 9,
            child: Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: bar,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            left: 60,
            top: 7,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: p.accentNavy,
                shape: BoxShape.circle,
              ),
            ),
          ),
          row(36),
          row(48),
          row(60),
          row(84),
          row(96),
          for (final (x, a) in [(17.0, 0.9), (41.0, 0.3), (65.0, 0.3)])
            Positioned(
              left: x - 3,
              top: 140,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: p.textPrimary.withValues(alpha: a),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
