import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/event.dart';
import '../../../domain/models/event_draft.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/event_candidates_viewmodel.dart';
import 'event_page_reader_screen.dart';
import 'event_register_parts.dart';
import 'event_register_screen.dart';
import 'performance_picker_sheet.dart';
import '../../core/ui/viewer_aware_header.dart';

/// イベントの候補（画面定義書（設定・発信者向け）2.3.11）。検索結果やアーティストのページにあったイベントのページへの
/// リンクを並べ、発信者が1件ずつページを開いて確かめ、「このイベントを登録」で登録する（ページに公演が複数あれば、1つ選ぶ）。
class EventCandidatesScreen extends ConsumerStatefulWidget {
  const EventCandidatesScreen({
    super.key,
    required this.creatorId,
    required this.candidates,
  });

  final String creatorId;
  final List<EventCandidate> candidates;

  @override
  ConsumerState<EventCandidatesScreen> createState() =>
      _EventCandidatesScreenState();
}

class _EventCandidatesScreenState extends ConsumerState<EventCandidatesScreen> {
  List<EventCandidate> get _candidates => widget.candidates;

  String get creatorId => widget.creatorId;

  EventCandidatesKey get _key =>
      EventCandidatesKey(creatorId, [for (final c in _candidates) c.url]);

  Future<void> _open(EventCandidate candidate) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await EventPageReaderScreen.open(
      context,
      Uri.parse(candidate.url),
      mode: PageReaderMode.register,
    );
    if (outcome is! PageHtml || !mounted) return;
    final vm = ref.read(eventCandidatesViewModelProvider(_key).notifier);
    final overlay = ref.read(loadingOverlayProvider.notifier);
    final draft = await overlay.run(() => vm.read(candidate.url, outcome.html));
    if (!mounted) return;
    // ページに公演が複数あれば、1つ選んでもらう（2.3.14）。選ばずに閉じたら、登録しない。
    final performances = draft?.performances ?? const <PerformanceDraft>[];
    final chosen = await pickPerformance(context, performances);
    if (!mounted || (performances.isNotEmpty && chosen == null)) return;
    final result = await overlay.run(
      () => vm.register(candidate.url, draft, chosen),
    );
    if (!mounted) return;
    switch (result) {
      case CandidateRegistered() || CandidateDuplicate() || CandidateFailed():
        showAppSnackBar(context, candidateRegisterMessage(l10n, result));
      case CandidateNeedsInput(:final draft):
        // 足りない項目を、登録の画面で足してもらう。
        if (draft == null) {
          showAppSnackBar(context, l10n.eventRegisterReadFailed);
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EventRegisterScreen(
              creatorId: creatorId,
              initialUrl: candidate.url,
              initialDraft: draft,
            ),
          ),
        );
        await vm.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidates = _candidates;
    final title = l10n.eventCandidatesTitle;
    final registered =
        ref.watch(eventCandidatesViewModelProvider(_key)).value ?? const {};
    return HeaderScaffold(
      appBar: ScreenAppBar(title: title),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              candidates.isEmpty
                  ? l10n.eventCandidatesEmpty
                  : l10n.eventCandidatesNote,
              style: context.textStyles.hint,
            ),
          ),
          for (final candidate in candidates)
            _CandidateRow(
              candidate: candidate,
              registered: registered.contains(candidate.url),
              onTap: () => _open(candidate),
            ),
        ],
      ),
    );
  }
}

/// 候補の1行。リンクの文字（2行まで）と、日付・会場とサイトの名前。登録済みなら「登録済み」のチップ。
class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.registered,
    required this.onTap,
  });

  final EventCandidate candidate;
  final bool registered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: registered ? c.textSecondary : c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      ?candidate.detail,
                      l10n.eventLinkSite(EventLink(url: candidate.url)),
                    ].join(l10n.commonListSeparator),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (registered)
              StatusChip(l10n.eventCandidatesRegistered, muted: true)
            else
              Icon(Icons.chevron_right, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
