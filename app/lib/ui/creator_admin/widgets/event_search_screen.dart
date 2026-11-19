import 'package:flutter/material.dart';

import '../../../domain/models/event_draft.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/labeled_field.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../../domain/models/ticket_search.dart';
import 'event_page_reader_screen.dart';
import 'hidden_page.dart';
import 'performance_candidates_screen.dart';
import '../../core/ui/viewer_aware_header.dart';

/// チケットサイトで探す（画面定義書（設定・発信者向け）2.3.12）。アーティスト名で、チケットぴあ・イープラス・ローチケ・楽天チケットを
/// 検索し、ヒットしたアーティストをサイトごとに並べる（楽天チケットは、ヒットしたイベントを並べる）。選んだアーティストで、公演の候補（2.3.13）を開く。
/// 検索結果のページは、「探す」を押したときだけ、画面に出さずにサイトごとに1ページ開く。
class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({
    super.key,
    required this.creatorId,
    required this.initialName,
  });

  final String creatorId;

  /// アーティスト名の初期値（発信者の名前）。
  final String initialName;

  @override
  State<EventSearchScreen> createState() => _EventSearchScreenState();
}

/// 1つのサイトの検索の結果。
sealed class _SiteResult {
  const _SiteResult();
}

class _Searching extends _SiteResult {
  const _Searching();
}

class _Failed extends _SiteResult {
  const _Failed({this.maintenance = false});

  /// メンテナンス中だった。
  final bool maintenance;
}

class _Found extends _SiteResult {
  const _Found(this.artists);

  final List<ArtistHit> artists;
}

class _EventSearchScreenState extends State<EventSearchScreen> {
  late final _name = TextEditingController(text: widget.initialName);
  final _pages = {for (final s in TicketSite.values) s: HiddenPage()};

  /// サイトごとの結果。まだ探していなければ空。
  final _results = <TicketSite, _SiteResult>{};

  /// 選んだアーティスト（アーティストのページの URL）。
  final _selected = <String>{};

  bool get _searching => _results.values.any((r) => r is _Searching);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _name.text.trim();
    if (name.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _selected.clear();
      for (final site in TicketSite.values) {
        _results[site] = const _Searching();
      }
    });
    await Future.wait([
      for (final site in TicketSite.values) _searchSite(site, name),
    ]);
  }

  Future<void> _searchSite(TicketSite site, String name) async {
    _SiteResult result;
    final l10n = AppLocalizations.of(context)!;
    try {
      final artists = site == TicketSite.rakuten
          // 楽天チケットは、検索結果にアーティストが出ず、イベントが直接並ぶ。検索結果を1人の代わりにする。
          ? TicketSearch.rakutenArtist(
              name,
              EventPageReaderScreen.parseCandidates(
                await _pages[site]!.run(
                  TicketSearch.searchUrl(site, name),
                  EventPageReaderScreen.candidatesScript,
                  ready: (r) =>
                      EventPageReaderScreen.parseCandidates(r).isNotEmpty,
                ),
              ),
              l10n.eventSearchRakutenEvents,
            )
          : TicketSearch.parseArtists(
              site,
              await _pages[site]!.run(
                TicketSearch.searchUrl(site, name),
                TicketSearch.artistsScript(site),
                ready: (r) => TicketSearch.parseArtists(site, r).isNotEmpty,
              ),
            );
      result = _Found(artists);
      // 名前が入れた名前と同じアーティストは、はじめから選んでおく。同じ名前がなければ、括弧の補足と記号を除いて
      // 1人だけ合うときに選ぶ（「星街すいせい (アイドルVtuber)」など。2人以上なら、同じ名前の別人かもしれないので選ばない）。
      for (final a
          in site == TicketSite.rakuten
              ? artists
              : TicketSearch.likelyArtists(artists, name)) {
        _selected.add(a.url);
      }
    } on PageUnderMaintenance {
      result = const _Failed(maintenance: true);
    } catch (_) {
      result = const _Failed();
    }
    if (mounted) setState(() => _results[site] = result);
  }

  List<ArtistHit> get _chosen => [
    for (final r in _results.values)
      if (r is _Found)
        for (final a in r.artists)
          if (_selected.contains(a.url)) a,
  ];

  void _openPerformances() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PerformanceCandidatesScreen(
        creatorId: widget.creatorId,
        artists: _chosen,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final chosen = _chosen;
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.eventSearchTitle),
      body: Stack(
        children: [
          for (final page in _pages.values) HiddenPageView(page: page),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    LabeledField(
                      label: l10n.eventSearchName,
                      note: l10n.eventSearchNote,
                      child: TextField(
                        controller: _name,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: TonalButton(
                        label: l10n.eventSearchButton,
                        onPressed: _name.text.trim().isEmpty || _searching
                            ? null
                            : _search,
                      ),
                    ),
                    for (final site in TicketSite.values)
                      if (_results[site] case final result?) ...[
                        SectionLabel(site.label),
                        switch (result) {
                          _Searching() => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          _Failed(:final maintenance) => _Note(
                            maintenance
                                ? l10n.eventSearchMaintenance
                                : l10n.commonLoadFailedTitle,
                          ),
                          _Found(:final artists) when artists.isEmpty => _Note(
                            l10n.eventSearchNoArtist,
                          ),
                          _Found(:final artists) => Column(
                            children: [
                              for (final a in artists)
                                CheckboxListTile(
                                  value: _selected.contains(a.url),
                                  onChanged: (v) => setState(
                                    () => v == true
                                        ? _selected.add(a.url)
                                        : _selected.remove(a.url),
                                  ),
                                  title: Text(
                                    a.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    site.label,
                                    style: context.textStyles.caption,
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                            ],
                          ),
                        },
                      ],
                  ],
                ),
              ),
              if (_results.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: PrimaryButton(
                      label: l10n.eventSearchShowPerformances(chosen.length),
                      onPressed: chosen.isEmpty || _searching
                          ? null
                          : _openPerformances,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Text(text, style: context.textStyles.hint),
  );
}
