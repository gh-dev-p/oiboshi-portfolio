import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/event.dart';
import '../../../domain/models/event_draft.dart';
import '../../../domain/models/event_url_key.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../utils/formatters.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/value_key.dart';
import 'creator_admin_providers.dart';
import 'event_register_viewmodel.dart';
import 'schedule_input.dart';

/// 公演の候補の画面のキー（発信者と、候補の URL）。Provider のキーに使うので、値で等しさを決める。
class EventCandidatesKey extends ProviderKey {
  const EventCandidatesKey(this.creatorId, this.urls);

  final String creatorId;
  final List<String> urls;

  @override
  List<Object?> get props => [creatorId, urls];
}

/// 候補をワンタップで登録した結果。
sealed class CandidateRegisterResult {
  const CandidateRegisterResult();
}

/// 登録できた。[timeTbd] なら、開演の時刻が読み取れず「時刻未定」にした公演がある。
class CandidateRegistered extends CandidateRegisterResult {
  const CandidateRegistered({this.timeTbd = false});

  final bool timeTbd;
}

/// タイトルか公演が読み取れなかった。下書きを入れた登録の画面で、足してもらう。
class CandidateNeedsInput extends CandidateRegisterResult {
  const CandidateNeedsInput(this.draft);

  final EventDraft? draft;
}

/// 同じチケットのページを指すリンクが、ほかのイベントにある。
class CandidateDuplicate extends CandidateRegisterResult {
  const CandidateDuplicate();
}

/// 保存に失敗した。
class CandidateFailed extends CandidateRegisterResult {
  const CandidateFailed();
}

/// イベントの候補（画面定義書（設定・発信者向け）2.3.11）。候補のうち登録済みのもの（URL の集合）を持ち、
/// 発信者が開いて確かめたイベントのページから、ワンタップでイベントを登録する。
class EventCandidatesViewModel extends AsyncNotifier<Set<String>> {
  EventCandidatesViewModel(this.key);

  final EventCandidatesKey key;

  @override
  Future<Set<String>> build() => withSession(
    ref,
    (_) => ref
        .watch(scheduleRepositoryProvider)
        .registeredEventUrls(key.creatorId, key.urls),
  );

  /// 登録済みかを読み直す。
  Future<void> reload() async {
    final registered = await ref
        .read(scheduleRepositoryProvider)
        .registeredEventUrls(key.creatorId, key.urls)
        .catchError((_) => state.value ?? <String>{});
    if (ref.mounted) state = AsyncData(registered);
  }

  /// 発信者が開いた候補のページ（[url]）から取り出した部分（[html]）を読み取る。読めなければ null。
  Future<EventDraft?> read(String url, String html) async {
    if (html.trim().isEmpty) return null;
    try {
      return await ref
          .read(scheduleRepositoryProvider)
          .readEventUrl(url, html: html);
    } catch (_) {
      return null;
    }
  }

  /// 読み取った [draft] のうち、[performance]（ページの公演から、発信者が選んだもの）を、足りていれば、そのまま
  /// 1つのイベントとして登録する。リンクは、公演のページの URL、なければ候補の [url]。開演の時刻が読み取れなければ
  /// 「時刻未定」にする。
  Future<CandidateRegisterResult> register(
    String url,
    EventDraft? draft,
    PerformanceDraft? performance,
  ) async {
    final title = draft?.title?.trim() ?? '';
    if (draft == null ||
        scheduleTitleMissing(title) ||
        scheduleTitleTooLong(title) ||
        performance == null) {
      return CandidateNeedsInput(
        draft == null
            ? null
            : EventDraft(title: draft.title, performances: [?performance]),
      );
    }
    return _save(
      title,
      [performance.url ?? url],
      [PerformanceInput.fromDraft(performance, tbdIfNoStart: true)],
    );
  }

