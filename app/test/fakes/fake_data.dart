import 'dart:async';
import 'dart:typed_data';

import 'package:oiboshi/domain/models/announce_template.dart';
import 'package:oiboshi/domain/models/last_playback.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/creator_link.dart';
import 'package:oiboshi/domain/models/creator_settings.dart';
import 'package:oiboshi/domain/models/creator_type.dart';
import 'package:oiboshi/domain/models/event.dart';
import 'package:oiboshi/domain/models/event_draft.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/instagram_dm.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/domain/models/plan_billing.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/report.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';
import 'package:oiboshi/domain/models/sns_profile.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/domain/models/user_settings.dart';
import 'package:oiboshi/domain/models/want.dart';

/// 画面のテスト用。メモリの上のデータを、本物の Repository と同じ形で返す。
class FakeData {
  final creators = <Creator>[];

  /// 優先のフラグの付いた発信者（おすすめで先に出す）。
  final featured = <String>{};

  /// ファンに見せない（共有のリンクで見せない）発信者の ID（`shared_creator` が行を返さない）。
  final unshareableCreatorIds = <String>{};

  /// おすすめを読んだ回数。
  var recommendCount = 0;

  /// 発信者のタイプの一覧。
  final creatorTypes = <CreatorType>[
    const CreatorType(id: 'game', name: 'ゲーム'),
    const CreatorType(id: 'chat', name: '雑談'),
    const CreatorType(id: 'singing', name: '歌'),
    const CreatorType(id: 'asmr', name: 'ASMR'),
  ];

  /// サーバーに問い合わせた検索の言葉。
  final searches = <String>[];
  final posts = <Post>[];
  final schedules = <ScheduleItem>[];

  /// イベント（ID ごと）。公演は [schedules] の、`eventId` を持つ行。
  final events = <String, Event>{};

  /// チケットの URL ごとの、読み取りの結果（イベントの登録）。
  final eventDrafts = <String, EventDraft>{};

  /// 読み取らせた URL。
  final eventUrlReads = <String>[];

  /// 発信者が開いたページから取り出して、渡された中身。
  final eventPageHtmls = <String>[];

  /// 真なら、URL の読み取りが通信で失敗する。
  bool readEventUrlFails = false;
  final follows = <Follow>[];
  var settings = const UserSettings();
  var displayMode = DisplayMode.system;
  var appLanguage = AppLanguage.system;

  /// ユーザーが固定ビューアのスイッチを切ったか。既定は真にして、起動したときに固定ビューアを出さない
  /// （固定ビューアの初めの状態を見るテストだけ、偽にする）。
  var fixedViewerUserOff = true;

  /// 固定ビューアで最後に流していたもの（端末内）。
  LastPlayback? lastPlayback;
  var onboardingDone = false;

  /// 初回起動の引き継ぎで、クリップボードを確かめたか。
  var clipboardLinkChecked = false;

  /// 真なら、初回起動を済ませた印の保存が失敗する。
  bool failOnboardingSave = false;
  String? ownedCreatorId;

  /// 端末のセッションのユーザー ID の移り変わり。テストから、ログインの処理を通らない切り替わりを起こすのに使う。
  final sessionUserChanges = StreamController<String?>.broadcast();

  /// 端末のセッションを、[id] のユーザーに切り替える（ログインの処理を通らない切り替わり）。
  void switchSessionUser(String id) {
    userId = id;
    sessionUserChanges.add(id);
  }

  /// アカウント連携の結果。連携できたら、`{SNS}_linked` を確認済みで入れる。
  var linkResult = AccountLinkResult.linked;

  /// 発信者として登録の手順で連携した、登録待ちのアカウント。
  final pendingLinks = <SnsService, CreatorAccount>{};

  /// 結び付いたログイン方法。空なら、匿名のユーザー。
  final loginMethods = <LoginMethod>[];

  /// ログイン・結び付けの結果。
  var loginResult = LoginResult.done;

  /// 結び付けたログインで入る（ユーザーの切り替え）結果。null なら [loginResult]。
  LoginResult? signInResult;

