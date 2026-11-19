import 'sns_service.dart';

/// 自分が押した追いたい（機能仕様書（届ける・広める）4.5.1。サーバーの `my_wants` の1行）。
/// 持つのは SNS の種別と ID と押した人数だけ。名前やアイコンは持たない。
class Want {
  const Want({
    required this.wantedAccountId,
    required this.service,
    required this.account,
    required this.wantCount,
    required this.wantedAt,
  });

  /// 取り消しに使う、未登録のアカウントの ID。
  final String wantedAccountId;
  final SnsService service;

  /// そろえた ID（YouTube のハンドルは `@` 付き、チャンネル ID は `UC` で始まる）。
  final String account;

  /// 押した人数（自分を含む）。
  final int wantCount;
  final DateTime wantedAt;

  /// 画面に出す ID。
  String get displayAccount => displayWantAccount(service, account);

  /// サーバーの1行から作る。知らない SNS なら null。
  static Want? fromRow(Map<String, dynamic> row) {
    final service = SnsService.fromName(row['service'] as String?);
    if (service == null) return null;
    return Want(
      wantedAccountId: row['wanted_account_id'] as String,
      service: service,
      account: row['account'] as String,
      wantCount: (row['want_count'] as num).toInt(),
      wantedAt: DateTime.parse(row['wanted_at'] as String),
    );
  }
}

/// 画面に出す ID。YouTube はそのまま（ハンドルは `@` 付き、チャンネル ID は付けない）、ほかは `@` を付ける。
String displayWantAccount(SnsService service, String account) =>
    service == SnsService.youtube ? account : '@$account';

/// 追いたいを押した結果。
sealed class WantResult {
  const WantResult();

  /// サーバーの `want_account` の結果から作る。
  static WantResult fromServer(Map<String, dynamic> value) =>
      switch (value['result']) {
        'wanted' => WantAdded((value['count'] as num).toInt()),
        'registered' => WantRegistered(value['creator_id'] as String),
        'limit' => const WantLimit(),
        'invalid' => const WantInvalid(),
        _ => const WantFailed(),
      };
}

/// 押した（もう押していたときも）。[count] は押した人数。
class WantAdded extends WantResult {
  const WantAdded(this.count);
  final int count;
}

/// 追星にいる発信者の、確認済みのアカウントだった。
class WantRegistered extends WantResult {
  const WantRegistered(this.creatorId);
  final String creatorId;
}

/// 今日の申告の上限（10件）に達した。
class WantLimit extends WantResult {
  const WantLimit();
}

/// URL・ID の形が分からない。
class WantInvalid extends WantResult {
  const WantInvalid();
}

/// 送れなかった。
class WantFailed extends WantResult {
  const WantFailed();
}
