import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/announce_template.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../domain/models/share_link.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../../utils/text_limits.dart';

/// 告知画像の週（届ける・広める仕様書 4.4.1。今週・来週の2つ、月曜から日曜）。
enum AnnounceWeek { thisWeek, nextWeek }

/// 発信者が選んだ画像を、上げる前に縮める長辺（画面定義書（設定・発信者）2.3.15）。
const announcePhotoMaxSide = 1000.0;

/// 告知画像の縦横の比（X に貼る横長 16:9、1600×900。画像はサーバーが作る）。
const announceImageAspectRatio = 16 / 9;

/// [week] の月曜 0 時（端末の時刻）。週は月曜から日曜。
DateTime announceWeekStart(DateTime now, AnnounceWeek week) {
  final today = dateOnly(now.toLocal());
  final monday = today.subtract(
    Duration(days: today.weekday - DateTime.monday),
  );
  return week == AnnounceWeek.nextWeek
      ? DateTime(monday.year, monday.month, monday.day + 7)
      : monday;
}

/// 告知画像に載せるもの。
class AnnounceData {
  const AnnounceData({
    required this.creator,
    required this.weekStart,
    required this.items,
    this.shortUrls = const {},
    this.linkCounts,
  });

  final Creator creator;

  /// 週の月曜 0 時。
  final DateTime weekStart;

  /// その週の予定（予約とイベントの公演）。開始の順。終わった配信（実績）は入れない。
  final List<ScheduleItem> items;

  /// 共有の文のリンクの、元の URL → 追星の短い URL（届ける・広める仕様書 4.4.2）。
  /// 作れなかった URL は入らず、文には元の URL を入れる。
  final Map<String, String> shortUrls;

  /// 短い URL の押された数（元の URL → 回数。届ける・広める仕様書 4.4.2）。読めなければ null。
  final Map<String, int>? linkCounts;

  /// 共有の文に入れるリンク（予定ごとのリンクと、誘う用のリンク）の、元の URL。
  List<String> get shareLinks => {
    for (final item in items) ?scheduleLinkOf(item, creator),
    ShareLink.forCreator(creator.id, invite: true).toString(),
  }.toList();

  /// [url] を、文に入れる形（短い URL があればそれ）にする。
  String linkFor(String url) => shortUrls[url] ?? url;

  /// [weekStart] から数えて [index] 日目（0 が月曜）の予定。
  List<ScheduleItem> itemsOn(int index) {
    final day = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + index,
    );
    return items.where((i) => isSameDay(i.startsAt.toLocal(), day)).toList();
  }
}

/// 告知画像と一緒に渡す文の長さの上限。X の1投稿（280。日本語などの全角は1文字を2、URL は1本 23 と数える）。
/// 共有シートでは行き先が分からないので、一番短い X に合わせる（届ける・広める仕様書 4.4.1）。
const announceTextMaxWeight = 280;

/// 予定の題名を、文では何文字までにするか。超えたら切って「…」を付ける。
const _titleMax = 24;

/// X の数え方での長さ（twitter-text の重み）。URL（http で始まる語）は1本 23。
/// ラテン文字・一部の記号は 1、それ以外（日本語・絵文字など）は 2。
int xWeight(String text) {
  var total = 0;
  for (final word in text.split(RegExp(r'(?<=\s)|(?=\s)'))) {
    if (word.startsWith('http://') || word.startsWith('https://')) {
      total += 23;
      continue;
    }
    for (final rune in word.runes) {
      final light =
          rune <= 0x10FF ||
          (rune >= 0x2000 && rune <= 0x200D) ||
          (rune >= 0x2010 && rune <= 0x201F) ||
          (rune >= 0x2032 && rune <= 0x2037);
      total += light ? 1 : 2;
    }
  }
  return total;
}

/// 予定のリンク。取った配信の予約は、YouTube なら予約の動画のページ、ほかはチャンネルのページ。
/// イベントは、リンク（チケットなど）。リンクが広告（PR）なら、公演のページにする（文に PR と書けないため）。
/// 無ければ null。
String? scheduleLinkOf(ScheduleItem item, Creator creator) {
  if (item.isEvent) {
    final ticket = item.ticketIsPromotion ? null : item.ticketUrl;
    return ticket ?? item.performanceUrl;
  }
  final service = item.service;
  if (service == null) return null;
  final id = item.externalId;
  if (service == SnsService.youtube && item.fetched && id != null) {
    return 'https://youtu.be/$id';
  }
  final account = creator.accounts[service];
  return account == null ? null : service.profileUrl(account).toString();
}

