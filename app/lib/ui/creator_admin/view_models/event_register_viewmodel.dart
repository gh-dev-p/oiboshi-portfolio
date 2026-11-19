import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/event.dart';
import '../../../domain/models/event_draft.dart';
import '../../../domain/models/event_url_key.dart';
import '../../../domain/models/schedule_item.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/guard.dart';
import '../../oshi/view_models/oshi_providers.dart';
import '../../schedule/view_models/schedule_providers.dart';
import 'creator_admin_providers.dart';
import 'schedule_input.dart';

/// 公演1つの入力（画面定義書（設定・発信者向け）2.3.9）。
class PerformanceInput {
  const PerformanceInput({
    this.date,
    this.allDay = false,
    this.start,
    this.end,
    this.venue = '',
    this.url,
  });

  /// 読み取った下書きから作る。開始の時刻が分からない公演は、[tbdIfNoStart] なら時刻未定にし、
  /// でなければ開始を空のままにする。
  factory PerformanceInput.fromDraft(
    PerformanceDraft d, {
    bool tbdIfNoStart = false,
  }) => PerformanceInput(
    date: d.date,
    allDay: tbdIfNoStart && d.start == null,
    start: _time(d.start),
    end: _time(d.end),
    venue: d.venue ?? '',
    url: d.url,
  );

  /// 登録済みの公演（予定の行）から作る（編集のとき）。
  factory PerformanceInput.fromItem(ScheduleItem item) {
    final times = scheduleTimesOf(item);
    return PerformanceInput(
      date: times.date,
      allDay: times.allDay,
      start: times.start,
      end: times.end,
      venue: item.venue ?? '',
      url: item.performanceUrl,
    );
  }

  static TimeOfDay? _time(({int hour, int minute})? t) =>
      t == null ? null : TimeOfDay(hour: t.hour, minute: t.minute);

  final DateTime? date;
  final bool allDay;
  final TimeOfDay? start;

  /// 終了の時刻。空なら、デフォルトの長さで描く。開始より前なら、翌日の時刻とみなす。
  final TimeOfDay? end;
  final String venue;

  /// 公演のページの URL（読み取ったもの。入力欄はなく、そのまま持つ）。
  final String? url;

  bool get dateMissing => date == null;
  bool get startMissing => !allDay && start == null;
  bool get valid => !dateMissing && !startMissing;

  PerformanceInput copyWith({
    DateTime? date,
    bool? allDay,
    TimeOfDay? start,
    TimeOfDay? end,
    bool clearEnd = false,
    String? venue,
  }) => PerformanceInput(
    date: date ?? this.date,
    allDay: allDay ?? this.allDay,
    start: start ?? this.start,
    end: clearEnd ? null : end ?? this.end,
    venue: venue ?? this.venue,
    url: url,
  );

  /// 予定にする（日時・会場・公演のページの URL。タイトルとリンクは、保存の関数が写す）。[valid] のときだけ呼ぶ。
  ScheduleItem toItem(String creatorId) {
    final (:startsAt, :endsAt) = startEndOf(
      date: date!,
      allDay: allDay,
      start: start,
      end: end,
    );
    final venue = this.venue.trim();
    return ScheduleItem(
      id: '',
      creatorId: creatorId,
      title: '',
      startsAt: startsAt,
      endsAt: endsAt,
      allDay: allDay,
      venue: venue.isEmpty ? null : venue,
      performanceUrl: url,
    );
  }
}

/// リンク1本の入力。広告（PR）かは、リンクごとに持つ。
class LinkInput {
  const LinkInput({this.url = '', this.promotion = false});

  final String url;
  final bool promotion;

  bool get empty => url.trim().isEmpty;

  /// 入っていて、`https://` で始まる URL でない。
  bool get invalid => scheduleLinkInvalid(url);
}

/// イベントの入力。タイトル・リンク・公演（1つのイベントに1つ。決定事項 1）。空のリンクは保存しない。
class EventRegisterInput {
  const EventRegisterInput({
    required this.title,
    required this.links,
    required this.performance,
  });

  final String title;
  final List<LinkInput> links;
  final PerformanceInput performance;

  bool get titleMissing => scheduleTitleMissing(title);
  bool get titleTooLong => scheduleTitleTooLong(title);

  /// `https://` で始まらないリンクがある。
  bool get linkInvalid => links.any((l) => l.invalid);

  bool get valid => !titleMissing && performance.valid;
}

/// イベントを保存・削除できなかった理由。
enum EventRegisterError {
  /// 必須の項目が足りない。
  requiredMissing,

  /// タイトルが長すぎる。
  titleTooLong,

  /// リンクが `https://` で始まる URL でない。
  linkInvalid,

  /// 同じチケットのページを指すリンクが、ほかのイベントにある。
  duplicateLink,

  /// 保存（削除）に失敗した。
  failed,
}

/// URL を読み取った結果。
enum EventReadResult {
  /// 読み取れた（下書きを入れた）。
  read,

