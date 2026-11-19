import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/event_draft.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/text_limits.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../core/ui/labeled_field.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/state_view.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/event_register_viewmodel.dart';
import '../view_models/schedule_input.dart' show maxScheduleTitleLength;
import 'event_candidates_screen.dart';
import 'event_page_reader_screen.dart';
import 'event_register_parts.dart';
import 'event_search_screen.dart';
import 'performance_picker_sheet.dart';
import '../../core/ui/viewer_aware_header.dart';

/// イベントの登録・編集（画面定義書（設定・発信者向け）2.3.9）。チケットのページを開いて読み取って下書きにし、
/// タイトル・チケットのリンク（何本でも）・公演（1つのイベントに1つ。決定事項 1）を入れて保存する。[eventId] を渡すと、編集。
class EventRegisterScreen extends ConsumerStatefulWidget {
  const EventRegisterScreen({
    super.key,
    required this.creatorId,
    this.eventId,
    this.initialUrl,
    this.initialDraft,
  });

  final String creatorId;

  /// 編集するイベント。null なら、新しく登録する。
  final String? eventId;

  /// 新しく登録するとき、はじめから入れておくリンク（イベントの候補（2.3.11）から開いたとき）。
  final String? initialUrl;

  /// 新しく登録するとき、はじめから入れておく、読み取った内容。
  final EventDraft? initialDraft;

  /// 登録（[eventId] が null）・編集の画面を開く。
  static Future<void> open(
    BuildContext context, {
    required String creatorId,
    String? eventId,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          EventRegisterScreen(creatorId: creatorId, eventId: eventId),
    ),
  );

  @override
  ConsumerState<EventRegisterScreen> createState() =>
      _EventRegisterScreenState();
}

/// イベントの登録の画面の、入力欄の状態。読み取りの流れ（[_PageReading]）と、画面の State が使う。
abstract class _EventRegisterForm extends ConsumerState<EventRegisterScreen> {
  final _url = TextEditingController();
  final _title = TextEditingController();
  PerformanceInput _performance = const PerformanceInput();
  final _venue = TextEditingController();
  final _links = <EventLinkField>[];
  bool _showErrors = false;
  bool _showUrlError = false;

  /// 編集のとき、入っている内容を読み込めたか。読めなかったら、[_loadFailed]。
  bool _loaded = false;
  bool _loadFailed = false;

  bool get _editing => widget.eventId != null;

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    _venue.dispose();
    for (final l in _links) {
      l.controller.dispose();
    }
    super.dispose();
  }

  EventRegisterViewModel get _vm =>
      ref.read(eventRegisterViewModelProvider(widget.creatorId).notifier);

  /// 入力欄の内容。会場は、それぞれの入力欄から引く。
  EventRegisterInput get _input => EventRegisterInput(
    title: _title.text,
    links: [for (final l in _links) l.input],
    performance: _performance.copyWith(venue: _venue.text),
  );

  bool get _urlInvalid {
    final url = _url.text.trim();
    return url.isEmpty || !isHttpsUrl(url);
  }

  void _setPerformance(PerformanceInput p) {
    _performance = p;
    _venue.text = p.venue;
  }
}

