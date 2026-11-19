import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/ui/labeled_field.dart';
import '../../core/ui/settings_row.dart';

/// 発信者向けの入力の画面（イベントの登録など）で使う部品。

/// 押して選ぶ入力欄（日付・時刻）。
class PickerBox extends StatelessWidget {
  const PickerBox({
    super.key,
    required this.text,
    required this.placeholder,
    required this.onTap,
    this.icon,
    this.onClear,
  });

  final String? text;
  final String placeholder;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.fieldFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text ?? placeholder,
                  style: TextStyle(
                    fontSize: 15,
                    color: text == null ? c.textTertiary : c.textPrimary,
                  ),
                ),
              ),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close, size: 18, color: c.textTertiary),
                )
              else if (icon != null)
                Icon(icon, size: 20, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// ラベルと補足と、右のスイッチの行。
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 15, color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(sub, style: context.textStyles.hint),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// 開始と終了の時刻の入力欄（横に2つ並べる）。終了は空にでき、空ならその日の終わりまで表示することを、欄の下に出す。
/// 時計を開いたときの初めの時刻は、入っていなければ [defaultStart]・[defaultEnd]（終了は、開始が入っていれば開始）。
class StartEndTimeRow extends StatelessWidget {
  const StartEndTimeRow({
    super.key,
    required this.start,
    required this.end,
    required this.startError,
    required this.defaultStart,
    required this.defaultEnd,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onEndCleared,
  });

  final TimeOfDay? start;
  final TimeOfDay? end;

  /// 開始の欄に、入れていない案内を出すか。
  final bool startError;
  final TimeOfDay defaultStart;
  final TimeOfDay defaultEnd;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;
  final VoidCallback onEndCleared;

  static String _format(TimeOfDay t) => clockOfDay(t.hour, t.minute);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final start = this.start;
    final end = this.end;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LabeledField(
              label: l10n.creatorAdminEventFieldStart,
              required: true,
              error: startError,
              padding: EdgeInsets.zero,
              child: PickerBox(
                text: start == null ? null : _format(start),
                placeholder: l10n.commonNotSet,
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: start ?? defaultStart,
                  );
                  if (t != null) onStartChanged(t);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LabeledField(
              label: l10n.creatorAdminEventFieldEnd,
              padding: EdgeInsets.zero,
              child: PickerBox(
                text: end == null ? null : _format(end),
                placeholder: l10n.commonNotSet,
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: end ?? start ?? defaultEnd,
                  );
                  if (t != null) onEndChanged(t);
                },
                onClear: end == null ? null : onEndCleared,
              ),
            ),
          ),
        ],
      ),
    );
    // 終了を空にしたときの表示を、欄の下に知らせる（2026-11-19 本人）。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.creatorAdminEventEndNote,
            style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
