import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/report.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/labeled_field.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/report_viewmodel.dart';

/// 通報（シート）（画面定義書（ファン向け）2.6.1）を出す。送ったら閉じて、[context] の画面に結果のスナックバーを出す。
/// 送れなかったときも、シートは閉じずに、スナックバーで知らせる。
Future<void> showReportSheet(BuildContext context, ReportTarget target) async {
  final submitted = await showAppSheet<bool>(
    context,
    builder: (_) => ReportSheet(target: target),
  );
  if (submitted == true && context.mounted) {
    showAppSnackBar(context, AppLocalizations.of(context)!.reportSubmitted);
  }
}

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({super.key, required this.target});

  final ReportTarget target;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final _detail = TextEditingController();

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(reportViewModelProvider.notifier);
    final result = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => vm.submit(widget.target));
    if (!mounted) return;
    switch (result) {
      case ReportResult.submitted:
        Navigator.of(context).pop(true);
      case ReportResult.duplicate:
        showAppSnackBar(context, l10n.reportAlreadySubmitted);
      case ReportResult.failed:
        showAppSnackBar(context, l10n.reportFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final state = ref.watch(reportViewModelProvider);
    final vm = ref.read(reportViewModelProvider.notifier);
    return Padding(
      // キーボードが出ても、入力欄と「送信」が隠れないようにする。
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheet(
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetTitle(l10n.reportTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                widget.target.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySecondary,
              ),
            ),
            for (final reason in ReportReason.values)
              ListTile(
                key: ValueKey('report-reason-${reason.name}'),
                leading: Icon(
                  state.reason == reason
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: state.reason == reason ? c.primary : c.textTertiary,
                ),
                title: Text(l10n.reportReason(reason)),
                selected: state.reason == reason,
                onTap: () => vm.selectReason(reason),
              ),
            LabeledField(
              label: l10n.reportDetailLabel,
              child: TextField(
                controller: _detail,
                minLines: 3,
                maxLines: 6,
                maxLength: ReportViewModel.maxDetailLength,
                keyboardType: TextInputType.multiline,
                onChanged: vm.setDetail,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(l10n.reportNote, style: context.textStyles.hint),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PrimaryButton(
                label: l10n.reportSubmit,
                onPressed: state.canSubmit ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