  /// 結び付けたログインで入ろうとした方法。
  final signInProviders = <LoginProvider>[];

  /// ログイン先のユーザーが、もとから持つフォローと表示しない発信者。ログインで切り替わると、これに入れ替わる。
  final signInFollows = <Follow>[];
  final signInHiddenCreatorIds = <String>[];

  /// アプリ運営用ログインで入れるアカウント（メールアドレス → パスワード）。入ると、ユーザーは `user-admin` になる。
  final passwordAccounts = <String, String>{};

  /// アプリ運営用ログインの、端末の回数の制限（端末内の保存）。
  var passwordLoginLock = const PasswordLoginLock();

  /// 真なら、アプリ運営用ログインで、サーバーの回数の制限にかかる。
  var passwordServerRateLimited = false;

  /// 真なら、フォローの足し合わせの券を受け取れない。
  var startMergeFails = false;

  /// 受け取った券と、移した券。
  final mergeTokens = <String>[];
  final finishedMergeTokens = <String>[];

  /// 券ごとの、匿名のユーザーのフォローと表示しない発信者（足し合わせの元）。
  final mergeSources = <String, (List<Follow>, List<String>)>{};

  /// いまのユーザー ID。null なら、サインインしていない。
  String? userId = 'user-a';

  /// 再認証の結果と、求めた回数。
  var reauthResult = LoginResult.done;
  var reauthCount = 0;

  /// 再認証で使ったログイン方法。
  final reauthProviders = <LoginProvider>[];

  /// 退会で取り消した、Apple の一時的なコード。取り消さなければ null。
  String? revokedAppleCode;

  /// 退会を失敗させる。
  var withdrawFails = false;

  /// 発信者の登録の結果。
  var registerResult = RegisterResult.registered;

  /// 登録のあとの、画像のアップロードを失敗させる。
  var registerUploadFails = false;

  /// 登録で渡されたアイコンとカバー。
  Uint8List? registeredAvatar;
  Uint8List? registeredCover;

  /// Storage から消した、ファンのカバー画像（発信者 ID）。
  final removedCovers = <String>[];

  /// 取り戻せる発信者（オーナーが退会した発信者）。取り戻すと、オーナーになる。
  final reclaimable = <ReclaimableCreator>[];

  /// 取り戻しの結果。
  var reclaimResult = ReclaimResult.reclaimed;

  /// SNS から取り込むプロフィール。null なら、取り込みに失敗する。
  SnsProfileDraft? Function(SnsService service)? profileDraft;

  /// 取り込みの回数の上限を超えているか。
  var profileImportLimited = false;

  /// この端末で課金を使えるか（RevenueCat のキーがあるか）。
  var billingAvailable = true;

  /// ストアの X連携プランの価格（日本の App Store と同じ）と、読み込みを失敗させるか。
  var xOptionPrice = const PlanPrice(
    amount: 290,
    currencyCode: 'JPY',
    formatted: '¥290',
  );
  var offerFails = false;

  /// ストアの購入から決まる、いまの加入。
  var subscription = PlanSubscription.none;

  /// 購入の結果。買えたら、[subscription] を X連携プランに加入中にする。
  var purchaseResult = PlanPurchaseResult.purchased;

  /// 買った回数と、RevenueCat にそろえたユーザー。
  var purchases = 0;
  final billingUsers = <String>[];

  /// 購入を復元したときに見つかる加入。
  var restorable = PlanSubscription.none;

  /// サーバーの加入を書き直させた回数と、それを失敗させるか。
  var subscriptionSyncs = 0;
  var subscriptionSyncFails = false;

  /// サーバーの加入を書き直させたときに、サーバーの値（発信者の休止中など）を変える。
  void Function()? onSubscriptionSync;

  /// サーバーに書いた加入の期限（`plan_subscriptions`）と、それを読めなくするか。
  var serverSubscription = ServerPlanSubscription.none;
  var serverSubscriptionFails = false;

  /// 自分がオーナーの発信者を読んだ回数。
  var ownedCreatorReads = 0;