/// 告知画像と一緒に共有する文（届ける・広める仕様書 4.4.1）。
/// 見出し、予定ごとに1行（日付・時刻・題名・リンク）、最後に誘う用のリンク（4.3.6）。
/// リンクの無い予定は入れない（画像に全部載っていて、文はリンクを渡すため）。前の行と同じリンクは、2回目から付けない。
/// [maxWeight] に入りきらない予定は「ほか N 件」にまとめる。誘う用のリンクは必ず残す。
String announceShareText(
  AnnounceData data,
  AppLocalizations l10n, {
  int maxWeight = announceTextMaxWeight,
}) {
  final end = DateTime(
    data.weekStart.year,
    data.weekStart.month,
    data.weekStart.day + 6,
  );
  final header = l10n.announceShareHeading(
    data.creator.name,
    '${monthDay(data.weekStart)}–${monthDay(end)}',
  );
  final invite = [
    l10n.announceShareInvite,
    data.linkFor(
      ShareLink.forCreator(data.creator.id, invite: true).toString(),
    ),
  ].join('\n');
  final seen = <String>{};
  final lines = <String>[];
  for (final item in data.items) {
    final link = scheduleLinkOf(item, data.creator);
    if (link == null) continue;
    final time = item.timeTbd
        ? l10n.commonTimeTbd
        : item.allDay
        ? l10n.commonAllDay
        : clockTime(item.startsAt.toLocal());
    final title = item.title.isEmpty ? l10n.commonLive : item.title;
    final short = graphemeLength(title) > _titleMax
        ? '${clampGraphemes(title, _titleMax - 1)}…'
        : title;
    final date = monthDayWeekday(item.startsAt.toLocal(), l10n);
    lines.add(
      [date, time, short, if (seen.add(link)) data.linkFor(link)].join(' '),
    );
  }
  // 見出し・誘う用のリンクと、行どうしの改行の分を先に取っておく。
  var used = xWeight(header) + 1 + xWeight(invite) + 1;
  final kept = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final rest = lines.length - i - 1;
    final more = rest > 0 ? xWeight(l10n.commonMoreCount(rest)) + 1 : 0;
    if (used + xWeight(lines[i]) + 1 + more > maxWeight) break;
    used += xWeight(lines[i]) + 1;
    kept.add(lines[i]);
  }
  final dropped = lines.length - kept.length;
  return [
    header,
    ...kept,
    if (dropped > 0) l10n.commonMoreCount(dropped),
    '',
    invite,
  ].join('\n');
}

/// 「リンクが押された数」の行（届ける・広める仕様書 4.4.2）。文に入っている、短い URL のリンクだけを、文と同じ順に。
/// 予定は日付と題名、誘う用のリンクは [AppLocalizations.announceLinkInvite]。
List<({String label, int count})> announceLinkRows(
  AnnounceData data,
  AppLocalizations l10n,
) {
  final counts = data.linkCounts;
  if (counts == null) return const [];
  final seen = <String>{};
  final rows = <({String label, int count})>[];
  for (final item in data.items) {
    final link = scheduleLinkOf(item, data.creator);
    if (link == null || !seen.add(link)) continue;
    final count = counts[link];
    if (count == null) continue;
    final title = item.title.isEmpty ? l10n.commonLive : item.title;
    final date = monthDayWeekday(item.startsAt.toLocal(), l10n);
    rows.add((label: '$date $title', count: count));
  }
  final invite = ShareLink.forCreator(data.creator.id, invite: true).toString();
  if (counts[invite] case final count?) {
    rows.add((label: l10n.announceLinkInvite, count: count));
  }
  return rows;
}

/// 告知画像に載せるもの（発信者と週ごと）。
final announceDataProvider = FutureProvider.autoDispose
    .family<AnnounceData, ({String creatorId, AnnounceWeek week})>((
      ref,
      key,
    ) async {
      final creatorRepo = ref.read(creatorRepositoryProvider);
      final creator = await creatorRepo.fetchById(key.creatorId);
      if (creator == null) throw StateError('発信者が見つからない: ${key.creatorId}');
      final start = announceWeekStart(DateTime.now(), key.week);
      final end = DateTime(start.year, start.month, start.day + 7);
      final items = await ref
          .read(scheduleRepositoryProvider)
          .fetchRange([key.creatorId], from: start, until: end);
      final data = AnnounceData(
        creator: creator,
        weekStart: start,
        items: items.where((i) => !i.record).toList(),
      );
      // 共有の文のリンクを、追星の短い URL にする（届ける・広める仕様書 4.4.2）。作れなければ、元の URL のまま。
      try {
        final links = ref.read(creatorLinkRepositoryProvider);
        final shortUrls = await links.shortLinks(creator.id, data.shareLinks);
        // 押された数は、読めなければ出さない（共有は止めない）。
        Map<String, int>? counts;
        try {
          counts = await links.shortLinkCounts(
            creator.id,
            shortUrls.keys.toList(),
          );
        } catch (e) {
          debugPrint('短い URL の押された数を読めない: $e');
        }
        return AnnounceData(
          creator: creator,
          weekStart: start,
          items: data.items,
          shortUrls: shortUrls,
          linkCounts: counts,
        );
      } catch (e) {
        debugPrint('短い URL を作れない（元の URL で文を作る）: $e');
        return data;
      }
    });