  /// ページを読めなかった・何も読み取れなかった。
  unreadable,

  /// 通信などで失敗した。
  failed,
}

/// イベントの登録の画面に出すもの。
class EventRegisterState {
  const EventRegisterState({this.reading = false});

  /// URL を読み取っているところか。
  final bool reading;
}

/// イベントの登録・編集（画面定義書（設定・発信者向け）2.3.9）。イベントを、リンクと公演ごとまとめて保存する
/// （データ設計書 3.1.17・3.1.18）。
class EventRegisterViewModel extends Notifier<EventRegisterState> {
  EventRegisterViewModel(this.creatorId);

  final String creatorId;

  @override
  EventRegisterState build() => const EventRegisterState();

  /// 編集する [eventId] のイベントを読む。なければ null。読めなければ、例外を投げる。
  Future<Event?> loadEvent(String eventId) async {
    // 読み終えるまで、自動で捨てられないように見張っておく。
    final keep = ref.listen(eventProvider(eventId), (_, _) {});
    try {
      return await ref.read(eventProvider(eventId).future);
    } finally {
      keep.close();
    }
  }

  /// 読み込めなかったイベントを、サインインから読み直す。
  Future<Event?> retryLoadEvent(String eventId) {
    ref.invalidate(authSessionProvider);
    return loadEvent(eventId);
  }

  /// 発信者の名前（チケットサイトで探すの、初めに入れておく名前）。読めなければ空。
  Future<String> creatorName() async {
    // 読み終えるまで、自動で捨てられないように見張っておく（[loadEvent] と同じ）。
    final keep = ref.listen(creatorProvider(creatorId), (_, _) {});
    try {
      return (await ref.read(creatorProvider(creatorId).future))?.name ?? '';
    } catch (_) {
      return '';
    } finally {
      keep.close();
    }
  }

  /// 発信者が開いたページ（[url]）から取り出した部分（[html]）を読み取る（画面定義書 2.3.10）。
  /// 読み取れたら下書き、読めなければ null と理由。
  Future<(EventDraft?, EventReadResult)> read(
    String url, {
    required String html,
  }) async {
    state = const EventRegisterState(reading: true);
    try {
      final draft = await ref
          .read(scheduleRepositoryProvider)
          .readEventUrl(url.trim(), html: html);
      if (draft == null ||
          (draft.title == null && draft.performances.isEmpty)) {
        return (null, EventReadResult.unreadable);
      }
      return (draft, EventReadResult.read);
    } catch (_) {
      return (null, EventReadResult.failed);
    } finally {
      if (ref.mounted) {
        state = const EventRegisterState();
      }
    }
  }

  /// 入力を確かめて、イベントを保存する（[eventId] があれば、そのイベントを書き換える）。
  /// 保存できたら null、できなければ理由。
  Future<EventRegisterError?> save(
    EventRegisterInput input, {
    String? eventId,
  }) async {
    final invalid = checkScheduleInput(
      valid: input.valid,
      titleTooLong: input.titleTooLong,
      linkInvalid: input.linkInvalid,
      requiredMissing: EventRegisterError.requiredMissing,
      tooLong: EventRegisterError.titleTooLong,
      badLink: EventRegisterError.linkInvalid,
    );
    if (invalid != null) return invalid;
    final error = await saveEventOrError(
      () => ref
          .read(scheduleRepositoryProvider)
          .saveEvent(
            id: eventId,
            creatorId: creatorId,
            title: input.title.trim(),
            // 同じチケットのページを指すリンクは1本にする（同じイベントの中の2本どうしで、サーバーの一意に当たるため）。
            links: uniqueEventLinks([
              for (final l in input.links)
                if (!l.empty)
                  EventLink(url: l.url.trim(), isPromotion: l.promotion),
            ]),
            performances: [input.performance.toItem(creatorId)],
          ),
    );
    if (error != null) {
      return switch (error) {
        EventSaveError.duplicateLink => EventRegisterError.duplicateLink,
        EventSaveError.failed => EventRegisterError.failed,
      };
    }
    _refresh(eventId);
    return null;
  }

  /// イベントを消す（リンクと公演も消える）。消せたら null、できなければ理由。
  Future<EventRegisterError?> delete(String eventId) async {
    if (!await succeeded(
      () => ref.read(scheduleRepositoryProvider).deleteEvent(eventId),
    )) {
      return EventRegisterError.failed;
    }
    _refresh(eventId);
    return null;
  }

  /// 予定を出している画面（一覧・スケジュール・カレンダー・発信者ページ・ホーム・イベントの詳細）を読み直す。
  void _refresh(String? eventId) {
    refreshCreatorSchedules(ref, creatorId);
    if (eventId != null) ref.invalidate(eventProvider(eventId));
  }
}

final eventRegisterViewModelProvider = NotifierProvider.autoDispose
    .family<EventRegisterViewModel, EventRegisterState, String>(
      EventRegisterViewModel.new,
    );