  /// 予定（カレンダー予定）の登録・書き換え・削除を失敗させるか（失敗したときは、何も書かない）。
  var scheduleWriteFails = false;

  /// true のとき、読み取りを失敗させる。
  bool failReads = false;

  /// 真なら、ログイン方法の読み込みが通信で失敗する。
  bool failLoginMethods = false;

  /// 完了するまで、サインインを待たせる（「もう一度試す」のあとの読み込み中を確かめる）。
  Completer<void>? signInGate;

  /// タイムラインを読んだときの、続きの位置（最新を読んだときは null）。
  final timelineReads = <Post?>[];

  /// 投稿を隠す・また出すのを失敗させる。
  var hidePostFails = false;

  /// 発信者が隠した投稿の ID（機能仕様書 4.4.4）。[posts] にあっても、ファンの読み取りでは返さない。
  final hiddenPostIds = <String>{};

  /// 表示しない発信者の ID（表示しないにした順）。
  final hiddenCreatorIds = <String>[];

  /// 表示しない発信者の書き込みを失敗させる。
  var hiddenWriteFails = false;

  /// フォローを外すのを失敗させる。
  var unfollowFails = false;

  /// 送った通報（対象・理由・詳しい内容）。
  final reports = <(ReportTarget, ReportReason, String)>[];

  /// 通報の結果。
  var reportResult = ReportResult.submitted;

  /// 発信者ごとのリンク集（並び順。押された回数つき）。
  final creatorLinks = <String, List<CreatorLink>>{};

  /// 作った短い URL（元の URL → ID）。告知の共有の文（届ける・広める仕様書 4.4.2）。
  final shortLinkIds = <String, String>{};

  /// 短い URL の押された数（元の URL → 回数）。
  final shortLinkClicks = <String, int>{};

  /// 真なら、短い URL を作れない（通信の失敗の代わり）。
  var shortLinksFail = false;

  /// 週間の告知画像のテンプレの一覧（サーバーの代わり）。
  var announceTemplates = <AnnounceTemplate>[
    const AnnounceTemplate(
      id: 'spotlight',
      name: 'スポットライト',
      thumbnailUrl: 'https://f.example/thumbnail/spotlight',
      isDefault: true,
    ),
  ];

  /// 真なら、テンプレの一覧を読めない。
  var announceTemplatesFail = false;

  /// 発信者が選んだ告知画像の画像（発信者 ID → URL）。
  final announcePhotos = <String, String>{};

  /// サーバーに告知画像を作らせた条件。
  final announceRenders =
      <
        ({
          String creatorId,
          DateTime weekStart,
          String templateId,
          String? photo,
        })
      >[];

  /// 真なら、告知画像を作れない。
  var announceRenderFail = false;

  /// あれば、告知画像を作るのを、これが終わるまで待たせる（作っている間の表示の確かめ）。
  Completer<void>? announceRenderGate;

  /// 真なら、選んだ画像を上げられない。
  var announcePhotoFail = false;

  /// 押されたリンクの ID（押した順）。
  final linkClicks = <String>[];

  /// 自分が押した追いたい（新しい順）。
  final wants = <Want>[];

  /// 追いたいを押した結果を決める。null なら、[wants] に足す。
  WantResult? wantResult;

  /// 確認済みのアカウント（`SNS:ID`）と、その発信者 ID。押すと、追いたいにせず発信者を返す。
  final wantRegistered = <String, String>{};

  /// 追いたいの取り消しを失敗させる。
  var wantCancelFails = false;

  /// 【仮】Instagram の DM での確認の受け先。null なら、DM の手順を使わない。
  String? instagramDmAccount;

  /// 【仮】出したコード（発信者 ID。登録の手順は null）と、コードを出した結果。
  final instagramDmRequests = <String?, InstagramDmRequest>{};
  var instagramDmResult = InstagramDmRequestResult.requested;

  /// 【仮】DM の確認の状態を読むのに失敗する。
  bool instagramDmFails = false;

  void check() {
    if (failReads) throw const AppException(AppErrorKind.network);
  }
}