/// ページからの読み取りの流れ（画面定義書 2.3.10）。ページを開いて読み取り、入力欄に入れる。
/// 時刻未定の公演は、公演のページから開演の時刻を読む（2.3.9）。
mixin _PageReading on _EventRegisterForm {
  /// 発信者がアプリの中でページを開き、表示しているページから読み取る（画面定義書 2.3.10）。
  Future<void> _read() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    if (_urlInvalid) {
      setState(() => _showUrlError = true);
      return;
    }
    setState(() => _showUrlError = false);
    var url = _url.text.trim();
    final outcome = await EventPageReaderScreen.open(context, Uri.parse(url));
    if (!mounted || outcome == null) return;
    final String html;
    switch (outcome) {
      case PageCandidates(:final candidates):
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EventCandidatesScreen(
              creatorId: widget.creatorId,
              candidates: candidates,
            ),
          ),
        );
        return;
      case PageHtml():
        html = outcome.html;
        // ページの中を移ってから読み取ったら、読み取りとリンクには、移った先のページの URL を使う。
        url = outcome.url?.toString() ?? url;
    }
    if (!mounted) return;
    if (html.trim().isEmpty) {
      showAppSnackBar(context, l10n.eventRegisterReadFailed);
      return;
    }
    final (draft, result) = await _vm.read(url, html: html);
    if (!mounted) return;
    await _apply(url, draft, result);
  }

  /// 読み取りの結果を、入力欄に入れて知らせる。公演が複数あれば、1つ選んでもらう（2.3.14。選ばなければ、公演は
  /// そのまま）。読み取った URL は、まだなければリンクに足す。
  Future<void> _apply(
    String url,
    EventDraft? draft,
    EventReadResult result,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case EventReadResult.read:
        final chosen = await pickPerformance(
          context,
          draft?.performances ?? const [],
        );
        if (!mounted) return;
        setState(
          () => _fill(
            url,
            EventDraft(title: draft?.title, performances: [?chosen]),
          ),
        );
        showAppSnackBar(context, l10n.eventRegisterReadDone);
      case EventReadResult.unreadable:
        showAppSnackBar(context, l10n.eventRegisterReadFailed);
      case EventReadResult.failed:
        showAppSnackBar(context, l10n.commonLoadFailedTitle);
    }
  }

  /// 読み取った内容を入力欄に入れる。公演は、[draft] の1つめ（呼ぶ側で1つに絞る）。リンクには、公演のページの URL を、
  /// なければ読み取った URL を、まだなければ足す。
  void _fill(String url, EventDraft? draft) {
    final title = draft?.title;
    if (title != null) _title.text = title;
    final performance = draft?.performances.firstOrNull;
    if (performance != null) {
      _setPerformance(PerformanceInput.fromDraft(performance));
    }
    final link = performance?.url ?? url;
    if (!_links.any((l) => l.controller.text.trim() == link)) {
      // 空のリンクの欄があれば、そこに入れる。
      final empty = _links.where((l) => l.input.empty).firstOrNull;
      if (empty != null) {
        empty.controller.text = link;
      } else {
        _links.add(EventLinkField(url: link));
      }
    }
  }

  /// 時刻未定の公演の、公演のページを開いて、開演の時刻を読む（画面定義書 2.3.9）。
  Future<void> _readTime() async {
    final l10n = AppLocalizations.of(context)!;
    final url = _performance.url;
    if (url == null) return;
    final outcome = await EventPageReaderScreen.open(
      context,
      Uri.parse(url),
      mode: PageReaderMode.readTime,
    );
    if (!mounted || outcome is! PageHtml) return;
    final (draft, _) = outcome.html.trim().isEmpty
        ? (null, EventReadResult.unreadable)
        : await _vm.read(url, html: outcome.html);
    if (!mounted) return;
    final p = _performance;
    final timed = [
      for (final d in draft?.performances ?? const <PerformanceDraft>[])
        if (d.start != null) d,
    ];
    // 同じ日の公演の時刻。なければ、ページの公演が1つだけのときの時刻。
    final match =
        timed.where((d) => DateUtils.isSameDay(d.date, p.date)).firstOrNull ??
        (timed.length == 1 ? timed.single : null);
    if (match == null) {
      showAppSnackBar(context, l10n.eventRegisterTimeReadFailed);
      return;
    }
    final read = PerformanceInput.fromDraft(match);
    setState(
      () => _performance = PerformanceInput(
        date: p.date,
        start: read.start,
        end: read.end,
        venue: _venue.text,
        url: p.url,
      ),
    );
    showAppSnackBar(context, l10n.eventRegisterTimeRead);
  }
}

class _EventRegisterScreenState extends _EventRegisterForm with _PageReading {
  @override
  void initState() {
    super.initState();
    if (_editing) {
      _load();
    } else {
      _loaded = true;
      final url = widget.initialUrl;
      if (url != null) {
        _url.text = url;
        _fill(url, widget.initialDraft);
      }
    }
  }

