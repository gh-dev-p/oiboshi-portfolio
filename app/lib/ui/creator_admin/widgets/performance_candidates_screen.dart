import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/event_draft.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/event_panel.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/event_candidates_viewmodel.dart';
import '../../../domain/models/ticket_search.dart';
import 'event_page_reader_screen.dart';
import 'event_register_screen.dart';
import 'event_register_parts.dart';
import 'hidden_page.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 公演の候補（画面定義書（設定・発信者向け）2.3.13）。選んだアーティストの公演を、サイトを横断して1日1行で並べる。
/// アーティストのページと、そこにあるイベントのページを、画面に出さずにサイトごとに1ページずつ開いて、公演を集める
/// （アーティストのページには受付中の公演しか出ないサイトがあるため、イベントのページから、受付が終わった公演も拾う）。
class PerformanceCandidatesScreen extends ConsumerStatefulWidget {
  const PerformanceCandidatesScreen({
    super.key,
    required this.creatorId,
    required this.artists,
  });

  final String creatorId;
  final List<ArtistHit> artists;

  @override
  ConsumerState<PerformanceCandidatesScreen> createState() =>
      _PerformanceCandidatesScreenState();
}

class _PerformanceCandidatesScreenState
    extends ConsumerState<PerformanceCandidatesScreen> {
  final _pages = {for (final s in TicketSite.values) s: HiddenPage()};

  /// まとめた公演。集め終えるまで null。
  List<PerformanceGroup>? _groups;

  /// 開けなかったページの数。
  int _failed = 0;

  /// 開いたページの数と、開くページの数（読み込み中の表示）。
  int _done = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _groups = null;
      _failed = 0;
      _done = 0;
      _total = widget.artists.length;
    });
    final entries = <PerformanceEntry>[];
    await Future.wait([
      for (final site in TicketSite.values)
        _collect(site, [
          for (final a in widget.artists)
            if (a.site == site) a,
        ], entries),
    ]);
    if (!mounted) return;
    setState(
      () => _groups = TicketSearch.group(entries, dateOnly(DateTime.now())),
    );
  }

  /// 1つのサイトの、選んだアーティストのページと、そこにあるイベントのページを1ページずつ開いて、公演を集める。
  Future<void> _collect(
    TicketSite site,
    List<ArtistHit> artists,
    List<PerformanceEntry> into,
  ) async {
    final page = _pages[site]!;
    for (final artist in artists) {
      List<EventCandidate> events = const [];
      try {
        final results = await page.runAll(
          Uri.parse(artist.url),
          [
            EventPageReaderScreen.candidatesScript,
            TicketSearch.performancesScript,
          ],
          ready: (r) => EventPageReaderScreen.parseCandidates(r[0]).isNotEmpty,
        );
        events = [
          for (final e in EventPageReaderScreen.parseCandidates(results[0]))
            if (TicketSearch.onSite(site, e.url)) e,
        ];
        // イープラスは、アーティストのページの公演ごとのリンクも拾う。
        into.addAll(
          TicketSearch.parsePerformances(
            site,
            results[1],
            pageUrl: artist.url,
            titled: false,
          ).where((e) => e.perfLevel),
        );
      } catch (_) {
        _failed++;
      }
      if (!mounted) return;
      setState(() {
        _done++;
        _total += events.length;
      });
      for (final event in events) {
        try {
          final result = await page.run(
            Uri.parse(event.url),
            TicketSearch.performancesScript,
            ready: (r) => TicketSearch.parsePerformances(
              site,
              r,
              pageUrl: event.url,
            ).isNotEmpty,
          );
          into.addAll(
            TicketSearch.parsePerformances(
              site,
              result,
              pageUrl: event.url,
              linkTitle: event.text,
            ),
          );
        } catch (_) {
          _failed++;
        }
        if (!mounted) return;
        setState(() => _done++);
      }
    }
  }

  EventCandidatesKey get _key => EventCandidatesKey(widget.creatorId, [
    for (final g in _groups!)
      for (final t in g.tickets) t.url,
  ]);

  Future<void> _open(PerformanceGroup group) async {
    final l10n = AppLocalizations.of(context)!;
    // 最初のサイト（チケットぴあ・ローチケ・イープラス・楽天チケットの順）の公演のページを開く。
    final ticket = group.tickets.first;
    final outcome = await EventPageReaderScreen.open(
      context,
      Uri.parse(ticket.pageUrl),
      mode: PageReaderMode.register,
    );
    if (outcome is! PageHtml || !mounted) return;
    final vm = ref.read(eventCandidatesViewModelProvider(_key).notifier);
    final result = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => vm.registerPerformance(group, ticket, outcome.html));
    if (!mounted) return;
    if (result is CandidateNeedsInput) {
      // タイトルが読み取れない・長すぎるときは、下書きを入れた登録の画面で直してもらう。
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EventRegisterScreen(
            creatorId: widget.creatorId,
            initialUrl: ticket.url,
            initialDraft: result.draft,
          ),
        ),
      );
      await vm.reload();
      ref.invalidate(registeredPerformancesProvider(widget.creatorId));
      return;
    }
    showAppSnackBar(context, candidateRegisterMessage(l10n, result));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = _groups;
    final title = l10n.performanceCandidatesTitle;
    if (groups == null) {
      return HeaderScaffold(
        appBar: ScreenAppBar(title: title),
        body: Stack(
          children: [
            for (final page in _pages.values) HiddenPageView(page: page),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.performanceCandidatesLoading(_done, _total),
                    style: context.textStyles.hint,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final registered =
        ref.watch(eventCandidatesViewModelProvider(_key)).value ?? const {};
    final performances =
        ref.watch(registeredPerformancesProvider(widget.creatorId)).value ??
        const [];
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
              groups.isEmpty
                  ? l10n.performanceCandidatesEmpty
                  : l10n.performanceCandidatesNote,
              style: context.textStyles.hint,
            ),
          ),
          for (final g in groups)
            _PerformanceRow(
              group: g,
              // チケットリンクの URL か、日付・会場・開演で、登録済みを見分ける。
              registered:
                  g.tickets.any((t) => registered.contains(t.url)) ||
                  TicketSearch.alreadyRegistered(g, performances),
              onTap: () => _open(g),
            ),
          if (_failed > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.performanceCandidatesFailedEvents(_failed),
                    style: context.textStyles.hint,
                  ),
                  const SizedBox(height: 8),
                  TonalButton(label: l10n.commonRetry, onPressed: _load),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 公演の1行。ファンのイベントの行（EventRow）と同じ形で、左に日付のブロック、右にイベントの名前と「{曜日}・{会場}」、
/// その下に売っているサイト。登録済みなら「登録済み」のチップ。
class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.group,
    required this.registered,
    required this.onTap,
  });

  final PerformanceGroup group;
  final bool registered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final date = group.date;
    final weekday = weekdayLabel(date, l10n);
    final venue = group.venue;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            EventDateTile(start: date),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineText(
                    group.eventTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: registered ? c.textSecondary : c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  OneLineText(
                    venue == null || venue.isEmpty
                        ? weekday
                        : l10n.commonWhenVenue(weekday, venue),
                    style: context.textStyles.caption,
                  ),
                  const SizedBox(height: 2),
                  OneLineText(
                    group.tickets
                        .map((t) => t.site.label)
                        .join(l10n.commonListSeparator),
                    style: context.textStyles.hint,
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
