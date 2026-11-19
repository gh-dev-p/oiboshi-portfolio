/// プッシュ通知（サーバーが `data` に入れた値から作る）。配信開始の通知（機能仕様書 4.3.3）、
/// 予定の事前通知（届ける・広める仕様書 4.1.1）、追いたいの人の登録の通知（4.5.2）。
/// 予定の事前通知なら [scheduleId] があり、追いたいの人の登録の通知なら [wantArrival] が真。
class LiveNotification {
  const LiveNotification({
    required this.creatorId,
    required this.title,
    required this.body,
    this.scheduleId,
    this.service,
    this.liveId,
    this.wantArrival = false,
  });

  final String creatorId;

  /// 通知のタイトル（「{発信者の名前}が配信を始めました」「{発信者の名前}の予定」など）。
  final String title;

  /// 通知の本文（配信のタイトル、予定の時刻とタイトルなど）。
  final String body;

  /// 予定の事前通知の、予定の ID。ほかの通知なら null。
  final String? scheduleId;

  /// 配信開始の通知の、配信のサービスと配信 ID（発信者に見せる数の対象。届ける・広める仕様書 4.2.1）。
  final String? service;
  final String? liveId;

  /// 追いたいの人の登録の通知か（押したら、その発信者ページを開く）。
  final bool wantArrival;

  /// 通知の `data` から作る。上の3種類でなければ null。
  static LiveNotification? fromMessage(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final creatorId = data['creator_id'];
    if (creatorId is! String || creatorId.isEmpty) return null;
    String? scheduleId;
    var wantArrival = false;
    switch (data['type']) {
      case 'live_start':
        break;
      case 'want_arrival':
        wantArrival = true;
      case 'schedule_notice':
        final id = data['schedule_id'];
        if (id is! String || id.isEmpty) return null;
        scheduleId = id;
      default:
        return null;
    }
    return LiveNotification(
      creatorId: creatorId,
      title: title ?? '',
      body: body ?? '',
      scheduleId: scheduleId,
      service: data['service'] is String ? data['service'] as String : null,
      liveId: data['live_id'] is String ? data['live_id'] as String : null,
      wantArrival: wantArrival,
    );
  }
}