/// テンプレの一覧（[lang] の表示名）。取れなければ空（既定のテンプレで作る。画面定義書（設定・発信者）2.3.15）。
final announceTemplatesProvider = FutureProvider.autoDispose
    .family<List<AnnounceTemplate>, String>((ref, lang) async {
      try {
        return await ref
            .read(announceImageRepositoryProvider)
            .fetchTemplates(lang);
      } catch (e) {
        debugPrint('テンプレの一覧を読めない（既定のテンプレで作る）: $e');
        return const [];
      }
    });

/// 発信者が選んだ画像の URL。選んでいなければ null（アイコンを使う）。
final announcePhotoProvider = FutureProvider.autoDispose
    .family<String?, String>(
      (ref, creatorId) =>
          ref.read(announceImageRepositoryProvider).fetchPhoto(creatorId),
    );

/// 告知画像を作る条件。選んだ画像の URL も入れ、画像を変えたら作り直す。
typedef AnnounceImageKey = ({
  String creatorId,
  AnnounceWeek week,
  String templateId,
  String lang,
  String? photoUrl,
});

/// サーバーが作った告知画像（PNG）。
final announceImageProvider = FutureProvider.autoDispose
    .family<Uint8List, AnnounceImageKey>(
      (ref, key) => ref
          .read(announceImageRepositoryProvider)
          .render(
            creatorId: key.creatorId,
            weekStart: announceWeekStart(DateTime.now(), key.week),
            templateId: key.templateId,
            lang: key.lang,
          ),
    );

/// 使うテンプレの ID。覚えた ID が一覧にあればそれ、無ければ一覧の既定、一覧が空なら [AnnounceTemplate.defaultId]。
String announceTemplateIdFor(String? saved, List<AnnounceTemplate> templates) {
  if (saved != null && templates.any((t) => t.id == saved)) return saved;
  return templates.where((t) => t.isDefault).firstOrNull?.id ??
      templates.firstOrNull?.id ??
      AnnounceTemplate.defaultId;
}

/// 画像を変えた結果。
enum AnnouncePhotoResult { changed, cancelled, failed }

/// 告知画像の操作（届ける・広める仕様書 4.4.1）：画像とリンクの共有、テンプレを覚える、画像を変える・戻す。
class AnnounceImageViewModel extends Notifier<void> {
  @override
  void build() {}

  /// 覚えたテンプレの ID（選んでいなければ null）。
  String? get savedTemplateId =>
      ref.read(appPreferencesStoreProvider).announceTemplateId;

  /// 選んだテンプレを覚える（次に開いたときも選ばれたまま）。
  Future<void> saveTemplate(String id) =>
      ref.read(appPreferencesStoreProvider).setAnnounceTemplateId(id);

  /// 端末の写真から1枚選び（長辺 1000 に縮める）、[creatorId] の告知画像に使う。
  Future<AnnouncePhotoResult> changePhoto(String creatorId) async {
    final Uint8List? image;
    try {
      image = await ref
          .read(imagePickerServiceProvider)
          .pickImage(maxSide: announcePhotoMaxSide);
    } catch (e) {
      debugPrint('写真を選べない: $e');
      return AnnouncePhotoResult.failed;
    }
    if (image == null) return AnnouncePhotoResult.cancelled;
    try {
      await ref
          .read(announceImageRepositoryProvider)
          .uploadPhoto(creatorId, image);
      ref.invalidate(announcePhotoProvider(creatorId));
      return AnnouncePhotoResult.changed;
    } catch (e) {
      debugPrint('告知画像の画像を上げられない: $e');
      return AnnouncePhotoResult.failed;
    }
  }

  /// 選んだ画像を外し、アイコンに戻す。外せたら真。
  Future<bool> resetPhoto(String creatorId) async {
    try {
      await ref.read(announceImageRepositoryProvider).deletePhoto(creatorId);
      ref.invalidate(announcePhotoProvider(creatorId));
      return true;
    } catch (e) {
      debugPrint('告知画像の画像を外せない: $e');
      return false;
    }
  }

  /// [png] と [text] を共有シートに渡す。渡せたら真。
  Future<bool> share(
    Uint8List png, {
    required String creatorId,
    required DateTime weekStart,
    String? text,
    Rect? origin,
  }) async {
    try {
      final date =
          '${weekStart.year}${weekStart.month.toString().padLeft(2, '0')}'
          '${weekStart.day.toString().padLeft(2, '0')}';
      await ref
          .read(shareSheetServiceProvider)
          .shareImage(
            png,
            fileName: 'oiboshi-$creatorId-week-$date.png',
            origin: origin,
            text: text,
          );
      return true;
    } catch (e) {
      debugPrint('告知画像を共有できない: $e');
      return false;
    }
  }
}

final announceImageViewModelProvider =
    NotifierProvider<AnnounceImageViewModel, void>(AnnounceImageViewModel.new);