  /// 編集するイベントを読み、入力欄に入れる。
  Future<void> _load({bool retry = false}) async {
    setState(() => _loadFailed = false);
    // 読み終えるまで、ViewModel が自動で捨てられないように見張っておく。
    final keep = ref.listenManual(
      eventRegisterViewModelProvider(widget.creatorId),
      (_, _) {},
    );
    try {
      final eventId = widget.eventId!;
      final event = await (retry
          ? _vm.retryLoadEvent(eventId)
          : _vm.loadEvent(eventId));
      if (!mounted) return;
      if (event == null) throw StateError('event not found');
      setState(() {
        _title.text = event.title;
        _setPerformance(
          event.performances.isEmpty
              ? const PerformanceInput()
              : PerformanceInput.fromItem(event.performances.first),
        );
        for (final l in _links) {
          l.controller.dispose();
        }
        _links
          ..clear()
          ..addAll([
            for (final l in event.links)
              EventLinkField(url: l.url, promotion: l.isPromotion),
          ]);
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      keep.close();
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _showErrors = true);
    final input = _input;
    final error = input.valid && !input.titleTooLong && !input.linkInvalid
        ? await ref
              .read(loadingOverlayProvider.notifier)
              .run(() => _vm.save(input, eventId: widget.eventId))
        : await _vm.save(input, eventId: widget.eventId);
    if (!mounted) return;
    switch (error) {
      case null:
        showAppSnackBar(
          context,
          _editing ? l10n.eventRegisterUpdated : l10n.eventRegisterSaved,
        );
        Navigator.of(context).pop();
      case EventRegisterError.requiredMissing:
        showAppSnackBar(context, l10n.creatorAdminEventRequiredMissing);
      case EventRegisterError.titleTooLong:
        showAppSnackBar(context, l10n.creatorAdminEventTitleTooLong);
      // リンクの欄に案内を出す（[_showErrors]）。
      case EventRegisterError.linkInvalid:
        break;
      case EventRegisterError.duplicateLink:
        showAppSnackBar(context, l10n.eventRegisterDuplicateLink);
      case EventRegisterError.failed:
        showAppSnackBar(context, l10n.commonSaveFailed);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final id = widget.eventId;
    if (id == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.eventRegisterDeleteConfirmTitle,
      message: l10n.eventRegisterDeleteConfirmMessage,
      confirmLabel: l10n.creatorAdminEventDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final error = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => _vm.delete(id));
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      showAppSnackBar(context, l10n.creatorAdminEventDeleteFailed);
    }
  }

  /// チケットサイトで探す（画面定義書 2.3.12）を開く。
  Future<void> _openSearch() async {
    final name = await _vm.creatorName();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EventSearchScreen(creatorId: widget.creatorId, initialName: name),
      ),
    );
  }

  void _removeLink(int i) => setState(() {
    _links.removeAt(i).controller.dispose();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(eventRegisterViewModelProvider(widget.creatorId));
    final title = _editing ? l10n.eventEditTitle : l10n.eventRegisterTitle;
    if (!_loaded) {
      return HeaderScaffold(
        appBar: ScreenAppBar(title: title),
        body: _loadFailed
            ? StateView.error(onRetry: () => _load(retry: true))
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final input = _input;
    return HeaderScaffold(
      appBar: ScreenAppBar(
        title: title,
        actions: [
          AppTextButton(label: l10n.commonSave, fontSize: 15, onPressed: _save),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: [
          if (!_editing)
            SettingsRow(
              icon: Icons.search,
              label: l10n.eventSearchTitle,
              onTap: _openSearch,
            ),
          LabeledField(
            label: l10n.eventRegisterUrlLabel,
            note: l10n.eventRegisterUrlHint,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'https://',
                      errorText: _showUrlError && _url.text.trim().isNotEmpty
                          ? l10n.creatorAdminEventLinkInvalid
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                EventReadButton(
                  label: l10n.eventRegisterRead,
                  loading: state.reading,
                  // URL が空のあいだは押せない（2.3.9）。
                  onPressed: _url.text.trim().isEmpty ? null : _read,
                ),
              ],
            ),
          ),
          LabeledField(
            label: l10n.creatorAdminEventFieldTitle,
            required: true,
            error: _showErrors && (input.titleMissing || input.titleTooLong),
            child: TextField(
              controller: _title,
              maxLength: maxScheduleTitleLength,
              decoration: InputDecoration(
                counterText: '',
                hintText: l10n.creatorAdminEventTitleHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SectionLabel(l10n.eventRegisterPerformance),
          EventPerformanceCard(
            input: _performance,
            venue: _venue,
            showErrors: _showErrors,
            onChanged: (p) => setState(() => _performance = p),
            onReadTime: _readTime,
          ),
          SectionLabel(l10n.eventRegisterLinksLabel),
          for (var i = 0; i < _links.length; i++)
            EventLinkCard(
              field: _links[i],
              showErrors: _showErrors,
              onChanged: () => setState(() {}),
              onRemove: () => _removeLink(i),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TonalButton(
              label: l10n.eventRegisterAddLink,
              onPressed: () => setState(() => _links.add(EventLinkField())),
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: 16),
            SettingsRow(
              icon: Icons.delete_outline,
              label: l10n.eventRegisterDelete,
              destructive: true,
              showChevron: false,
              onTap: _delete,
            ),
          ],
        ],
      ),
    );
  }
}
