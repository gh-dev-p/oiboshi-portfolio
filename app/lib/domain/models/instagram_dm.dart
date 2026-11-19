// 【仮】Instagram の DM での確認（機能仕様書 4.6.2.1）。
// Meta の審査が通るまでの、一時的な仕組み。通ったら、このファイルごと外す。

/// 出したコード。`instagram_dm_requests` テーブルの1行。
class InstagramDmRequest {
  const InstagramDmRequest({
    required this.id,
    required this.account,
    required this.code,
    required this.createdAt,
  });

  factory InstagramDmRequest.fromRow(Map<String, dynamic> row) =>
      InstagramDmRequest(
        id: row['id'] as String,
        account: row['account'] as String,
        code: row['code'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  /// コードの期限（サーバーの `request_instagram_dm`・`approve_instagram_dm` と合わせる）。
  static const lifetime = Duration(days: 7);

  final String id;

  /// 確かめる Instagram のユーザー名。
  final String account;
  final String code;
  final DateTime createdAt;

  DateTime get expiresAt => createdAt.add(lifetime);
}

/// DM の確認の状態。
class InstagramDmState {
  const InstagramDmState({this.dmAccount, this.request});

  /// DM の受け先の Instagram のユーザー名。null なら、DM の手順は使わない（Instagram のログインで確かめる）。
  final String? dmAccount;

  /// 確かめを待っているコード。
  final InstagramDmRequest? request;

  bool get enabled => dmAccount != null;
}

/// コードを出した結果。
enum InstagramDmRequestResult {
  requested,

  /// ユーザー名の形が違う。
  invalid,

  /// ほかの発信者で確認済みのアカウント。
  duplicate,

  /// DM の手順を止めた・オーナーでない・通信の失敗。
  failed;

  /// サーバーが返す `result`（関数 `request_instagram_dm`）から引く。
  static InstagramDmRequestResult fromServer(String? value) => switch (value) {
    'requested' => requested,
    'invalid' => invalid,
    'duplicate' => duplicate,
    _ => failed,
  };
}
