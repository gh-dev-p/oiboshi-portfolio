import '../../utils/server_time.dart';
import 'creator.dart';
import 'sns_service.dart';

/// 追星に出す内容の選択。`creator_displays` テーブルの1行。
class CreatorDisplay {
  const CreatorDisplay({
    required this.service,
    required this.content,
    required this.enabled,
  });

  factory CreatorDisplay.fromRow(Map<String, dynamic> row) => CreatorDisplay(
    service: SnsService.fromName(row['service'] as String)!,
    content: DisplayContent.fromName(row['content'] as String)!,
    enabled: (row['enabled'] as bool?) ?? true,
  );

  final SnsService service;
  final DisplayContent content;
  final bool enabled;
}

/// アカウント連携の結果（機能仕様書 4.6.2）。
enum AccountLinkResult {
  linked,

  /// オーナーが退会した発信者のアカウント（登録の手順から）。登録待ちの連携に入り、その発信者を取り戻せる（4.6.1.2）。
  reclaimable,

  /// ほかの発信者で確認済みのアカウント。
  duplicate,

  /// SNS の画面で、許可しなかった・閉じた。
  cancelled,

  /// YouTube のチャンネルがない Google アカウント。
  noChannel,

  /// 時間切れ・通信の失敗・SNS の失敗。
  failed;

  /// サーバーが戻す `result`（`_shared/account_link.ts` の `LinkResult`）から引く。
  static AccountLinkResult fromServer(String? value) => switch (value) {
    'linked' => linked,
    'reclaimable' => reclaimable,
    'duplicate' => duplicate,
    'cancelled' || null => cancelled,
    'no_channel' => noChannel,
    _ => failed,
  };
}

/// 発信者の登録の結果（機能仕様書 4.6.1）。
enum RegisterResult {
  registered,

  /// 登録できたが、そのあとのアイコン・カバー・タイプの保存に失敗した（プロフィールの編集で直してもらう）。
  registeredPartially,

  /// ID が、ほかの発信者で使われている。
  idTaken,

  /// 連携したアカウントが、その間にほかの発信者で確認済みになった。
  duplicate,

  /// 受付を閉じている（課金をつなぐまで）。
  closed,

  /// 登録待ちの連携がない・すでにオーナー・そのほかの失敗。
  failed;

  /// サーバー（Edge Function `register-creator`）の結果から引く。
  static RegisterResult fromServer(String? value) => switch (value) {
    'registered' => registered,
    'id_taken' => idTaken,
    'duplicate' => duplicate,
    'registration_closed' => closed,
    _ => failed,
  };

  /// 登録できたか（プロフィールの一部を保存できなかったときを含む）。
  bool get isRegistered => this == registered || this == registeredPartially;
}

/// 取り戻し（機能仕様書 4.6.1.2）の結果。
enum ReclaimResult {
  reclaimed,

  /// 猶予の90日を過ぎた・ほかの人が取り戻した・連携したアカウントが違う。
  notReclaimable,

  /// 連携したアカウントが、その間にほかの発信者で確認済みになった。
  duplicate,

  /// 受付を閉じている。
  closed,

  /// すでにオーナー・そのほかの失敗。
  failed;

  /// サーバー（Edge Function `reclaim-creator`）の結果から引く。
  static ReclaimResult fromServer(String? value) => switch (value) {
    'reclaimed' => reclaimed,
    'not_reclaimable' => notReclaimable,
    'duplicate' => duplicate,
    'registration_closed' => closed,
    _ => failed,
  };
}

/// 取り戻せる発信者（`reclaimable_creators` の1行）。オーナーが退会して、ファンには見えていない。
class ReclaimableCreator {
  const ReclaimableCreator({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.purgeAt,
    this.plan = CreatorPlan.standard,
  });

  factory ReclaimableCreator.fromRow(Map<String, dynamic> row) =>
      ReclaimableCreator(
        id: row['id'] as String,
        name: row['name'] as String,
        avatarUrl: row['avatar_url'] as String?,
        purgeAt: parseTime(row['purge_at'] as String)!,
        plan: CreatorPlan.fromName(row['plan'] as String?),
      );

  final String id;
  final String name;
  final String? avatarUrl;

  /// 消える時刻（オーナーが退会した90日後）。これより前なら、取り戻せる。
  final DateTime purgeAt;

  /// プランの種類。永年無料・運営・確認用なら、取り戻すのに加入が要らない（機能仕様書 4.6.1.2）。
  final CreatorPlan plan;
}

/// 発信者の ID の形（英小文字・数字・`_`・`-` の1〜40文字）。
final creatorIdPattern = RegExp(r'^[a-z0-9_-]{1,40}$');
