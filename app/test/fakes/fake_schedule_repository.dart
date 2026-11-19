import 'dart:async';

import 'package:oiboshi/data/repositories/schedule/schedule_repository.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:oiboshi/domain/models/event_url_key.dart';
import 'package:oiboshi/domain/models/event.dart';
import 'package:oiboshi/domain/models/event_draft.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';

import 'fake_data.dart';

class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository(this.data);

  final FakeData data;

  /// [fetchRange] で読んだ範囲の始まり。読んだ回数と、範囲が変わったかを見る。
  final fetchedFrom = <DateTime>[];

  @override
  Future<ScheduleItem?> fetchSchedule(String id) async {
    data.check();
    return data.schedules.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<List<ScheduleItem>> fetchRange(
    List<String> creatorIds, {
    required DateTime from,
    required DateTime until,
    bool includeOngoing = false,
  }) async {
    data.check();
    fetchedFrom.add(from);
    return data.schedules
        .where(
          (s) =>
              creatorIds.contains(s.creatorId) &&
              (!s.startsAt.isBefore(from) ||
                  (includeOngoing &&
                      s.endsAt != null &&
                      !s.endsAt!.isBefore(from))) &&
              s.startsAt.isBefore(until),
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<List<ScheduleItem>> fetchCreatorPerformances(String creatorId) async {
    data.check();
    return data.schedules
        .where((s) => s.creatorId == creatorId && !s.fetched)
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  void _checkWrite() {
    if (data.scheduleWriteFails) {
      throw const AppException(AppErrorKind.network);
    }
  }

  @override
  Future<Event?> fetchEvent(String id) async {
    data.check();
    final e = data.events[id];
    if (e == null) return null;
    return Event(
      id: e.id,
      creatorId: e.creatorId,
      title: e.title,
      links: e.links,
      performances: data.schedules.where((s) => s.eventId == id).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
    );
  }

  /// データベースと同じく、公演を予定の行にし、タイトルと1本目のリンクを写す。
  /// 同じ URL のリンクが、同じ発信者のほかのイベントにあれば、登録済みとして断る。
  @override
  Future<String> saveEvent({
    String? id,
    required String creatorId,
    required String title,
    required List<EventLink> links,
    required List<ScheduleItem> performances,
  }) async {
    if (data.scheduleWriteFails) {
      throw const EventSaveException(EventSaveError.failed);
    }
    final taken = {
      for (final e in data.events.values)
        if (e.creatorId == creatorId && e.id != id)
          for (final l in e.links) l.url,
    };
    if (links.any((l) => taken.contains(l.url))) {
      throw const EventSaveException(EventSaveError.duplicateLink);
    }
    // データベースと同じく、同じイベントの中でも、同じチケットのページを指すリンクは2本入れられない。
    if ({for (final l in links) eventUrlKey(l.url)}.length != links.length) {
      throw const EventSaveException(EventSaveError.duplicateLink);
    }
    final eventId = id ?? 'event${data.events.length + 1}';
    data.events[eventId] = Event(
      id: eventId,
      creatorId: creatorId,
      title: title,
      links: links,
      performances: const [],
    );
    data.schedules.removeWhere((s) => s.eventId == eventId);
    final first = links.firstOrNull;
    for (final p in performances) {
      data.schedules.add(
        ScheduleItem(
          id: 'perf${data.schedules.length + 1}',
          creatorId: creatorId,
          title: title,
          startsAt: p.startsAt,
          endsAt: p.endsAt,
          allDay: p.allDay,
          venue: p.venue,
          ticketUrl: p.performanceUrl ?? first?.url,
          ticketIsPromotion: p.performanceUrl == null
              ? first?.isPromotion ?? false
              : false,
          eventId: eventId,
          performanceUrl: p.performanceUrl,
        ),
      );
    }
    return eventId;
  }

  @override
  Future<void> deleteEvent(String id) async {
    _checkWrite();
    data.events.remove(id);
    data.schedules.removeWhere((s) => s.eventId == id);
  }

  @override
  Future<Set<String>> registeredEventUrls(
    String creatorId,
    List<String> urls,
  ) async {
    data.check();
    final taken = {
      for (final e in data.events.values)
        if (e.creatorId == creatorId)
          for (final l in e.links) l.url,
    };
    return urls.where(taken.contains).toSet();
  }

  /// [FakeData.eventDrafts] にある URL なら、その下書きを返す。なければ、読めなかったとする。
  @override
  Future<EventDraft?> readEventUrl(String url, {required String html}) async {
    data.eventUrlReads.add(url);
    data.eventPageHtmls.add(html);
    if (data.readEventUrlFails) throw const AppException(AppErrorKind.network);
    return data.eventDrafts[url];
  }
}
