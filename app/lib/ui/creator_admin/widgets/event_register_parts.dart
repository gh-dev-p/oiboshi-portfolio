import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/labeled_field.dart';
import '../../core/ui/settings_row.dart';
import '../view_models/event_candidates_viewmodel.dart';
import '../view_models/event_register_viewmodel.dart';
import '../view_models/schedule_input.dart';
import 'form_parts.dart';

/// イベントの登録（画面定義書（設定・発信者向け）2.3.9）と、候補からの登録（2.3.11・2.3.13）で使う部品。

/// リンク1本の入力欄の状態。
class EventLinkField {
  EventLinkField({String url = '', this.promotion = false})
    : controller = TextEditingController(text: url);

  final TextEditingController controller;
  bool promotion;

  LinkInput get input => LinkInput(url: controller.text, promotion: promotion);
}

/// リンク1本のカード。URL の入力欄、広告（PR）のスイッチ、消すボタン。
class EventLinkCard extends StatelessWidget {
  const EventLinkCard({
    super.key,
    required this.field,
    required this.showErrors,
    required this.onChanged,
    required this.onRemove,
  });

  final EventLinkField field;
  final bool showErrors;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: SurfacePanel(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: field.controller,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'https://',
                        errorText: showErrors && field.input.invalid
                            ? l10n.creatorAdminEventLinkInvalid
                            : null,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.eventRegisterRemoveLink,
                    icon: Icon(Icons.close, size: 20, color: c.textTertiary),
                    onPressed: onRemove,
                  ),
                ],
              ),
            ),
            SwitchRow(
              label: l10n.creatorAdminEventPromotion,
              sub: l10n.creatorAdminEventPromotionHint,
              value: field.promotion,
              onChanged: (v) {
                field.promotion = v;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 公演のカード。日付・時刻未定・開始・終了・会場。
class EventPerformanceCard extends StatelessWidget {
  const EventPerformanceCard({
    super.key,
    required this.input,
    required this.venue,
    required this.showErrors,
    required this.onChanged,
    required this.onReadTime,
  });

  final PerformanceInput input;
  final TextEditingController venue;
  final bool showErrors;
  final ValueChanged<PerformanceInput> onChanged;

  /// 「ページから時刻を読む」。時刻未定で、公演のページの URL があるときだけ出す。
  final VoidCallback onReadTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = input.date;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SurfacePanel(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: l10n.creatorAdminEventFieldDate,
              required: true,
              error: showErrors && input.dateMissing,
              child: PickerBox(
                text: date == null
                    ? null
                    : l10n.creatorAdminEventDate(
                        fullDate(date, l10n),
                        weekdayLabel(date, l10n),
                      ),
                placeholder: l10n.creatorAdminEventPickDate,
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  final (first, last) = scheduleDateRange(date);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: first,
                    lastDate: last,
                  );
                  if (picked != null) onChanged(input.copyWith(date: picked));
                },
              ),
            ),
            SwitchRow(
              label: l10n.eventRegisterTimeTbd,
              sub: l10n.eventRegisterTimeTbdHint,
              value: input.allDay,
              onChanged: (v) => onChanged(input.copyWith(allDay: v)),
            ),
            if (input.allDay && input.url != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TonalButton(
                  label: l10n.eventRegisterReadTime,
                  onPressed: onReadTime,
                ),
              ),
            if (!input.allDay)
              StartEndTimeRow(
                start: input.start,
                end: input.end,
                startError: showErrors && input.startMissing,
                defaultStart: const TimeOfDay(hour: 18, minute: 0),
                defaultEnd: const TimeOfDay(hour: 20, minute: 0),
                onStartChanged: (t) => onChanged(input.copyWith(start: t)),
                onEndChanged: (t) => onChanged(input.copyWith(end: t)),
                onEndCleared: () => onChanged(input.copyWith(clearEnd: true)),
              ),
            LabeledField(
              label: l10n.creatorAdminEventFieldVenue,
              child: TextField(
                controller: venue,
                decoration: InputDecoration(
                  hintText: l10n.creatorAdminEventVenueHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「読み取る」のボタン。読み取っているあいだは、読み込み中の表示にして押せなくする。
class EventReadButton extends StatelessWidget {
  const EventReadButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;

  /// null なら押せない。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 48,
      child: Material(
        color: c.tonal,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 候補から登録した結果のスナックバーの文言。入力を足してもらう結果（[CandidateNeedsInput]）は、保存できなかったと出す。
String candidateRegisterMessage(
  AppLocalizations l10n,
  CandidateRegisterResult result,
) => switch (result) {
  CandidateRegistered(:final timeTbd) =>
    timeTbd ? l10n.eventCandidatesSavedTimeTbd : l10n.eventRegisterSaved,
  CandidateDuplicate() => l10n.eventRegisterDuplicateLink,
  CandidateNeedsInput() || CandidateFailed() => l10n.commonSaveFailed,
};