  /// 公演の候補（2.3.13）の1公演を、1つのイベントとして登録する。[html] は、発信者が開いた [opened] の公演のページから
  /// 取り出した部分。チケットリンクは、まとめたサイトごとの公演のページ。開演と会場は開いたページから読み、
  /// 読めなければ一覧のもの、開演がそれもなければ「時刻未定」にする。ページに同じ日の公演が複数あり（昼夜の公演）、
  /// どれか決められなければ、ページの開演は使わない。
  Future<CandidateRegisterResult> registerPerformance(
    PerformanceGroup group,
    TicketOption opened,
    String html,
  ) async {
    EventDraft? draft;
    try {
      draft = html.trim().isEmpty
          ? null
          : await ref
                .read(scheduleRepositoryProvider)
                .readEventUrl(opened.url, html: html);
    } catch (_) {
      draft = null;
    }
    final sameDay = [
      for (final p in draft?.performances ?? const <PerformanceDraft>[])
        if (isSameDay(p.date, group.date)) p,
    ];
    // 同じ日の公演が複数あれば（昼夜の公演）、一覧の開演に合うものを選ぶ。決められなければ、ページの時刻は使わない。
    final timed = {
      for (final p in sameDay)
        if (p.start != null) p.start,
    };
    final match = group.start != null
        ? sameDay.where((p) => p.start == group.start).firstOrNull
        : (timed.length <= 1 ? sameDay.firstOrNull : null);
    final start = match?.start ?? group.start;
    final input = PerformanceInput.fromDraft(
      PerformanceDraft(
        date: group.date,
        start: start,
        end: match?.start == null ? null : match?.end,
        venue: match?.venue ?? group.venue,
        url: opened.url,
      ),
      tbdIfNoStart: true,
    );
    final title = opened.eventTitle.trim().isNotEmpty
        ? opened.eventTitle.trim()
        : (draft?.title?.trim() ?? '');
    // タイトルが取れない・長すぎると保存できないので、下書きを入れた登録の画面で直してもらう（2.3.11）。
    if (scheduleTitleMissing(title) || scheduleTitleTooLong(title)) {
      return CandidateNeedsInput(
        EventDraft(
          title: title.isEmpty ? null : title,
          performances: [
            PerformanceDraft(
              date: group.date,
              start: start,
              end: match?.start == null ? null : match?.end,
              venue: match?.venue ?? group.venue,
              url: opened.url,
            ),
          ],
        ),
      );
    }
    return _save(title, [for (final t in group.tickets) t.url], [input]);
  }

  /// イベントを保存し、一覧と予定を読み直す。チケットリンクは [urls]（同じチケットのページを指すものは1本にする）。
  Future<CandidateRegisterResult> _save(
    String title,
    List<String> urls,
    List<PerformanceInput> performances,
  ) async {
    final error = await saveEventOrError(
      () => ref
          .read(scheduleRepositoryProvider)
          .saveEvent(
            creatorId: key.creatorId,
            title: title,
            links: uniqueEventLinks([
              for (final url in urls) EventLink(url: url),
            ]),
            performances: [
              for (final p in performances) p.toItem(key.creatorId),
            ],
          ),
    );
    if (error != null) {
      return switch (error) {
        EventSaveError.duplicateLink => const CandidateDuplicate(),
        EventSaveError.failed => const CandidateFailed(),
      };
    }
    refreshCreatorSchedules(ref, key.creatorId);
    ref.invalidate(registeredPerformancesProvider(key.creatorId));
    await reload();
    return CandidateRegistered(timeTbd: performances.any((p) => p.allDay));
  }
}

/// 発信者が登録したイベントの公演（公演の候補で、日付・会場・開演でも登録済みを見分けるため）。
final registeredPerformancesProvider = FutureProvider.autoDispose
    .family<List<ScheduleItem>, String>(
      (ref, creatorId) => withSession(ref, (_) async {
        final items = await ref
            .watch(scheduleRepositoryProvider)
            .fetchCreatorPerformances(creatorId);
        return [
          for (final s in items)
            if (s.eventId != null) s,
        ];
      }),
    );

final eventCandidatesViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<EventCandidatesViewModel, Set<String>, EventCandidatesKey>(
      EventCandidatesViewModel.new,
    );
