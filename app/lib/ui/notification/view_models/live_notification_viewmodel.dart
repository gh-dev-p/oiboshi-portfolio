import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/live_notification.dart';
import '../../../domain/models/schedule_item.dart';

/// プッシュ通知（配信開始・予定の事前通知）を受けた出来事。[opened] は、通知を押して開いたか（偽なら、アプリを開いているときに届いた）。
class LiveNotificationEvent {
  const LiveNotificationEvent(this.notification, {required this.opened});

  final LiveNotification notification;
  final bool opened;
}

/// 配信開始の通知を受けた出来事を、状態として公開する（アーキテクチャ設計書 2.2）。
/// アプリの土台（`app.dart`）が起動したときから監視し続け、初回起動の画面にいるあいだの出来事も残す。
/// ホームの枠が監視し、発信者ページを開くかスナックバーを出して、[consume] で消す。
class LiveNotificationViewModel extends Notifier<LiveNotificationEvent?> {
  @override
  LiveNotificationEvent? build() {
    final repo = ref.watch(notificationRepositoryProvider);
    final subs = [
      repo.openedNotifications.listen(_opened),
      repo.foregroundNotifications.listen((n) {
        // ホームで受け取る前の、押した出来事は、あとで届いたもので消さない（機能仕様書 4.3.3）。
        if (state?.opened ?? false) return;
        state = LiveNotificationEvent(n, opened: false);
      }),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });
    // アプリが終わっていたときに、通知を押して開いた。
    unawaited(
      repo
          .initialOpenedNotification()
          .then((n) {
            if (n != null && ref.mounted) _opened(n);
          })
          .catchError((_) {}),
    );
    return null;
  }

  /// 通知を押して開いた。発信者に見せる数に「通知から開いた」を記録する（届ける・広める仕様書 4.2.1。送れなくても止めない）。
  void _opened(LiveNotification n) {
    state = LiveNotificationEvent(n, opened: true);
    unawaited(
      ref
          .read(reachRepositoryProvider)
          .recordOpened(
            n.creatorId,
            scheduleId: n.scheduleId,
            liveService: n.service,
            liveId: n.liveId,
          ),
    );
  }

  /// 出来事を扱い終えた。
  void consume() => state = null;

  /// 予定の事前通知で開く予定と発信者（届ける・広める仕様書 4.1.1）。予定が消えていれば [item] は null。
  /// 発信者が読めなければ null（呼んだ側は発信者ページを開き、そこで失敗を出す）。
  Future<({ScheduleItem? item, Creator creator})?> loadSchedule(
    String creatorId,
    String scheduleId,
  ) async {
    try {
      final creator = await ref
          .read(creatorRepositoryProvider)
          .fetchById(creatorId);
      if (creator == null) return null;
      final item = await ref
          .read(scheduleRepositoryProvider)
          .fetchSchedule(scheduleId);
      return (
        item: item?.creatorId == creatorId ? item : null,
        creator: creator,
      );
    } catch (e) {
      debugPrint('予定の通知の予定を読めない: $e');
      return null;
    }
  }
}

final liveNotificationViewModelProvider =
    NotifierProvider<LiveNotificationViewModel, LiveNotificationEvent?>(
      LiveNotificationViewModel.new,
    );
