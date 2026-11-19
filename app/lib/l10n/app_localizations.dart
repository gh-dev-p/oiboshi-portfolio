import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// アプリの名前（MaterialApp.title）
  ///
  /// In ja, this message translates to:
  /// **'追星'**
  String get appTitle;

  /// 起動時のエラーの画面（bootstrap.dart）
  ///
  /// In ja, this message translates to:
  /// **'起動できませんでした'**
  String get startupErrorTitle;

  /// 共通：キャンセルのボタン
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get commonCancel;

  /// 共通：閉じるのボタン
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get commonClose;

  /// 共通：保存のボタン
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// 共通：戻るのボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get commonBack;

  /// 共通：検索フィールドのプレースホルダ
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get commonSearch;

  /// 共通：スナックバーの再試行
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get commonRetry;

  /// 共通：読み込みの失敗のときのボタン（StateView）
  ///
  /// In ja, this message translates to:
  /// **'もう一度試す'**
  String get commonTryAgain;

  /// 共通：検索の結果が0件
  ///
  /// In ja, this message translates to:
  /// **'見つかりませんでした'**
  String get commonNotFound;

  /// 共通：外部のページを開けなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'ページを開けませんでした'**
  String get commonPageOpenFailed;

  /// 共通：読み直しの失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'更新できませんでした'**
  String get commonRefreshFailed;

  /// 共通：読み込みの失敗の見出し（StateView）
  ///
  /// In ja, this message translates to:
  /// **'読み込めませんでした'**
  String get commonLoadFailedTitle;

  /// 共通：読み込みの失敗の説明（StateView）
  ///
  /// In ja, this message translates to:
  /// **'通信の状態を確認して、もう一度お試しください。'**
  String get commonLoadFailedMessage;

  /// 共通：保存の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'保存できませんでした'**
  String get commonSaveFailed;

  /// 共通：設定の変更の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'設定を変えられませんでした'**
  String get commonSettingChangeFailed;

  /// 共通：通知の設定の変更の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'通知の設定を変えられませんでした'**
  String get commonNotificationSettingChangeFailed;

  /// 共通：フォローのボタン（未フォロー）
  ///
  /// In ja, this message translates to:
  /// **'フォロー'**
  String get commonFollow;

  /// 共通：フォローのボタン（フォロー中）
  ///
  /// In ja, this message translates to:
  /// **'フォロー中'**
  String get commonFollowing;

  /// 共通：フォローの変更の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'フォローを変えられませんでした'**
  String get commonFollowChangeFailed;

  /// 共通：下部ナビのタブの読み上げの名前（ホーム）
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get commonTabHome;

  /// 共通：下部ナビのタブの読み上げの名前（スケジュール）
  ///
  /// In ja, this message translates to:
  /// **'スケジュール'**
  String get commonTabSchedule;

  /// 共通：下部ナビのタブの読み上げの名前（推しリスト）
  ///
  /// In ja, this message translates to:
  /// **'推しリスト'**
  String get commonTabOshiList;

  /// 共通：下部ナビの設定のタブ（読み上げの名前）
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get commonTabSettings;

  /// 共通：下部ナビの、固定ビューアを出す・消すスイッチ（読み上げ）
  ///
  /// In ja, this message translates to:
  /// **'固定ビューア'**
  String get commonFixedViewer;

  /// 共通：固定ビューアの帯の、推しの動画から配信中の推しの配信に切り替えるボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'配信に切り替える'**
  String get commonFixedViewerPlayLive;

  /// 固定ビューア：スイッチを入れたのに、流す配信・動画がないときの案内
  ///
  /// In ja, this message translates to:
  /// **'配信や動画を投稿している推しを見つけよう'**
  String get fixedViewerEmptyMessage;

  /// 固定ビューア：配信を流すようになったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'配信モードに切り替えました'**
  String get fixedViewerModeLive;

  /// 固定ビューア：下部ナビのスイッチを引っ張って配信に切り替えようとしたが、配信中の推しがいないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'配信中の推しはいません'**
  String get fixedViewerNoLive;

  /// 固定ビューア：下部ナビのコントローラーの長押しのヒント（上へはじくと流す）の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'再生'**
  String get fixedViewerControlPlay;

  /// 固定ビューア：下部ナビのコントローラーの長押しのヒント（上へはじくと止める）の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'停止'**
  String get fixedViewerControlPause;

  /// 固定ビューア：下部ナビのコントローラーの長押しのヒント（右へはじくと次の動画・配信）の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get fixedViewerControlNext;

  /// 固定ビューア：下部ナビのコントローラーの長押しのヒント（左へはじくと前の動画・配信）の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'前へ'**
  String get fixedViewerControlPrevious;

  /// 固定ビューア：下部ナビのコントローラーで止めたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'停止しました'**
  String get fixedViewerPaused;

  /// 固定ビューア：下部ナビのコントローラーで流し直したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'再生を再開しました'**
  String get fixedViewerResumed;

  /// 固定ビューア：推しの動画のランダム再生を流すようになったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'動画シャッフルモードに切り替えました'**
  String get fixedViewerModeShuffle;

  /// 固定ビューア：流していた配信が終わり、推しの動画のランダム再生に移ったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'配信が終わりました。動画シャッフルモードに切り替えました'**
  String get fixedViewerLiveEndedShuffle;

  /// 共通：値が未設定
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get commonNotSet;

  /// 共通：今日
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get commonToday;

  /// 共通：明日
  ///
  /// In ja, this message translates to:
  /// **'明日'**
  String get commonTomorrow;

  /// 共通：時刻のない予定
  ///
  /// In ja, this message translates to:
  /// **'終日'**
  String get commonAllDay;

  /// 共通：生配信（コンテンツの種類）。タイトルのない配信の表示名にも使う
  ///
  /// In ja, this message translates to:
  /// **'配信'**
  String get commonLive;

  /// 共通：投稿（コンテンツの種類）
  ///
  /// In ja, this message translates to:
  /// **'投稿'**
  String get commonPost;

  /// 共通：投稿が0件
  ///
  /// In ja, this message translates to:
  /// **'まだ投稿がありません'**
  String get commonNoPostsYet;

  /// 共通：まだ対応していないプラットフォームの印
  ///
  /// In ja, this message translates to:
  /// **'準備中'**
  String get commonComingSoon;

  /// 共通：運営が停止した発信者のチップ
  ///
  /// In ja, this message translates to:
  /// **'停止中'**
  String get commonSuspended;

  /// 共通：発信者ページへのボタン
  ///
  /// In ja, this message translates to:
  /// **'発信者のページを開く'**
  String get commonOpenCreatorPage;

  /// 固定ビューア：投稿の動画の帯の、ビューアで開くボタン
  ///
  /// In ja, this message translates to:
  /// **'投稿を開く'**
  String get commonOpenPost;

  /// 予定の種類の印（イベントの公演）。予定の詳細（シート）に出す
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get commonEvent;

  /// 共通：リンク
  ///
  /// In ja, this message translates to:
  /// **'リンク'**
  String get commonLink;

  /// 共通：イベントの公演のリンク（ファンに見せるところ）
  ///
  /// In ja, this message translates to:
  /// **'チケット'**
  String get commonTicket;

  /// 予定の詳細：イベントの公演のリンクを開くボタン
  ///
  /// In ja, this message translates to:
  /// **'チケットを見る'**
  String get scheduleDetailOpenTicket;

  /// 共通：埋め込みビューアの配信や、投稿ビューアの動画を、固定ビューアで流すボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'固定ビューアで流す'**
  String get commonLivePin;

  /// 共通：配信ビューアを前の推しの配信に切り替える矢印（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'前の配信'**
  String get commonLivePrevious;

  /// 共通：配信ビューアを次の推しの配信に切り替える矢印（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'次の配信'**
  String get commonLiveNext;

  /// 共通：配信ビューアの帯の推しのアイコン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'発信者ページを開く'**
  String get commonLiveOpenCreator;

  /// 相対時刻：1分未満
  ///
  /// In ja, this message translates to:
  /// **'たった今'**
  String get timeJustNow;

  /// 相対時刻：分
  ///
  /// In ja, this message translates to:
  /// **'{count}分前'**
  String timeMinutesAgo(int count);

  /// 相対時刻：時間
  ///
  /// In ja, this message translates to:
  /// **'{count}時間前'**
  String timeHoursAgo(int count);

  /// 相対時刻：日
  ///
  /// In ja, this message translates to:
  /// **'{count}日前'**
  String timeDaysAgo(int count);

  /// 予定までの残り時間：開始済み
  ///
  /// In ja, this message translates to:
  /// **'開始済み'**
  String get timeStarted;

  /// 予定までの残り時間：1時間未満
  ///
  /// In ja, this message translates to:
  /// **'まもなく'**
  String get timeSoon;

  /// 予定までの残り時間：今日
  ///
  /// In ja, this message translates to:
  /// **'あと{count}時間'**
  String timeHoursLeft(int count);

  /// 予定までの残り時間：2日以上先
  ///
  /// In ja, this message translates to:
  /// **'{count}日後'**
  String timeDaysLater(int count);

  /// 日本円の金額（ストアがくれない金額。X の連携の差額など）
  ///
  /// In ja, this message translates to:
  /// **'{amount}円'**
  String priceYen(String amount);

  /// SNS の名前（SnsService.name）
  ///
  /// In ja, this message translates to:
  /// **'{service, select, twitcasting{ツイキャス} youtube{YouTube} instagram{Instagram} twitch{Twitch} x{X} other{{service}}}'**
  String snsServiceName(String service);

  /// 投稿の種類（PostKind.name）
  ///
  /// In ja, this message translates to:
  /// **'{kind, select, video{動画} short{ショート} image{画像} reel{リール} carousel{カルーセル} other{投稿}}'**
  String postKindName(String kind);

  /// 追星に出す内容の種類（DisplayContent.name）
  ///
  /// In ja, this message translates to:
  /// **'{content, select, live{配信} video{動画・ショート} post{投稿} schedule{予約} other{{content}}}'**
  String displayContentName(String content);

  /// 発信者のプラン（CreatorPlan.name）
  ///
  /// In ja, this message translates to:
  /// **'{plan, select, standard{基本プラン} complimentary{永年無料} admin{運営} debug{確認用} other{{plan}}}'**
  String creatorPlanName(String plan);

  /// 画面モード（DisplayMode.name）
  ///
  /// In ja, this message translates to:
  /// **'{mode, select, system{端末の設定に従う} light{ライト} dark{ダーク} other{{mode}}}'**
  String displayModeName(String mode);

  /// 表示言語（AppLanguage.name）。日本語・English は、どの言語でもその言語の表記で出す
  ///
  /// In ja, this message translates to:
  /// **'{language, select, system{端末の設定に従う} ja{日本語} en{English} other{{language}}}'**
  String appLanguageName(String language);

  /// 共通：利用規約（ウェルカム・設定・プランのリンク）
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get commonTermsOfService;

  /// 共通：プライバシーポリシー（ウェルカム・設定・プランのリンク）
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get commonPrivacyPolicy;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：カバー画像の変更の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'カバーを変えられませんでした'**
  String get creatorCoverChangeFailed;

  /// 発信者ページ：配信中で、固定ビューアでその配信を流していないときのボタン
  ///
  /// In ja, this message translates to:
  /// **'固定ビューアで見る'**
  String get creatorWatchLive;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：カバー画像を変えるボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'カバーを変える'**
  String get creatorChangeCover;

  /// 発信者ページ（画面定義書 2.4.1）：カメラのアイコンのメニューの、端末の写真を選ぶ項目
  ///
  /// In ja, this message translates to:
  /// **'写真を選ぶ'**
  String get creatorCoverPickPhoto;

  /// 発信者ページ（画面定義書 2.4.1）：カメラのアイコンのメニューの、自分の写真を消して発信者のカバーに戻す項目
  ///
  /// In ja, this message translates to:
  /// **'推しが設定したカバーに戻す'**
  String get creatorCoverReset;

  /// 発信者ページ（画面定義書 2.4.1）：自分の写真と発信者のカバーを切り替える、カバーの読み上げの名前
  ///
  /// In ja, this message translates to:
  /// **'カバーを裏返す'**
  String get creatorFlipCover;

  /// 固定ビューア（画面定義書 2.4.3）：固定ビューアで流していた配信が終わって、固定ビューアを閉じたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'配信が終わりました'**
  String get fixedViewerLiveEnded;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：各SNSのフォロワー数の合計の後ろに付く語
  ///
  /// In ja, this message translates to:
  /// **'合計フォロワー'**
  String get creatorTotalFollowers;

  /// 発信者ページ（画面定義書 2.4.1）：折りたたんだプロフィール文の下の、全文を出すボタン
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get creatorBioExpand;

  /// 発信者ページ（画面定義書 2.4.1）：開いたプロフィール文の下の、1行目だけに戻すボタン
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get creatorBioCollapse;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：次の予定のカードの見出し。until は予定までの残り時間（あと3時間など）
  ///
  /// In ja, this message translates to:
  /// **'次の予定 ・ {until}'**
  String creatorNextScheduleHeader(String until);

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：次の予定のカードの、配信先と開始日時。source は SNS の名前か「イベント」、date は月日と曜日、time は時刻
  ///
  /// In ja, this message translates to:
  /// **'{source} ・ {date} {time}〜'**
  String creatorNextScheduleMeta(String source, String date, String time);

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：次の予定のカードで、SNS のない予定（イベントの公演）の配信先の表示
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get creatorNextScheduleEvent;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：新着の投稿と既読の投稿の境目の線
  ///
  /// In ja, this message translates to:
  /// **'ここまで新着'**
  String get creatorNewPostsDivider;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：フォロー中のベルのシート：通知をオンにする（通知オフのとき）
  ///
  /// In ja, this message translates to:
  /// **'通知をオンにする'**
  String get creatorBellNotifyOn;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：フォロー中のベルのシート：通知をオフにする（通知オンのとき）
  ///
  /// In ja, this message translates to:
  /// **'通知をオフにする'**
  String get creatorBellNotifyOff;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：フォロー中のベルのシート：フォローをやめる
  ///
  /// In ja, this message translates to:
  /// **'フォローをやめる'**
  String get creatorBellUnfollow;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：フォロー中のベルのボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'通知とフォロー'**
  String get creatorBellMenu;

  /// 発信者ページ（画面定義書 2.4.1・2.4.2）：この発信者の月のカレンダーを開くボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'月のカレンダー'**
  String get creatorMonthCalendar;

  /// 発信者ページ：メニュー（…）のボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'メニュー'**
  String get creatorMenu;

  /// 発信者ページのメニュー：通報する
  ///
  /// In ja, this message translates to:
  /// **'通報する'**
  String get creatorReport;

  /// 発信者ページのメニュー：この発信者を表示しない
  ///
  /// In ja, this message translates to:
  /// **'この発信者を表示しない'**
  String get creatorHide;

  /// 表示しないの確認のダイアログ：見出し
  ///
  /// In ja, this message translates to:
  /// **'{name}を表示しないようにしますか？'**
  String creatorHideConfirmTitle(String name);

  /// 表示しないの確認のダイアログ：説明
  ///
  /// In ja, this message translates to:
  /// **'フォローを外し、検索やタイムラインにも出さなくなります。設定から元に戻せます。'**
  String get creatorHideConfirmMessage;

  /// 表示しないの確認のダイアログ：表示しないのボタン
  ///
  /// In ja, this message translates to:
  /// **'表示しない'**
  String get creatorHideConfirmAction;

  /// 表示しないにしたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'この発信者を表示しないようにしました'**
  String get creatorHidden;

  /// 表示しないにできなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'表示しないにできませんでした'**
  String get creatorHideFailed;

  /// 通報（シート）：見出し
  ///
  /// In ja, this message translates to:
  /// **'通報する'**
  String get reportTitle;

  /// 通報の理由（ReportReason.name）
  ///
  /// In ja, this message translates to:
  /// **'{reason, select, impersonation{なりすまし} inappropriate{不適切な内容} dangerousLink{危険なリンク} other{その他}}'**
  String reportReasonName(String reason);

  /// 通報（シート）：詳しい内容の入力欄のラベル
  ///
  /// In ja, this message translates to:
  /// **'詳しい内容（任意）'**
  String get reportDetailLabel;

  /// 通報（シート）：注記
  ///
  /// In ja, this message translates to:
  /// **'運営が内容を確かめ、必要に応じて表示を止めます。結果はお知らせしません。'**
  String get reportNote;

  /// 通報（シート）：送信のボタン
  ///
  /// In ja, this message translates to:
  /// **'送信'**
  String get reportSubmit;

  /// 通報を送ったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'通報しました。運営が確認します'**
  String get reportSubmitted;

  /// 24時間のうちに同じ対象を通報済みのときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'この内容は、すでに通報を受け付けています'**
  String get reportAlreadySubmitted;

  /// 通報を送れなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'通報できませんでした'**
  String get reportFailed;

  /// 配信の映像（画面定義書 2.4.2・2.4.3）：ツイキャスの映像の再生に失敗したとき
  ///
  /// In ja, this message translates to:
  /// **'映像を再生できませんでした'**
  String get commonLiveVideoFailed;

  /// 配信の映像（画面定義書 2.4.2・2.4.3）：ミュートのボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'ミュート'**
  String get commonLiveMute;

  /// 配信の映像（画面定義書 2.4.2・2.4.3）：ミュートの解除のボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'ミュートを解除'**
  String get commonLiveUnmute;

  /// 発信者メニュー：画面のタイトルと、下のナビの発信者メニューのボタンの読み上げ
  ///
  /// In ja, this message translates to:
  /// **'発信者メニュー'**
  String get commonCreatorMenu;

  /// 発信者メニュー：停止中の注意
  ///
  /// In ja, this message translates to:
  /// **'この発信者は、運営が表示を止めています。くわしくは、お問い合わせください。'**
  String get creatorAdminSuspendedNotice;

  /// 発信者メニュー：連携の節の見出し（SNS）
  ///
  /// In ja, this message translates to:
  /// **'連携'**
  String get creatorAdminMenuSectionLinks;

  /// プロフィールの編集：画面のタイトル。発信者メニューの行の名前にも使う
  ///
  /// In ja, this message translates to:
  /// **'プロフィールの編集'**
  String get creatorAdminProfileEditTitle;

  /// SNS の連携：画面のタイトル。発信者メニューの行の名前にも使う。設定のアカウント（ログイン方法）と混ざらないよう「アカウント連携」とは呼ばない
  ///
  /// In ja, this message translates to:
  /// **'SNS の連携'**
  String get creatorAdminAccountLinkTitle;

  /// 発信者メニュー：アカウント連携の行の、連携済みの数
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String creatorAdminMenuLinkedCount(int count);

  /// 発信者メニュー：コンテンツの節の見出し（投稿の管理・イベントの管理・予定のデフォルトの長さ）
  ///
  /// In ja, this message translates to:
  /// **'コンテンツ'**
  String get creatorAdminMenuSectionContent;

  /// 発信者メニューの「イベントの管理」の行と、その画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'イベントの管理'**
  String get creatorAdminMenuEventManage;

  /// 投稿の管理：画面のタイトル。発信者メニューの行の名前にも使う
  ///
  /// In ja, this message translates to:
  /// **'投稿の管理'**
  String get creatorAdminPostManageTitle;

  /// プラン：画面のタイトル。発信者メニューの節の見出し・行の名前にも使う
  ///
  /// In ja, this message translates to:
  /// **'プラン'**
  String get creatorAdminPlanTitle;

  /// アカウント連携・表示する内容：準備中のプラットフォーム（ニコニコ）の名前
  ///
  /// In ja, this message translates to:
  /// **'ニコニコ'**
  String get creatorAdminUpcomingNiconico;

  /// 表示する内容：準備中の TikTok で選べるようになる内容
  ///
  /// In ja, this message translates to:
  /// **'配信・ショート動画'**
  String get creatorAdminUpcomingTiktokContents;

  /// 表示する内容：準備中のニコニコで選べるようになる内容
  ///
  /// In ja, this message translates to:
  /// **'配信・動画'**
  String get creatorAdminUpcomingNiconicoContents;

  /// アカウント連携：連携できたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{service}を連携しました'**
  String creatorAdminLinked(String service);

  /// アカウント連携：ほかの発信者で連携済みのときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'このアカウントは、ほかの発信者で連携されています'**
  String get creatorAdminLinkDuplicate;

  /// アカウント連携：YouTube のチャンネルがないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'YouTube のチャンネルが見つかりませんでした'**
  String get creatorAdminLinkNoChannel;

  /// アカウント連携：連携の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'連携できませんでした。もう一度お試しください'**
  String get creatorAdminLinkFailed;

  /// アカウント連携：連携の解除の確認ダイアログの見出し
  ///
  /// In ja, this message translates to:
  /// **'{service}の連携を解除しますか？'**
  String creatorAdminUnlinkConfirmTitle(String service);

  /// アカウント連携：連携の解除の確認ダイアログの説明
  ///
  /// In ja, this message translates to:
  /// **'追星に表示されなくなります。'**
  String get creatorAdminUnlinkConfirmMessage;

  /// アカウント連携：連携の解除の確認ダイアログの実行ボタン
  ///
  /// In ja, this message translates to:
  /// **'解除する'**
  String get creatorAdminUnlinkConfirmAction;

  /// アカウント連携：連携を解除したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{service}の連携を解除しました'**
  String creatorAdminUnlinked(String service);

  /// アカウント連携：連携の解除の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'解除できませんでした。もう一度お試しください'**
  String get creatorAdminUnlinkFailed;

  /// アカウント連携：画面の上の説明
  ///
  /// In ja, this message translates to:
  /// **'連携して、そのアカウントが本人のものだと確認されると、追星に表示できます。'**
  String get creatorAdminAccountLinkIntro;

  /// アカウント連携：画面の下の注意書き
  ///
  /// In ja, this message translates to:
  /// **'確認が済んでいないアカウントは、追星には表示されません。連携したあとも、追星に出す内容をオフにできます。連携は、いつでも解除できます。'**
  String get creatorAdminAccountLinkNote;

  /// アカウント連携：連携のボタン
  ///
  /// In ja, this message translates to:
  /// **'連携する'**
  String get creatorAdminLinkAction;

  /// アカウント連携：連携していない SNS の行の表示
  ///
  /// In ja, this message translates to:
  /// **'未連携'**
  String get creatorAdminNotLinked;

  /// 表示する内容：オフにしたときの注記
  ///
  /// In ja, this message translates to:
  /// **'オフにすると、取得済みの投稿も、すぐにファンに見えなくなります。'**
  String get creatorAdminDisplayContentsHideNote;

  /// 表示する内容：X のカードの注意書き（X連携プランに未加入）
  ///
  /// In ja, this message translates to:
  /// **'X連携プラン（月{price}）に加入すると使えます'**
  String creatorAdminDisplayNeedsXOption(String price);

  /// 発信者として登録：登録できたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'発信者として登録しました'**
  String get creatorAdminRegistered;

  /// 発信者として登録：登録できたが、登録のあとのアイコン・カバー・タイプの保存に失敗したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'発信者として登録しました。プロフィールの一部を保存できなかったので、プロフィールの編集で直してください'**
  String get creatorAdminRegisteredPartially;

  /// 発信者として登録：ID が使われているときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'このIDは、すでに使われています'**
  String get creatorAdminRegisterIdTaken;

  /// 発信者として登録：連携したアカウントがほかの発信者で使われているときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'連携したアカウントが、ほかの発信者で使われています'**
  String get creatorAdminRegisterDuplicate;

  /// 発信者として登録：登録を受け付けていないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'発信者の登録は、準備中です'**
  String get creatorAdminRegisterClosed;

  /// 発信者として登録：登録の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'登録できませんでした。もう一度お試しください'**
  String get creatorAdminRegisterFailed;

  /// 発信者として登録：画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'発信者として登録'**
  String get creatorAdminRegisterTitle;

  /// 発信者として登録：画面の上の見出し
  ///
  /// In ja, this message translates to:
  /// **'あなたの配信・投稿・イベントを\nファンに届けます'**
  String get creatorAdminRegisterHeadline;

  /// 発信者として登録：見出しの上の小さなラベル（英字のまま。2026-11-10 本人）
  ///
  /// In ja, this message translates to:
  /// **'FOR CREATORS'**
  String get creatorAdminRegisterEyebrow;

  /// 発信者として登録：見出しの下の説明
  ///
  /// In ja, this message translates to:
  /// **'連携したいSNSアカウントにサインインしてください。\n投稿やフォロワー数、リンクなどがアプリに表示されます。'**
  String get creatorAdminRegisterLead;

  /// 発信者として登録：手順1の見出し
  ///
  /// In ja, this message translates to:
  /// **'SNSアカウントを連携'**
  String get creatorAdminRegisterStepLink;

  /// 発信者として登録：手順1が済んだときの説明。services は連携済みの SNS の名前を commonListSeparator でつないだもの
  ///
  /// In ja, this message translates to:
  /// **'{services} を連携済み'**
  String creatorAdminRegisterStepLinkDone(String services);

  /// 共通：名前などを並べるときの区切り（発信者として登録の SNS の名前、タイムスケジュールの「+N」の読み上げ、公演の候補のチケットサイト、イベントの候補の説明とサイト）
  ///
  /// In ja, this message translates to:
  /// **'・'**
  String get commonListSeparator;

  /// 発信者として登録：手順2の見出し
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを入力'**
  String get creatorAdminRegisterStepProfile;

  /// 発信者として登録：手順2が済んだときの説明
  ///
  /// In ja, this message translates to:
  /// **'{name}（@{id}）として入力済み'**
  String creatorAdminRegisterStepProfileDone(String name, String id);

  /// 発信者として登録：規約への同意の文の、リンクの前の部分（日本語は空）
  ///
  /// In ja, this message translates to:
  /// **''**
  String get creatorAdminRegisterAgreePrefix;

  /// 発信者として登録：同意の文の、規約の名前の区切り（利用規約とプライバシーポリシーの間）
  ///
  /// In ja, this message translates to:
  /// **'・'**
  String get creatorAdminRegisterAgreeSeparator;

  /// 発信者として登録：同意の文の、最後の規約の名前の前の区切り（プライバシーポリシーと発信者向けの利用規約の間）
  ///
  /// In ja, this message translates to:
  /// **'・'**
  String get creatorAdminRegisterAgreeLastSeparator;

  /// 発信者として登録：規約への同意の文の、リンクの部分
  ///
  /// In ja, this message translates to:
  /// **'発信者向けの利用規約'**
  String get creatorAdminRegisterTerms;

  /// 発信者として登録：規約への同意の文の、リンクの後の部分（英語は空）
  ///
  /// In ja, this message translates to:
  /// **'に同意する'**
  String get creatorAdminRegisterAgreeSuffix;

  /// 発信者として登録：登録のボタン
  ///
  /// In ja, this message translates to:
  /// **'発信者として登録する'**
  String get creatorAdminRegisterAction;

  /// プロフィールの編集：SNS からの取り込みの失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{service}から取り込めませんでした'**
  String creatorAdminImportFailed(String service);

  /// プロフィールの編集：取り込める項目がないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{service}に、取り込める項目がありませんでした'**
  String creatorAdminImportEmpty(String service);

  /// プロフィールの編集：取り込みの回数の上限を超えたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{service}からの取り込みは、しばらく時間をおいてお試しください'**
  String creatorAdminImportLimited(String service);

  /// プロフィールの編集：取り込めたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{service}から、下書きを入れました'**
  String creatorAdminImported(String service);

  /// プロフィールの編集：取り込んだ項目の印
  ///
  /// In ja, this message translates to:
  /// **'下書き・{service}から'**
  String creatorAdminDraftBadge(String service);

  /// プロフィールの編集：名前の入力の誤りのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'名前は、1〜100文字で入力してください'**
  String get creatorAdminNameInvalid;

  /// プロフィールの編集：ID の入力の誤りのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'IDは、英小文字・数字・_・- の1〜40文字で入力してください'**
  String get creatorAdminIdInvalid;

  /// プロフィールの編集：カバーの画像を変えるボタンのツールチップ
  ///
  /// In ja, this message translates to:
  /// **'カバーを変える'**
  String get creatorAdminChangeCover;

  /// プロフィールの編集：アイコンを変えるボタンのツールチップ
  ///
  /// In ja, this message translates to:
  /// **'アイコンを変える'**
  String get creatorAdminChangeAvatar;

  /// プロフィールの編集：SNS からの取り込みのパネルの見出し
  ///
  /// In ja, this message translates to:
  /// **'連携したSNSから入力'**
  String get creatorAdminImportTitle;

  /// プロフィールの編集：SNS からの取り込みのパネルの説明
  ///
  /// In ja, this message translates to:
  /// **'名前・アイコン・プロフィール文を、下書きとして入れます。保存するまでは、反映されません。'**
  String get creatorAdminImportDescription;

  /// プロフィールの編集：名前の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'名前'**
  String get creatorAdminFieldName;

  /// プロフィールの編集：プロフィール文の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'プロフィール文'**
  String get creatorAdminFieldBio;

  /// プロフィールの編集：ID の欄の注意書き
  ///
  /// In ja, this message translates to:
  /// **'IDは、あとから変えられません。'**
  String get creatorAdminIdNote;

  /// プロフィールの編集：ID の欄のプレースホルダ
  ///
  /// In ja, this message translates to:
  /// **'英小文字・数字・_・-'**
  String get creatorAdminIdHint;

  /// イベントの登録：必須の項目が未入力のときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'必須の項目を入力してください'**
  String get creatorAdminEventRequiredMissing;

  /// イベントの登録：タイトルの欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get creatorAdminEventFieldTitle;

  /// イベントの登録：タイトルの欄のプレースホルダ
  ///
  /// In ja, this message translates to:
  /// **'例：新衣装のお披露目'**
  String get creatorAdminEventTitleHint;

  /// イベントの登録：日付の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'日付'**
  String get creatorAdminEventFieldDate;

  /// イベントの登録：選んだ日付。date は fullDate、weekday は weekdayLabel
  ///
  /// In ja, this message translates to:
  /// **'{date}（{weekday}）'**
  String creatorAdminEventDate(String date, String weekday);

  /// イベントの登録：日付の欄のプレースホルダ
  ///
  /// In ja, this message translates to:
  /// **'日付を選ぶ'**
  String get creatorAdminEventPickDate;

  /// イベントの登録：開始時刻の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'開始'**
  String get creatorAdminEventFieldStart;

  /// イベントの登録：終了時刻の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'終了（任意）'**
  String get creatorAdminEventFieldEnd;

  /// イベントの登録：終了時刻の欄の下の注意書き（終了を空にしたときの表示）
  ///
  /// In ja, this message translates to:
  /// **'指定しない場合は、その日の終わりまで表示します'**
  String get creatorAdminEventEndNote;

  /// イベントの登録：会場の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'会場（任意）'**
  String get creatorAdminEventFieldVenue;

  /// イベントの登録：会場の欄のプレースホルダ
  ///
  /// In ja, this message translates to:
  /// **'例：東京・渋谷 ○○ホール'**
  String get creatorAdminEventVenueHint;

  /// イベントの登録：広告のリンクのスイッチの名前
  ///
  /// In ja, this message translates to:
  /// **'このリンクは広告です'**
  String get creatorAdminEventPromotion;

  /// イベントの登録：広告のリンクのスイッチの説明
  ///
  /// In ja, this message translates to:
  /// **'「PR」と表示します（チケットの販売など）'**
  String get creatorAdminEventPromotionHint;

  /// イベントの登録：タイトルが長すぎるときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'タイトルは、1〜200文字で入力してください'**
  String get creatorAdminEventTitleTooLong;

  /// イベントの登録：リンクが https:// で始まらないときの、リンクの欄の案内
  ///
  /// In ja, this message translates to:
  /// **'https:// で始まる URL を入れてください'**
  String get creatorAdminEventLinkInvalid;

  /// イベントの登録：編集のときの、一番下の削除のボタン。削除の確認のダイアログのボタンにも使う
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get creatorAdminEventDelete;

  /// イベントの登録：削除に失敗したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'削除できませんでした'**
  String get creatorAdminEventDeleteFailed;

  /// イベントの管理：右上と、空の状態の登録のボタン
  ///
  /// In ja, this message translates to:
  /// **'登録'**
  String get creatorAdminEventListAdd;

  /// イベントの管理：1件もないときの状態表示
  ///
  /// In ja, this message translates to:
  /// **'イベントはまだありません'**
  String get creatorAdminEventListEmpty;

  /// イベントの管理：過去の予定をまとめる行
  ///
  /// In ja, this message translates to:
  /// **'過去のイベント'**
  String get creatorAdminEventListPast;

  /// 共通（入力欄の部品）：入力欄の必須の印。イベントの登録・プロフィールの編集など
  ///
  /// In ja, this message translates to:
  /// **'必須'**
  String get commonRequired;

  /// プラン：購入の承認待ちのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'支払いの承認を待っています'**
  String get creatorAdminPlanPurchasePending;

  /// プラン：購入の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'購入できませんでした。もう一度お試しください'**
  String get creatorAdminPlanPurchaseFailed;

  /// プラン：購入を復元できたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'購入を復元しました'**
  String get creatorAdminPlanRestored;

  /// プラン：復元できる購入がないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'復元できる購入がありません'**
  String get creatorAdminPlanNothingToRestore;

  /// プラン：購入の復元の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'復元できませんでした。もう一度お試しください'**
  String get creatorAdminPlanRestoreFailed;

  /// プラン：いまのプランのパネルの見出し
  ///
  /// In ja, this message translates to:
  /// **'いまのプラン'**
  String get creatorAdminPlanCurrent;

  /// プラン：基本プランの料金
  ///
  /// In ja, this message translates to:
  /// **'無料'**
  String get creatorAdminPlanFree;

  /// プラン：X の連携に加入するボタン
  ///
  /// In ja, this message translates to:
  /// **'加入する'**
  String get creatorAdminPlanSubscribe;

  /// プラン：加入中のプランの印
  ///
  /// In ja, this message translates to:
  /// **'加入中'**
  String get creatorAdminPlanSubscribed;

  /// プラン：月額の表示。price はストアの価格または priceYen
  ///
  /// In ja, this message translates to:
  /// **'月{price}'**
  String creatorAdminPlanPerMonth(String price);

  /// プラン：基本プランの内容（1）。services は、この版で出す SNS のうち X を除いたものの名前を commonListSeparator でつないだもの（v1.0.0 は Instagram・ツイキャスを除く）
  ///
  /// In ja, this message translates to:
  /// **'{services} の取得と表示'**
  String creatorAdminPlanBasicFeatureFetch(String services);

  /// プラン：基本プランの内容（2）
  ///
  /// In ja, this message translates to:
  /// **'配信の予約の取得'**
  String get creatorAdminPlanBasicFeatureReservations;

  /// プラン：基本プランの内容（3）
  ///
  /// In ja, this message translates to:
  /// **'イベントの登録'**
  String get creatorAdminPlanBasicFeatureCalendar;

  /// プラン：オプションの節の見出し
  ///
  /// In ja, this message translates to:
  /// **'オプション'**
  String get creatorAdminPlanAddOns;

  /// プラン：X の連携のオプションのカードの見出し
  ///
  /// In ja, this message translates to:
  /// **'X連携プラン'**
  String get creatorAdminPlanXOptionTitle;

  /// プラン：X の連携の内容（1）
  ///
  /// In ja, this message translates to:
  /// **'X の投稿の取得と表示'**
  String get creatorAdminPlanXFeatureFetch;

  /// プラン：X の連携の内容（2）
  ///
  /// In ja, this message translates to:
  /// **'リポスト・リプライは、取りません'**
  String get creatorAdminPlanXFeatureNoReposts;

  /// プラン：解約のボタン（ストアのサブスクの管理を開く）
  ///
  /// In ja, this message translates to:
  /// **'解約する'**
  String get creatorAdminPlanCancel;

  /// プラン：「解約する」の確認のダイアログの見出し
  ///
  /// In ja, this message translates to:
  /// **'ストアのサブスクの管理を開きます'**
  String get creatorAdminPlanCancelConfirmTitle;

  /// プラン：「解約する」の確認のダイアログの説明
  ///
  /// In ja, this message translates to:
  /// **'解約は、ストアの画面で行います。期間の終わりまでは、X の連携を使えます。'**
  String get creatorAdminPlanCancelConfirmMessage;

  /// プラン：「解約する」の確認のダイアログの、開くボタン
  ///
  /// In ja, this message translates to:
  /// **'開く'**
  String get creatorAdminPlanCancelConfirmAction;

  /// プラン：購入の復元のボタン
  ///
  /// In ja, this message translates to:
  /// **'購入を復元'**
  String get creatorAdminPlanRestore;

  /// プラン：自動更新のサブスクの注意書き（ストアの審査で要る文言）
  ///
  /// In ja, this message translates to:
  /// **'お支払いは、ストアのアカウントに請求されます。X連携プランは、1か月ごとの自動更新のサブスクです。期間の終わりの24時間前までに解約しないと、自動で更新されます。解約は、ストアのサブスクの管理で行えます。'**
  String get creatorAdminPlanSubscriptionTerms;

  /// プラン：利用規約とプライバシーポリシーのリンクの区切り
  ///
  /// In ja, this message translates to:
  /// **'・'**
  String get creatorAdminPlanLegalSeparator;

  /// プラン：X の連携の次の更新日。date は fullDate
  ///
  /// In ja, this message translates to:
  /// **'次の更新日 {date}'**
  String creatorAdminPlanRenewsOn(String date);

  /// プラン：X の連携を解約したときの、終わる日。date は fullDate
  ///
  /// In ja, this message translates to:
  /// **'{date}に終了'**
  String creatorAdminPlanEndsOn(String date);

  /// プラン：課金を使えない端末の見出し
  ///
  /// In ja, this message translates to:
  /// **'この端末では、まだ X連携プランに加入できません'**
  String get creatorAdminPlanUnavailableTitle;

  /// プラン：課金を使えない端末の説明
  ///
  /// In ja, this message translates to:
  /// **'準備ができるまで、お待ちください。'**
  String get creatorAdminPlanUnavailableMessage;

  /// プラン：永年無料・運営・確認用のプランの説明
  ///
  /// In ja, this message translates to:
  /// **'料金はかかりません（X の連携を含む）'**
  String get creatorAdminPlanIncludedNote;

  /// ウェルカム：アプリの説明
  ///
  /// In ja, this message translates to:
  /// **'推しの配信・投稿・予定が、\nひとつに集まります。'**
  String get onboardingWelcomeTagline;

  /// ウェルカム：はじめるのボタン
  ///
  /// In ja, this message translates to:
  /// **'はじめる'**
  String get onboardingStart;

  /// ウェルカム：発信者の登録へのボタン
  ///
  /// In ja, this message translates to:
  /// **'発信者の方はこちら'**
  String get onboardingForCreators;

  /// ウェルカム：同意の文の前半（はじめるのボタンの名前を含む）
  ///
  /// In ja, this message translates to:
  /// **'「はじめる」を押すと、'**
  String get onboardingAgreePrefix;

  /// ウェルカム：同意の文の、利用規約とプライバシーポリシーのつなぎ
  ///
  /// In ja, this message translates to:
  /// **'と'**
  String get onboardingAgreeAnd;

  /// ウェルカム：同意の文の後半
  ///
  /// In ja, this message translates to:
  /// **'に\n同意したものとします。'**
  String get onboardingAgreeSuffix;

  /// 推しを選ぶ：見出し
  ///
  /// In ja, this message translates to:
  /// **'推しをフォローしましょう'**
  String get onboardingChooseTitle;

  /// 推しを選ぶ：説明
  ///
  /// In ja, this message translates to:
  /// **'フォローした推しの、配信・投稿・予定が、ホームに集まります。'**
  String get onboardingChooseMessage;

  /// 推しを選ぶ：検索フィールドのプレースホルダ
  ///
  /// In ja, this message translates to:
  /// **'名前やIDで探す'**
  String get onboardingChooseSearchHint;

  /// 推しを選ぶ：次へのボタン（だれもフォローしていない）
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get onboardingNext;

  /// 推しを選ぶ：次へのボタン（フォロー中の人数つき）
  ///
  /// In ja, this message translates to:
  /// **'次へ（{count}人をフォロー中）'**
  String onboardingNextFollowing(int count);

  /// 推しを選ぶ：あとでのボタン
  ///
  /// In ja, this message translates to:
  /// **'あとで'**
  String get onboardingLater;

  /// 通知の説明：見出し
  ///
  /// In ja, this message translates to:
  /// **'配信が始まったら、\nお知らせします'**
  String get onboardingNotificationTitle;

  /// 通知の説明：説明
  ///
  /// In ja, this message translates to:
  /// **'推しが配信を始めたときに、通知でお知らせします。\nあとから、設定で変えられます。'**
  String get onboardingNotificationMessage;

  /// 通知の説明：通知の許可を求めるボタン
  ///
  /// In ja, this message translates to:
  /// **'通知をオンにする'**
  String get onboardingNotificationEnable;

  /// 通知の説明：通知の許可を求めずに進むボタン
  ///
  /// In ja, this message translates to:
  /// **'いまはしない'**
  String get onboardingNotificationSkip;

  /// 通知の説明：通知の見本カードの見出し（架空の発信者）
  ///
  /// In ja, this message translates to:
  /// **'星野ミナトが配信を始めました'**
  String get onboardingNotificationSampleTitle;

  /// 通知の説明：通知の見本カードの本文（架空の配信のタイトル）
  ///
  /// In ja, this message translates to:
  /// **'【Apex】プラチナ帯ソロランク耐久！'**
  String get onboardingNotificationSampleBody;

  /// 共通：配信の面（ホーム）と固定ビューアの、配信元のアイコン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'配信元で開く'**
  String get commonLiveOpenSource;

  /// 固定ビューアの帯の、フォロー中の推しの動画のランダム再生に切り替えるボタン（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'推しの動画をランダムに流す'**
  String get fixedViewerShufflePlay;

  /// ホーム：ランダムに流す動画が1本もないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'流せる動画がありません'**
  String get homeShuffleEmpty;

  /// 共通：固定ビューアのランダム再生で、前の動画に戻る矢印（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'前の動画'**
  String get commonVideoPrevious;

  /// 共通：固定ビューアのランダム再生で、次の動画に進む矢印（ツールチップ）
  ///
  /// In ja, this message translates to:
  /// **'次の動画'**
  String get commonVideoNext;

  /// ホーム：推しが0人のときの見出し
  ///
  /// In ja, this message translates to:
  /// **'推しを探しましょう'**
  String get homeEmptyTitle;

  /// ホーム：推しが0人のときの説明
  ///
  /// In ja, this message translates to:
  /// **'推しをフォローすると、配信や予定、投稿が、ここに集まります。'**
  String get homeEmptyMessage;

  /// ホーム：全体タイムラインの末尾（過去90日ぶんを読み終えた）
  ///
  /// In ja, this message translates to:
  /// **'過去90日ぶんを、すべて表示しました'**
  String get homeTimelineEnd;

  /// ホーム：次の予定（本日中。今日のこれからの予定）の見出し
  ///
  /// In ja, this message translates to:
  /// **'次の予定'**
  String get homeUpcomingTitle;

  /// ホーム：次の予定（本日中）が0件
  ///
  /// In ja, this message translates to:
  /// **'今日はこれからの予定はありません'**
  String get homeUpcomingEmpty;

  /// ホーム・発信者ページ・公演の候補：イベントの面の見出し。イベントの詳細の画面のタイトルにも使う
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get commonEventsTitle;

  /// ホーム・発信者ページ・イベント一覧：イベントが0件
  ///
  /// In ja, this message translates to:
  /// **'これからのイベントはありません'**
  String get commonEventsEmpty;

  /// ホーム・発信者ページ：「次の予定」「イベント」の面の下の、出しきれない件数。押すと、スケジュールのタブか月のカレンダーへ移る
  ///
  /// In ja, this message translates to:
  /// **'ほか {count} 件'**
  String commonMoreCount(int count);

  /// 共通：推しを探すの画面の名前。推しリストのヘッダーのボタン（ツールチップ）、ホームの推しが0人のときのボタン、固定ビューアの空のときの案内にも使う
  ///
  /// In ja, this message translates to:
  /// **'推しを探す'**
  String get commonFindCreatorsTitle;

  /// 推しリスト：フォロー中の人数
  ///
  /// In ja, this message translates to:
  /// **'{count}人フォロー中'**
  String oshiListCount(int count);

  /// 推しリスト：並び順の表示
  ///
  /// In ja, this message translates to:
  /// **'並び替え：配信中が先'**
  String get oshiListSortLiveFirst;

  /// 推しリスト：配信中の推しの行（配信のタイトル）
  ///
  /// In ja, this message translates to:
  /// **'配信中：{title}'**
  String oshiListLiveNow(String title);

  /// 推しリスト：次の予定（いつ・タイトル）
  ///
  /// In ja, this message translates to:
  /// **'{when} {title}'**
  String oshiListNextSchedule(String when, String title);

  /// 推しリスト：次の予定がない推しの行
  ///
  /// In ja, this message translates to:
  /// **'予定はありません'**
  String get oshiListNoSchedule;

  /// 推しリスト：フォロー中の推しが0人のときの見出し
  ///
  /// In ja, this message translates to:
  /// **'推しがいません'**
  String get oshiListEmptyTitle;

  /// 推しリスト：フォロー中の推しが0人のときの説明
  ///
  /// In ja, this message translates to:
  /// **'推しをフォローすると、ここに並びます。'**
  String get oshiListEmptyMessage;

  /// 推しリスト：検索に合う推しがいないときの説明
  ///
  /// In ja, this message translates to:
  /// **'「{query}」に合う推しは、フォロー中にいません。'**
  String oshiListNoMatch(String query);

  /// 推しリスト：フォローの解除の失敗のスナックバー
  ///
  /// In ja, this message translates to:
  /// **'フォローを解除できませんでした'**
  String get oshiListUnfollowFailed;

  /// 共通：推しを探す・推しを選ぶ（初回起動）で、検索の結果が0件のときの説明
  ///
  /// In ja, this message translates to:
  /// **'「{query}」に合う推しは、まだ追星にいません。名前やIDを、もう一度確かめてください。'**
  String commonFindNoMatch(String query);

  /// 推しを探す：言葉がないときの、おすすめの見出し
  ///
  /// In ja, this message translates to:
  /// **'おすすめ'**
  String get oshiFindRecommended;

  /// X の投稿：時刻の隣の、X で投稿を開くリンク（X の表示の決まりの「View on X」）
  ///
  /// In ja, this message translates to:
  /// **'Xで見る'**
  String get commonViewOnX;

  /// 投稿ビューア：元の投稿を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'開く'**
  String get postOpen;

  /// 投稿ビューア：押すまで流さない動画の、再生のマーク（読み上げ）
  ///
  /// In ja, this message translates to:
  /// **'再生'**
  String get postVideoPlay;

  /// 投稿ビューア：アプリで再生できない動画の、再生のマークの下の文言。押すと元の SNS で開く
  ///
  /// In ja, this message translates to:
  /// **'この動画はアプリ上では再生できません'**
  String get commonVideoUnplayable;

  /// 投稿の管理：一覧の上の注記。隠しても元の SNS の投稿は消えないこと
  ///
  /// In ja, this message translates to:
  /// **'ここで隠しても、元の SNS の投稿は消えません。追星でファンに出さなくなるだけです。'**
  String get creatorAdminPostManageNote;

  /// 投稿の管理：投稿ごとのトグル（オン＝出す、オフ＝隠す）の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'ファンに出す'**
  String get creatorAdminPostVisibleSwitch;

  /// 投稿の管理：投稿を隠したあとのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'隠しました'**
  String get creatorAdminPostHidden;

  /// 投稿の管理：投稿をまた出したあとのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'また出しました'**
  String get creatorAdminPostShown;

  /// 投稿の管理：投稿を隠せなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'隠せませんでした'**
  String get creatorAdminPostHideFailed;

  /// 投稿の管理：投稿をまた出せなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'また出せませんでした'**
  String get creatorAdminPostShowFailed;

  /// ホーム：アプリを開いているときに届いた配信開始の通知のスナックバー（通知にタイトルがないとき）
  ///
  /// In ja, this message translates to:
  /// **'推しが配信を始めました'**
  String get homeLiveStartedFallback;

  /// ホーム：配信開始の通知のスナックバーの、発信者ページを開く操作
  ///
  /// In ja, this message translates to:
  /// **'開く'**
  String get homeLiveStartedOpen;

  /// ホーム：アプリを開いているときに届いた予定の事前通知のスナックバー（通知にタイトルがないとき）
  ///
  /// In ja, this message translates to:
  /// **'推しの予定のお知らせ'**
  String get homeScheduleNoticeFallback;

  /// ホーム：アプリを開いているときに届いた、追いたいの人の登録の通知のスナックバー（通知にタイトルがないとき）
  ///
  /// In ja, this message translates to:
  /// **'追いたい人が追星に来ました'**
  String get homeWantArrivalFallback;

  /// タイムスケジュール：終了時刻のない予定のブロックの時刻（例：21:00〜）
  ///
  /// In ja, this message translates to:
  /// **'{time}〜'**
  String scheduleOpenEndedTime(String time);

  /// タイムスケジュール・月のカレンダー：選んだ日に予定がないとき
  ///
  /// In ja, this message translates to:
  /// **'この日の予定はありません'**
  String get scheduleDayEmpty;

  /// タイムスケジュール：予定がないときのカードの補足
  ///
  /// In ja, this message translates to:
  /// **'ほかの日は、上の日付から選べます。'**
  String get scheduleDayEmptyHint;

  /// タイムスケジュールの詳細のパネル：配信中の配信のカードの状態
  ///
  /// In ja, this message translates to:
  /// **'配信中'**
  String get scheduleLiveNow;

  /// タイムスケジュールの詳細のパネル：配信中の配信のカードのボタン
  ///
  /// In ja, this message translates to:
  /// **'配信を見る'**
  String get scheduleWatchLive;

  /// タイムスケジュールの詳細のパネル：まとめた投稿（+N）のカードの見出し
  ///
  /// In ja, this message translates to:
  /// **'{name}の投稿'**
  String schedulePostsGroupTitle(String name);

  /// タイムスケジュールの詳細のパネル：まとめた投稿のカードの、時刻と件数
  ///
  /// In ja, this message translates to:
  /// **'{hour}時ごろ ・ {count}件'**
  String schedulePostsGroupSubtitle(int hour, int count);

  /// タイムスケジュール：「+N」の読み上げ。services は、含まれる SNS の名前を commonListSeparator でつないだもの
  ///
  /// In ja, this message translates to:
  /// **'{count}件の投稿（{services}）'**
  String schedulePostsGroupSemantics(int count, String services);

  /// タイムスケジュール：絞り込みのシートの見出しと、ヘッダーのボタンのツールチップ
  ///
  /// In ja, this message translates to:
  /// **'絞り込み'**
  String get scheduleFilterTitle;

  /// 絞り込みのシート：リセットのボタン
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get scheduleFilterReset;

  /// 絞り込みのシート：表示する推しの行と、推しの選択の見出し
  ///
  /// In ja, this message translates to:
  /// **'表示する推し'**
  String get scheduleFilterCreatorsTitle;

  /// 絞り込みのシート（推しの選択）：すべて選ぶボタン
  ///
  /// In ja, this message translates to:
  /// **'すべて選ぶ'**
  String get scheduleFilterSelectAll;

  /// 絞り込みのシート（推しの選択）：すべて外すボタン
  ///
  /// In ja, this message translates to:
  /// **'すべて外す'**
  String get scheduleFilterDeselectAll;

  /// 絞り込みのシート：表示する推しが全員のときの値
  ///
  /// In ja, this message translates to:
  /// **'全員'**
  String get scheduleFilterAllCreators;

  /// 絞り込みのシート：表示する推しの人数
  ///
  /// In ja, this message translates to:
  /// **'{count}人'**
  String scheduleFilterCreatorCount(int count);

  /// 絞り込みのシート：プラットフォームの見出し
  ///
  /// In ja, this message translates to:
  /// **'プラットフォーム'**
  String get scheduleFilterPlatforms;

  /// 絞り込みのシート：表示する内容の見出し
  ///
  /// In ja, this message translates to:
  /// **'表示する内容'**
  String get scheduleFilterContent;

  /// タイムスケジュールのヘッダー：予定のない推しを隠すアイコン（オン・オフ）
  ///
  /// In ja, this message translates to:
  /// **'配信・投稿・予定のない推しを隠す'**
  String get scheduleFilterHideEmpty;

  /// タイムスケジュール：予定のない推しを隠すアイコンをオンにしたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'配信・投稿・予定のない推しを隠しました'**
  String get scheduleHideEmptyOn;

  /// タイムスケジュール：予定のない推しを隠すアイコンをオフにしたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'すべての推しを表示しました'**
  String get scheduleHideEmptyOff;

  /// 絞り込みのシート：決定のボタン（人数とSNSの数）
  ///
  /// In ja, this message translates to:
  /// **'{creators}人・{services}つのSNSで表示'**
  String scheduleFilterApply(int creators, int services);

  /// 共通（プラットフォームのチップ）：プラットフォームのない予定（イベントの公演）
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get commonNoService;

  /// タイムスケジュール：推しがいないときの空の状態の見出し
  ///
  /// In ja, this message translates to:
  /// **'推しの予定が、ここに並びます'**
  String get scheduleEmptyTitle;

  /// タイムスケジュール：推しがいないときの空の状態の説明
  ///
  /// In ja, this message translates to:
  /// **'推しをフォローすると、配信やイベントを、時間の表で見られます。'**
  String get scheduleEmptyMessage;

  /// タイムスケジュール：月のカレンダーへのボタンのツールチップ
  ///
  /// In ja, this message translates to:
  /// **'カレンダーへ'**
  String get scheduleOpenCalendar;

  /// タイムスケジュール：終日の予定が複数あるときの表示（ほかの件数）
  ///
  /// In ja, this message translates to:
  /// **'{title} +{count}'**
  String scheduleAllDayMore(String title, int count);

  /// 月のカレンダー：複数の推しのときの画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'みんなのカレンダー'**
  String get scheduleCalendarAllTitle;

  /// 月のカレンダー：1人の推しのときの画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'{name}のカレンダー'**
  String scheduleCalendarCreatorTitle(String name);

  /// イベント一覧：推し全員のときの画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'みんなのイベント'**
  String get eventListAllTitle;

  /// イベント一覧：1人の推しのときの画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'{name}のイベント'**
  String eventListCreatorTitle(String name);

  /// 共通：イベントの面（イベント一覧など）と公演の候補の行の、曜日と時刻（when）と会場
  ///
  /// In ja, this message translates to:
  /// **'{when}・{venue}'**
  String commonWhenVenue(String when, String venue);

  /// イベント一覧：イベントが0件のときの説明
  ///
  /// In ja, this message translates to:
  /// **'イベントが登録されると、ここに出ます'**
  String get eventListEmptyMessage;

  /// 月のカレンダー：前の月へのボタンのツールチップ
  ///
  /// In ja, this message translates to:
  /// **'前の月'**
  String get schedulePreviousMonth;

  /// 月のカレンダー：次の月へのボタンのツールチップ
  ///
  /// In ja, this message translates to:
  /// **'次の月'**
  String get scheduleNextMonth;

  /// 月のカレンダー：選んだ日のパネルの投稿の行
  ///
  /// In ja, this message translates to:
  /// **'この日に行われた投稿'**
  String get scheduleCalendarDayPosts;

  /// 月のカレンダー：選んだ日のパネルの投稿の件数
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String schedulePostCount(int count);

  /// 予定の詳細：配信の予定の種類
  ///
  /// In ja, this message translates to:
  /// **'配信の予定'**
  String get scheduleDetailLiveKind;

  /// 予定の詳細：終わった配信の状態
  ///
  /// In ja, this message translates to:
  /// **'終了しました'**
  String get scheduleDetailEnded;

  /// 予定の詳細：これからの配信の状態
  ///
  /// In ja, this message translates to:
  /// **'これから'**
  String get scheduleDetailUpcoming;

  /// 共通：予定の詳細・イベントの詳細・イベントの管理の、終日の予定の日付
  ///
  /// In ja, this message translates to:
  /// **'{date} 終日'**
  String commonScheduleDateAllDay(String date);

  /// 共通：予定の詳細・イベントの詳細・イベントの管理の、日時（終了時刻が未定なら end は空）
  ///
  /// In ja, this message translates to:
  /// **'{date}{start}〜{end}'**
  String commonScheduleDateTime(String date, String start, String end);

  /// 共通：予定の詳細・イベントの詳細の、日をまたぐ予定の日時（終了が開始と別の日）
  ///
  /// In ja, this message translates to:
  /// **'{startDate}{start}〜{endDate}{end}'**
  String commonScheduleDateTimeSpan(
    String startDate,
    String start,
    String endDate,
    String end,
  );

  /// 予定の詳細：終了時刻がないときの補足
  ///
  /// In ja, this message translates to:
  /// **'終了時刻は未定です'**
  String get scheduleDetailEndOpen;

  /// 予定の詳細：リンクの行の補足
  ///
  /// In ja, this message translates to:
  /// **'押すと、外部のページが開きます'**
  String get scheduleDetailLinkHint;

  /// 予定の詳細：この予定を通報する（イベントの公演で、自分がオーナーでないとき）
  ///
  /// In ja, this message translates to:
  /// **'この予定を通報する'**
  String get scheduleDetailReport;

  /// 予定の詳細：リンクを開くボタン
  ///
  /// In ja, this message translates to:
  /// **'リンクを開く'**
  String get scheduleDetailOpenLink;

  /// 予定の詳細：イベントの公演のオーナーにだけ出す、編集のボタン
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get scheduleDetailEdit;

  /// 外部のリンクを開く前の確認のダイアログのタイトル（予定の詳細・月のカレンダー・イベントの詳細など）。本文には行き先のドメインを出す
  ///
  /// In ja, this message translates to:
  /// **'外部のサイトを開きます'**
  String get commonLinkConfirmTitle;

  /// 外部のリンクを開く前の確認のダイアログの、開くボタン
  ///
  /// In ja, this message translates to:
  /// **'開く'**
  String get commonLinkConfirmOpen;

  /// 設定：画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// 設定：ログインが済んだときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'ログインしました'**
  String get settingsSignedIn;

  /// 設定：ログアウトの確認ダイアログのタイトル
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしますか？'**
  String get settingsLogoutConfirmTitle;

  /// 設定：ログアウトの確認ダイアログの本文
  ///
  /// In ja, this message translates to:
  /// **'結び付けたログイン方法で、またログインできます。'**
  String get settingsLogoutConfirmMessage;

  /// 設定：ログアウトの行と、確認ダイアログのボタン
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get settingsLogout;

  /// 設定：ログアウトが済んだときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしました'**
  String get settingsLoggedOut;

  /// 設定：ログアウトに失敗したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'ログアウトできませんでした'**
  String get settingsLogoutFailed;

  /// 設定：通知の行の値（オン）
  ///
  /// In ja, this message translates to:
  /// **'オン'**
  String get settingsOn;

  /// 設定：通知の行の値（オフ）
  ///
  /// In ja, this message translates to:
  /// **'オフ'**
  String get settingsOff;

  /// 設定：通知の行
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get settingsNotifications;

  /// 設定：画面モードの行と、画面モード（シート）のタイトル
  ///
  /// In ja, this message translates to:
  /// **'画面モード'**
  String get settingsDisplayMode;

  /// 設定：言語の行と、言語（シート）のタイトル
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get settingsLanguage;

  /// 設定：発信者として登録する行
  ///
  /// In ja, this message translates to:
  /// **'発信者として登録する'**
  String get settingsRegisterAsCreator;

  /// 設定：アカウントの見出し
  ///
  /// In ja, this message translates to:
  /// **'アカウント'**
  String get settingsSectionAccount;

  /// 設定：ログイン方法の行と、ログイン方法の画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'ログイン方法'**
  String get settingsLoginMethods;

  /// 設定：アカウント作成の前の「発信者として登録する」のカードの注記。発信者として登録：アカウントがないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'先にアカウントを作成してください'**
  String get settingsAccountRequired;

  /// 設定：表示しない発信者の行、表示しない発信者の画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'表示しない発信者'**
  String get settingsHiddenCreators;

  /// 設定：表示しない発信者の人数
  ///
  /// In ja, this message translates to:
  /// **'{count}人'**
  String settingsHiddenCreatorCount(int count);

  /// 表示しない発信者：説明
  ///
  /// In ja, this message translates to:
  /// **'表示しないにした発信者は、検索やタイムラインに出ません。'**
  String get settingsHiddenCreatorsDescription;

  /// 表示しない発信者：1人もいないとき
  ///
  /// In ja, this message translates to:
  /// **'表示しない発信者はいません'**
  String get settingsHiddenCreatorsEmpty;

  /// 表示しない発信者：表示するのボタン
  ///
  /// In ja, this message translates to:
  /// **'表示する'**
  String get settingsHiddenCreatorShow;

  /// 表示しない発信者：戻したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'表示するように戻しました'**
  String get settingsHiddenCreatorRestored;

  /// 表示しない発信者：戻せなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'戻せませんでした'**
  String get settingsHiddenCreatorRestoreFailed;

  /// 設定の行・アカウント作成／ログイン（シート）のタイトル。匿名のときだけ出す。作成かログインかは、アプリが決める
  ///
  /// In ja, this message translates to:
  /// **'アカウント作成／ログイン'**
  String get settingsAccountEntry;

  /// 設定：サポートの見出し
  ///
  /// In ja, this message translates to:
  /// **'サポート'**
  String get settingsSectionSupport;

  /// 共通：設定と発信者メニューのお問い合わせの行と、メールアプリが使えないときのダイアログのタイトル
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get commonContact;

  /// 設定：退会の行と、退会の画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'退会'**
  String get settingsWithdraw;

  /// 発信者メニュー：プロフィールカードの説明（押すとプロフィールの編集へ）
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを編集する'**
  String get creatorAdminMenuProfileCardHint;

  /// 共通（確認済みのチップ）：確認済みの印。SNS の連携・表示するコンテンツ
  ///
  /// In ja, this message translates to:
  /// **'確認済み'**
  String get commonVerified;

  /// 設定：お問い合わせのダイアログ（宛先がまだないとき）
  ///
  /// In ja, this message translates to:
  /// **'宛先のメールアドレスは、準備中です。'**
  String get settingsContactAddressPreparing;

  /// 設定：お問い合わせのダイアログ（宛先の案内）
  ///
  /// In ja, this message translates to:
  /// **'次の宛先に、メールでお問い合わせください。'**
  String get settingsContactByEmail;

  /// 設定：お問い合わせのダイアログのユーザーIDの見出し
  ///
  /// In ja, this message translates to:
  /// **'ユーザーID'**
  String get settingsUserId;

  /// 設定：お問い合わせのダイアログのボタン
  ///
  /// In ja, this message translates to:
  /// **'ユーザーIDをコピー'**
  String get settingsCopyUserId;

  /// 共通：設定と発信者メニューからの、お問い合わせのメールの件名
  ///
  /// In ja, this message translates to:
  /// **'追星へのお問い合わせ'**
  String get commonContactSubject;

  /// 共通：設定と発信者メニューからの、お問い合わせのメールの本文（ユーザーID・アプリのバージョン・OS）
  ///
  /// In ja, this message translates to:
  /// **'\n\n----\nユーザーID: {userId}\nアプリのバージョン: {version}\nOS: {os}\n'**
  String commonContactBody(String userId, String version, String os);

  /// 共通：お問い合わせのメールで、ユーザーIDがないとき
  ///
  /// In ja, this message translates to:
  /// **'（サインインしていません）'**
  String get commonContactNotSignedIn;

  /// ログイン方法：結び付けが済んだときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{provider}のログインを結び付けました'**
  String settingsLoginLinked(String provider);

  /// ログイン方法・ログイン（シート）：アカウントがほかで使われているときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'このアカウントは、ほかのユーザーで使われています'**
  String get settingsAccountAlreadyUsed;

  /// ログイン方法：結び付けに失敗したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'結び付けられませんでした。もう一度お試しください'**
  String get settingsLinkFailed;

  /// ログイン方法：外す確認ダイアログのタイトル
  ///
  /// In ja, this message translates to:
  /// **'{provider}のログインを外しますか？'**
  String settingsUnlinkConfirmTitle(String provider);

  /// ログイン方法：外す確認ダイアログの本文
  ///
  /// In ja, this message translates to:
  /// **'{provider}では、ログインできなくなります。'**
  String settingsUnlinkConfirmMessage(String provider);

  /// ログイン方法：外すボタン
  ///
  /// In ja, this message translates to:
  /// **'外す'**
  String get settingsUnlink;

  /// ログイン方法：外し終えたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{provider}のログインを外しました'**
  String settingsUnlinked(String provider);

  /// ログイン方法：外すのに失敗したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'外せませんでした。もう一度お試しください'**
  String get settingsUnlinkFailed;

  /// ログイン方法：画面の上の説明
  ///
  /// In ja, this message translates to:
  /// **'結び付けたどれかで、別の端末からもログインできます。発信者は、2つ以上がおすすめです。'**
  String get settingsLoginMethodsDescription;

  /// ログイン方法：画面の下の注記
  ///
  /// In ja, this message translates to:
  /// **'SNS のアカウント連携とは別です。ログイン方法を外しても、連携は残ります。'**
  String get settingsLoginMethodsNote;

  /// ログイン方法：結び付けるボタン
  ///
  /// In ja, this message translates to:
  /// **'結び付ける'**
  String get settingsLink;

  /// ログイン方法：結び付け済みで、アカウント名がないときの表示
  ///
  /// In ja, this message translates to:
  /// **'設定済み'**
  String get settingsLoginMethodSet;

  /// ログイン（シート）・本人の確認（シート）：ログインに失敗したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'ログインできませんでした。もう一度お試しください'**
  String get settingsLoginFailed;

  /// アカウント作成／ログイン（シート）の下の小さな入口と、アプリ運営用ログインの画面のタイトル（画面定義書 2.1.11）。「運営用」だけにしない（発信者のチームの運営と取り違えるため）
  ///
  /// In ja, this message translates to:
  /// **'アプリ運営用ログイン'**
  String get settingsAdminLogin;

  /// アプリ運営用ログイン：説明
  ///
  /// In ja, this message translates to:
  /// **'運営が用意したアカウントで入ります。新しい登録はできません。'**
  String get settingsAdminLoginLead;

  /// アプリ運営用ログイン：入力欄のラベル
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get settingsAdminLoginEmail;

  /// アプリ運営用ログイン：入力欄のラベル
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get settingsAdminLoginPassword;

  /// アプリ運営用ログイン：ボタン
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get settingsAdminLoginSubmit;

  /// アプリ運営用ログイン：メールアドレスかパスワードが違うときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスかパスワードが違います'**
  String get settingsAdminLoginInvalid;

  /// アプリ運営用ログイン：5回続けて違った（端末で5分）か、サーバーの回数の制限のときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'しばらくしてからやり直してください'**
  String get settingsAdminLoginTooMany;

  /// アカウント作成／ログイン（シート）：ウェルカムの「発信者の方はこちら」から開いたときに出す一言
  ///
  /// In ja, this message translates to:
  /// **'発信者として登録するには、アカウントが要ります。'**
  String get settingsLoginSheetCreatorLead;

  /// アカウント作成／ログイン（シート）：アカウントを作ったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'アカウントを作成しました'**
  String get settingsAccountCreated;

  /// アカウント作成／ログイン（シート）：Apple のボタン（Apple が決めた文言）
  ///
  /// In ja, this message translates to:
  /// **'Appleで続ける'**
  String get settingsContinueWithApple;

  /// アカウント作成／ログイン（シート）：Google のボタン（Google が決めた文言）
  ///
  /// In ja, this message translates to:
  /// **'Google で続行'**
  String get settingsContinueWithGoogle;

  /// ログイン（シート）・本人の確認（シート）：Apple のログインのボタン（Apple が決めた文言）
  ///
  /// In ja, this message translates to:
  /// **'Appleでサインイン'**
  String get settingsLoginWithApple;

  /// ログイン（シート）・本人の確認（シート）：Google のログインのボタン（Google が決めた文言）
  ///
  /// In ja, this message translates to:
  /// **'Google でログイン'**
  String get settingsLoginWithGoogle;

  /// アカウント作成／ログイン（シート）：X・Twitch のボタン
  ///
  /// In ja, this message translates to:
  /// **'{provider}で続ける'**
  String settingsContinueWith(String provider);

  /// ログイン（シート）・本人の確認（シート）：ログインのボタン
  ///
  /// In ja, this message translates to:
  /// **'{provider}でログイン'**
  String settingsLoginWith(String provider);

  /// 通知設定：画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get settingsNotificationSettingsTitle;

  /// 通知設定：端末の通知が許可されていないときの案内
  ///
  /// In ja, this message translates to:
  /// **'端末の通知がオフになっています。配信の開始や予定をお知らせするには、端末の設定で通知を許可してください。'**
  String get settingsDeviceNotificationsOff;

  /// 通知設定：端末の設定を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'端末の設定を開く'**
  String get settingsOpenDeviceSettings;

  /// 通知設定：通知の許可を一度も求めていないときの案内（許可カード）
  ///
  /// In ja, this message translates to:
  /// **'通知を許可すると、推しの配信の開始と予定をお知らせします。'**
  String get settingsNotificationPermissionPrompt;

  /// 通知設定：OS の通知の許可の画面を出すボタン
  ///
  /// In ja, this message translates to:
  /// **'通知を許可する'**
  String get settingsAllowNotifications;

  /// 通知設定：全体のスイッチの名前
  ///
  /// In ja, this message translates to:
  /// **'配信と予定の通知'**
  String get settingsLiveStartNotification;

  /// 通知設定：全体のスイッチの説明
  ///
  /// In ja, this message translates to:
  /// **'推しが配信を始めたときと、予定の前に、お知らせします'**
  String get settingsLiveStartNotificationDescription;

  /// 通知設定：画面の下の注記
  ///
  /// In ja, this message translates to:
  /// **'推しごとの通知は、それぞれの推しのページで変えられます。'**
  String get settingsPerCreatorNotificationNote;

  /// 本人の確認：ログイン方法を読めなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'読み込めませんでした。もう一度お試しください'**
  String get settingsReauthLoadFailed;

  /// 本人の確認（シート）：退会で Apple のひも付けを取り消すときの説明
  ///
  /// In ja, this message translates to:
  /// **'Apple でのサインインのひも付けも取り消すため、Apple で、もう一度ログインしてください。'**
  String get settingsReauthAppleMessage;

  /// 本人の確認（シート）：違うアカウントでログインしたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'結び付けたアカウントで、ログインしてください'**
  String get settingsWrongAccount;

  /// 本人の確認（シート）：タイトル
  ///
  /// In ja, this message translates to:
  /// **'本人の確認'**
  String get settingsReauthTitle;

  /// 本人の確認（シート）：この端末で使えるログイン方法がないときの説明
  ///
  /// In ja, this message translates to:
  /// **'この端末では、結び付けたログイン方法を使えません。iPhone で操作してください。'**
  String get settingsReauthUnavailable;

  /// 本人の確認（シート）：いつもの説明
  ///
  /// In ja, this message translates to:
  /// **'大事な操作の前に、結び付けたログイン方法で、もう一度ログインしてください。'**
  String get settingsReauthMessage;

  /// 退会：画面の説明
  ///
  /// In ja, this message translates to:
  /// **'退会すると、フォロー中の推し、通知や表示の設定が、すべて削除されます。この操作は取り消せません。'**
  String get settingsWithdrawWarning;

  /// 退会：Apple を結び付けていて、iOS 以外の端末のときの注記
  ///
  /// In ja, this message translates to:
  /// **'この端末では、Apple でのサインインのひも付けを取り消せません。iPhone で退会するか、退会のあとに、iPhone の設定の「Apple でサインイン」から外してください。'**
  String get settingsWithdrawAppleElsewhere;

  /// 退会：ログイン方法が Apple だけで、iOS 以外の端末のときの注記（退会するボタンは押せない）
  ///
  /// In ja, this message translates to:
  /// **'Apple だけでログインしているので、この端末では本人の確認ができません。iPhone で退会してください。'**
  String get settingsWithdrawAppleOnly;

  /// 退会：退会するボタン
  ///
  /// In ja, this message translates to:
  /// **'退会する'**
  String get settingsWithdrawButton;

  /// 退会：失敗したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'退会できませんでした'**
  String get settingsWithdrawFailed;

  /// アカウント連携：オーナーが退会した発信者のアカウントだったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'オーナーが退会した発信者のアカウントです。登録の画面から、取り戻せます'**
  String get creatorAdminLinkReclaimable;

  /// アカウント連携：登録済みの発信者の連携の解除の確認ダイアログの説明
  ///
  /// In ja, this message translates to:
  /// **'すぐに、追星に表示されなくなります。取得した投稿・配信・予定・実績は、90日残してから消します。90日のうちに、同じアカウントを連携し直すと、元に戻ります。'**
  String get creatorAdminUnlinkConfirmHeldMessage;

  /// 退会：発信者のオーナーへの説明
  ///
  /// In ja, this message translates to:
  /// **'あなたの発信者は、すぐに追星に表示されなくなり、90日後に消えます。90日のうちなら、発信者として登録の画面で、同じSNSのアカウントを連携すると、取り戻せます。'**
  String get settingsWithdrawCreatorNote;

  /// 退会：プランに加入中か、加入中かを読み込めないときの注意
  ///
  /// In ja, this message translates to:
  /// **'退会しても、ストアのサブスクは解約されません。先に、サブスクの管理から解約してください。'**
  String get settingsWithdrawSubscriptionNote;

  /// 退会：ストアのサブスクの管理を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'サブスクの管理を開く'**
  String get settingsWithdrawManageSubscription;

  /// プロフィールの編集：タイプの欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'タイプ'**
  String get creatorAdminProfileTypesLabel;

  /// プロフィールの編集：タイプの欄の注記
  ///
  /// In ja, this message translates to:
  /// **'{count}つまで選べます。おすすめに使います。'**
  String creatorAdminProfileTypesNote(int count);

  /// プロフィールの編集：タイプを読み込めなかったとき
  ///
  /// In ja, this message translates to:
  /// **'タイプを読み込めませんでした'**
  String get creatorAdminProfileTypesLoadFailed;

  /// 取り戻し：取り戻せたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'{name}を取り戻しました'**
  String creatorAdminReclaimed(String name);

  /// 取り戻し：もう取り戻せないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'この発信者は、もう取り戻せません'**
  String get creatorAdminReclaimNotReclaimable;

  /// 取り戻し：連携したアカウントがほかの発信者で使われているときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'連携したアカウントが、ほかの発信者で使われています'**
  String get creatorAdminReclaimDuplicate;

  /// 取り戻し：失敗したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'取り戻せませんでした。もう一度お試しください'**
  String get creatorAdminReclaimFailed;

  /// 取り戻しの案内：見出し
  ///
  /// In ja, this message translates to:
  /// **'発信者を取り戻せます'**
  String get creatorAdminReclaimTitle;

  /// 取り戻しの案内：説明。{plan} は、基本プランの発信者なら creatorAdminReclaimNeedsPlan、永年無料・運営・確認用なら空
  ///
  /// In ja, this message translates to:
  /// **'連携したアカウントの発信者「{name}」（@{id}）は、オーナーの退会で、いまは追星に表示されていません。{date}までに取り戻すと、プロフィール・連携・予定が、そのまま戻ります。{plan}'**
  String creatorAdminReclaimMessage(
    String name,
    String id,
    String date,
    String plan,
  );

  /// 登録：取り戻しの案内の最後に添える文（基本プランの発信者のとき。X の連携の引き継ぎ）
  ///
  /// In ja, this message translates to:
  /// **'X連携プランに加入していたなら、取り戻したあとに、プランの画面の「購入を復元」で引き継げます。'**
  String get creatorAdminReclaimNeedsPlan;

  /// 取り戻しの案内：ボタン
  ///
  /// In ja, this message translates to:
  /// **'取り戻す'**
  String get creatorAdminReclaimAction;

  /// 共通（投稿の行）：投稿の種類と、投稿からの時間を並べる
  ///
  /// In ja, this message translates to:
  /// **'{kind} ・ {time}'**
  String commonPostKindTime(String kind, String time);

  /// 共通（投稿の行）：SNS の名前と、投稿の時刻を並べる
  ///
  /// In ja, this message translates to:
  /// **'{service} ・ {time}'**
  String commonServiceTime(String service, String time);

  /// プロフィールの編集：ID の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'ID'**
  String get creatorAdminProfileIdLabel;

  /// 【仮】Instagram の DM での確認：シートの見出し
  ///
  /// In ja, this message translates to:
  /// **'Instagram を DM で確認'**
  String get creatorAdminDmTitle;

  /// 【仮】Instagram の DM での確認：コードを出す前の説明。account は受け先
  ///
  /// In ja, this message translates to:
  /// **'Instagram のユーザー名を入れて、コードを出してください。そのアカウントから、運営の Instagram（@{account}）にコードを DM で送ると、運営が確かめて「確認済み」にします。'**
  String creatorAdminDmIntro(String account);

  /// 【仮】Instagram の DM での確認：ユーザー名の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'Instagram のユーザー名'**
  String get creatorAdminDmUsernameLabel;

  /// 【仮】Instagram の DM での確認：コードを出すボタン
  ///
  /// In ja, this message translates to:
  /// **'コードを出す'**
  String get creatorAdminDmRequest;

  /// 【仮】Instagram の DM での確認：確かめるアカウント
  ///
  /// In ja, this message translates to:
  /// **'確かめるアカウント：@{account}'**
  String creatorAdminDmTarget(String account);

  /// 【仮】Instagram の DM での確認：コードをコピーするボタン
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get creatorAdminDmCopy;

  /// 【仮】Instagram の DM での確認：コピーしたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'コードをコピーしました'**
  String get creatorAdminDmCopied;

  /// 【仮】Instagram の DM での確認：DM の送り先
  ///
  /// In ja, this message translates to:
  /// **'送り先：@{account}'**
  String creatorAdminDmSendTo(String account);

  /// 【仮】Instagram の DM での確認：Instagram を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'Instagram で DM を送る'**
  String get creatorAdminDmOpen;

  /// 【仮】Instagram の DM での確認：コードを出したあとの注記。date は期限の日付
  ///
  /// In ja, this message translates to:
  /// **'運営が確かめるまで、数日かかることがあります。コードの期限は {date} までです。'**
  String creatorAdminDmNote(String date);

  /// 【仮】Instagram の DM での確認：コードを取り消すボタン
  ///
  /// In ja, this message translates to:
  /// **'取り消す'**
  String get creatorAdminDmCancel;

  /// 【仮】Instagram の DM での確認：ユーザー名の形が違うときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'Instagram のユーザー名を確かめてください'**
  String get creatorAdminDmInvalid;

  /// 【仮】Instagram の DM での確認：コードを出せないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'コードを出せませんでした。もう一度お試しください'**
  String get creatorAdminDmFailed;

  /// 【仮】Instagram の DM での確認：取り消せないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'取り消せませんでした。もう一度お試しください'**
  String get creatorAdminDmCancelFailed;

  /// 【仮】Instagram の DM での確認：アカウント連携の行の、確認を待っているチップ
  ///
  /// In ja, this message translates to:
  /// **'確認待ち'**
  String get creatorAdminDmPending;

  /// イベントの登録：画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'イベントの登録'**
  String get eventRegisterTitle;

  /// イベントの登録：URL の欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'チケットの URL'**
  String get eventRegisterUrlLabel;

  /// イベントの登録：URL の欄の補足
  ///
  /// In ja, this message translates to:
  /// **'チケットのページを開いて、タイトル・日時・会場を読み取ります。読み取れなかった項目は、手で入れてください。'**
  String get eventRegisterUrlHint;

  /// イベントの登録：URL を読み取るボタン
  ///
  /// In ja, this message translates to:
  /// **'読み取る'**
  String get eventRegisterRead;

  /// イベントの登録：読み取れたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'読み取りました。内容を確かめてください'**
  String get eventRegisterReadDone;

  /// イベントの登録：読み取れなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'読み取れませんでした。手で入れてください'**
  String get eventRegisterReadFailed;

  /// イベントの登録：公演のカードの見出し
  ///
  /// In ja, this message translates to:
  /// **'公演'**
  String get eventRegisterPerformance;

  /// 公演を選ぶ（シート）：タイトル
  ///
  /// In ja, this message translates to:
  /// **'公演を選ぶ'**
  String get performancePickerTitle;

  /// 公演を選ぶ（シート）：注記
  ///
  /// In ja, this message translates to:
  /// **'1つのイベントには、1つの公演を登録します。'**
  String get performancePickerNote;

  /// イベントの登録：保存できたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'イベントを登録しました'**
  String get eventRegisterSaved;

  /// ページから読み取る：読み取るボタン
  ///
  /// In ja, this message translates to:
  /// **'このページから読み取る'**
  String get eventPageReaderRead;

  /// ページから読み取る：ボタンの上の注記
  ///
  /// In ja, this message translates to:
  /// **'表示しているページから、タイトル・日時・会場を読み取ります。'**
  String get eventPageReaderNote;

  /// ページから読み取る：公演の候補から開いたときの、登録のボタン
  ///
  /// In ja, this message translates to:
  /// **'このイベントを登録'**
  String get eventPageReaderRegister;

  /// ページから読み取る：ページにあったイベントへのリンクから選ぶボタン
  ///
  /// In ja, this message translates to:
  /// **'このページのイベントから選ぶ（{count}件）'**
  String eventPageReaderCandidates(int count);

  /// イベントの候補：画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'イベントの候補'**
  String get eventCandidatesTitle;

  /// イベントの候補：一覧の上の注記
  ///
  /// In ja, this message translates to:
  /// **'押すとページを開きます。内容を確かめて、「このイベントを登録」を押してください。'**
  String get eventCandidatesNote;

  /// イベントの候補：登録済みのチップ
  ///
  /// In ja, this message translates to:
  /// **'登録済み'**
  String get eventCandidatesRegistered;

  /// ページから読み取る：公演の「ページから時刻を読む」から開いたときのボタン
  ///
  /// In ja, this message translates to:
  /// **'このページから時刻を読む'**
  String get eventPageReaderReadTime;

  /// イベントの候補：時刻未定の公演があるイベントを登録できたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'イベントを登録しました。時刻未定の公演は、編集で時刻を足せます'**
  String get eventCandidatesSavedTimeTbd;

  /// チケットサイトで探す：画面の見出しと、イベントの登録の行
  ///
  /// In ja, this message translates to:
  /// **'チケットサイトで探す'**
  String get eventSearchTitle;

  /// チケットサイトで探す：名前の入力欄
  ///
  /// In ja, this message translates to:
  /// **'アーティスト名'**
  String get eventSearchName;

  /// チケットサイトで探す：サイトの一覧の上の注記
  ///
  /// In ja, this message translates to:
  /// **'チケットぴあ・イープラス・ローチケ・楽天チケットで、この名前のアーティストを探します。同じ名前の別の人も出るので、確かめてから選んでください。'**
  String get eventSearchNote;

  /// イベントの登録：公演の、開演の時刻が決まっていないときのスイッチ
  ///
  /// In ja, this message translates to:
  /// **'時刻未定'**
  String get eventRegisterTimeTbd;

  /// イベントの登録：時刻未定のスイッチの説明
  ///
  /// In ja, this message translates to:
  /// **'開演の時刻が決まっていない・分からない公演'**
  String get eventRegisterTimeTbdHint;

  /// イベントの登録：時刻未定の公演の、公演のページを開いて時刻を読むボタン
  ///
  /// In ja, this message translates to:
  /// **'ページから時刻を読む'**
  String get eventRegisterReadTime;

  /// イベントの登録：時刻を読み取れたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'時刻を読み取りました'**
  String get eventRegisterTimeRead;

  /// イベントの登録：時刻を読み取れなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'時刻を読み取れませんでした'**
  String get eventRegisterTimeReadFailed;

  /// イベントの公演で、開演の時刻が決まっていないときの表示
  ///
  /// In ja, this message translates to:
  /// **'時刻未定'**
  String get commonTimeTbd;

  /// 共通：予定の詳細・イベントの詳細・イベントの管理の、イベントの公演で時刻未定のときの日時
  ///
  /// In ja, this message translates to:
  /// **'{date} 時刻未定'**
  String commonScheduleDateTimeTbd(String date);

  /// チケットサイトで探す：探すボタン
  ///
  /// In ja, this message translates to:
  /// **'探す'**
  String get eventSearchButton;

  /// チケットサイトで探す：ヒットしたアーティストがないとき
  ///
  /// In ja, this message translates to:
  /// **'アーティストが見つかりませんでした'**
  String get eventSearchNoArtist;

  /// イベントの候補：アーティストのページにイベントがないとき
  ///
  /// In ja, this message translates to:
  /// **'イベントが見つかりませんでした'**
  String get eventCandidatesEmpty;

  /// 公演の候補：一覧の上の注記
  ///
  /// In ja, this message translates to:
  /// **'押すと公演のページを開きます。内容を確かめて、「このイベントを登録」を押してください。'**
  String get performanceCandidatesNote;

  /// 公演の候補：これからの公演が1つもないとき
  ///
  /// In ja, this message translates to:
  /// **'公演が見つかりませんでした'**
  String get performanceCandidatesEmpty;

  /// 公演の候補：イベントのページを開いているあいだの表示
  ///
  /// In ja, this message translates to:
  /// **'公演を集めています（{done}/{total}）'**
  String performanceCandidatesLoading(int done, int total);

  /// 公演の候補：開けなかったページがあるとき
  ///
  /// In ja, this message translates to:
  /// **'読み込めなかったページが {count} 件あります'**
  String performanceCandidatesFailedEvents(int count);

  /// 公演の候補：画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'公演の候補'**
  String get performanceCandidatesTitle;

  /// チケットサイトで探す：選んだアーティストの公演を見るボタン
  ///
  /// In ja, this message translates to:
  /// **'公演を見る（{count}件）'**
  String eventSearchShowPerformances(int count);

  /// チケットサイトで探す：サイトがメンテナンス中のとき
  ///
  /// In ja, this message translates to:
  /// **'メンテナンス中のため、いまは探せません'**
  String get eventSearchMaintenance;

  /// チケットサイトで探す：楽天チケットの、名前を含むイベントの行
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を含むイベント（{count}件）'**
  String eventSearchRakutenEvents(String name, int count);

  /// イベントの編集：保存できたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'イベントを保存しました'**
  String get eventRegisterUpdated;

  /// イベントの登録：同じチケットのページを指すリンクが、ほかのイベントにあるとき
  ///
  /// In ja, this message translates to:
  /// **'このチケットリンクは、ほかのイベントで登録済みです'**
  String get eventRegisterDuplicateLink;

  /// イベントの編集：消す前の確認の見出し
  ///
  /// In ja, this message translates to:
  /// **'このイベントを消しますか？'**
  String get eventRegisterDeleteConfirmTitle;

  /// イベントの編集：消す前の確認の本文
  ///
  /// In ja, this message translates to:
  /// **'公演とチケットリンクも消えます。'**
  String get eventRegisterDeleteConfirmMessage;

  /// イベントの編集：画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'イベントの編集'**
  String get eventEditTitle;

  /// イベントの登録：リンクの欄の見出し
  ///
  /// In ja, this message translates to:
  /// **'チケットリンク'**
  String get eventRegisterLinksLabel;

  /// イベントの登録：リンクを足すボタン
  ///
  /// In ja, this message translates to:
  /// **'＋ チケットリンクを足す'**
  String get eventRegisterAddLink;

  /// イベントの登録：リンクを消すボタンの読み上げ
  ///
  /// In ja, this message translates to:
  /// **'このチケットリンクを消す'**
  String get eventRegisterRemoveLink;

  /// イベントの編集：消す行
  ///
  /// In ja, this message translates to:
  /// **'このイベントを消す'**
  String get eventRegisterDelete;

  /// イベントの詳細：リンクのボタン。site はサイトの名前（チケットぴあ・イープラスなど）
  ///
  /// In ja, this message translates to:
  /// **'{site}で購入'**
  String eventDetailOpenSite(String site);

  /// 発信者ページのメニュー・発信者メニュー：発信者の共有のリンクを共有する（仮）
  ///
  /// In ja, this message translates to:
  /// **'リンクを共有'**
  String get shareLinkAction;

  /// 共有シートに渡す文。{name} は発信者の名前、{link} は共有のリンク
  ///
  /// In ja, this message translates to:
  /// **'{name}の配信と予定を、追星で追えます\n{link}'**
  String shareLinkMessage(String name, String link);

  /// リンクの共有：発信者がファンに見せない状態のとき
  ///
  /// In ja, this message translates to:
  /// **'ファンに見せていない状態のため、リンクを共有できません（確認済みのアカウントがない、または停止中です）'**
  String get shareLinkUnavailable;

  /// リンクの共有：確かめられない・共有シートを開けないとき
  ///
  /// In ja, this message translates to:
  /// **'リンクを共有できませんでした'**
  String get shareLinkFailed;

  /// ホーム：共有のリンクから開いたが、発信者がない・ファンに見せない状態のとき
  ///
  /// In ja, this message translates to:
  /// **'リンクの発信者が見つかりませんでした'**
  String get shareLinkNotFound;

  /// 「リンクを共有」の画面：タイトル
  ///
  /// In ja, this message translates to:
  /// **'リンクを共有'**
  String get shareLinkTitle;

  /// 「リンクを共有」の画面：共有シートを開くボタン
  ///
  /// In ja, this message translates to:
  /// **'リンクを共有する'**
  String get shareLinkShareButton;

  /// 「リンクを共有」の画面：QR の画像を共有シートに渡すボタン（「画像を保存」で写真に保存できる）
  ///
  /// In ja, this message translates to:
  /// **'QR を画像で保存・共有'**
  String get shareLinkSaveQr;

  /// 「リンクを共有」の画面：下の注記
  ///
  /// In ja, this message translates to:
  /// **'リンクや QR から開いた人は、アプリが無ければ App Store へ進み、入れて開くとこの発信者をフォローした状態で始まります。アプリがあれば、このページへ進みます。'**
  String get shareLinkNote;

  /// 「リンクを共有」の画面：リンクを写したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'リンクをコピーしました'**
  String get shareLinkCopied;

  /// 「リンクを共有」の画面：リンクの行のコピーの印（読み上げ）
  ///
  /// In ja, this message translates to:
  /// **'リンクをコピー'**
  String get shareLinkCopy;

  /// 「リンクを共有」の画面：QR の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'共有のリンクの QR'**
  String get shareLinkQrLabel;

  /// 「リンクを共有」の画面：発信者がファンに見せない状態のときの見出し
  ///
  /// In ja, this message translates to:
  /// **'まだ共有できません'**
  String get shareLinkUnavailableTitle;

  /// 追いたい：ヘッダーのタイトル。推しを探すのヘッダーのアイコンの名前にも使う
  ///
  /// In ja, this message translates to:
  /// **'追いたい'**
  String get wantTitle;

  /// 追いたい：上の説明
  ///
  /// In ja, this message translates to:
  /// **'追星にまだいない人を、SNS の URL か ID で申告できます。その人が追星に来たら、お知らせして自動でフォローします。'**
  String get wantIntro;

  /// 追いたい：SNS のチップのラベル
  ///
  /// In ja, this message translates to:
  /// **'SNS（ID だけのときに選ぶ）'**
  String get wantServiceLabel;

  /// 追いたい：入力欄のラベル
  ///
  /// In ja, this message translates to:
  /// **'URL か ID'**
  String get wantInputLabel;

  /// 追いたい：入力欄のプレースホルダ
  ///
  /// In ja, this message translates to:
  /// **'https://x.com/… や @ID'**
  String get wantInputHint;

  /// 追いたい：読み取った ID の前のラベル
  ///
  /// In ja, this message translates to:
  /// **'申告する ID'**
  String get wantParsed;

  /// 追いたい：申告するボタン
  ///
  /// In ja, this message translates to:
  /// **'追いたい'**
  String get wantSubmit;

  /// 追いたい：ボタンの下の注記
  ///
  /// In ja, this message translates to:
  /// **'追星が持つのは、SNS と ID と押した人数だけです。誰が押したかは、ほかの人に見せません。'**
  String get wantPrivacyNote;

  /// 追いたい：自分が押した一覧の見出し
  ///
  /// In ja, this message translates to:
  /// **'あなたの追いたい'**
  String get wantListTitle;

  /// 追いたい：自分が押した一覧が空のとき
  ///
  /// In ja, this message translates to:
  /// **'まだ追いたいはありません'**
  String get wantListEmpty;

  /// 追いたい：一覧の行の、押した人数（自分を含む）
  ///
  /// In ja, this message translates to:
  /// **'{count}人が追いたい'**
  String wantCount(int count);

  /// 追いたい：一覧の行の、未登録のアカウントの印
  ///
  /// In ja, this message translates to:
  /// **'本人確認なし'**
  String get wantUnverified;

  /// 追いたい：一覧の行の、取り消すボタン
  ///
  /// In ja, this message translates to:
  /// **'取り消す'**
  String get wantCancel;

  /// 追いたい：押せたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'追いたいにしました'**
  String get wantAdded;

  /// 追いたい：確認済みのアカウントだったときのスナックバー（発信者ページを開く）
  ///
  /// In ja, this message translates to:
  /// **'この人は、もう追星にいます'**
  String get wantAlreadyHere;

  /// 追いたい：1日の上限に達したときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'今日はこれ以上申告できません'**
  String get wantLimit;

  /// 追いたい：URL・ID の形が分からないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'この形の URL は読めません'**
  String get wantInvalid;

  /// 追いたい：ID だけで SNS を選んでいないときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'ID だけのときは、SNS を選んでください'**
  String get wantChooseService;

  /// 追いたい：送れなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'申告できませんでした'**
  String get wantFailed;

  /// 追いたい：取り消せなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'取り消せませんでした'**
  String get wantCancelFailed;

  /// 推しを探す（結果なし）：追いたいへ進むボタン
  ///
  /// In ja, this message translates to:
  /// **'追いたいで申告する'**
  String get oshiFindWantButton;

  /// 発信者メニュー・告知画像の画面：タイトル
  ///
  /// In ja, this message translates to:
  /// **'週間の告知画像'**
  String get announceImageTitle;

  /// 告知画像の画面：週を選ぶ
  ///
  /// In ja, this message translates to:
  /// **'今週'**
  String get announceImageThisWeek;

  /// 告知画像の画面：週を選ぶ
  ///
  /// In ja, this message translates to:
  /// **'来週'**
  String get announceImageNextWeek;

  /// 告知画像の画面：共有シートを開くボタン
  ///
  /// In ja, this message translates to:
  /// **'画像とリンクを共有'**
  String get announceImageShare;

  /// 告知画像の画面：下の注記
  ///
  /// In ja, this message translates to:
  /// **'共有シートの「画像を保存」で、写真に保存できます。'**
  String get announceImageNote;

  /// 告知画像の画面：共有できなかったときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'画像を共有できませんでした'**
  String get announceImageShareFailed;

  /// 週間の告知画像：アイコンの代わりに使う画像を、端末の写真から選ぶボタン
  ///
  /// In ja, this message translates to:
  /// **'画像を変える'**
  String get announceImageChangePhoto;

  /// 週間の告知画像：選んだ画像を外して、アイコンに戻すボタン
  ///
  /// In ja, this message translates to:
  /// **'アイコンに戻す'**
  String get announceImageResetPhoto;

  /// 週間の告知画像：画像を変えるボタンの下の注記
  ///
  /// In ja, this message translates to:
  /// **'画像は真ん中で切り抜きます。どのテンプレでも同じ画像を使います。'**
  String get announceImagePhotoNote;

  /// 週間の告知画像：サーバーで画像を作れなかったとき
  ///
  /// In ja, this message translates to:
  /// **'画像を作れませんでした'**
  String get announceImageRenderFailed;

  /// 週間の告知画像：サーバーで画像を作っている間、見本の枠に出す文
  ///
  /// In ja, this message translates to:
  /// **'画像を作っています'**
  String get announceImageRendering;

  /// 週間の告知画像：選んだ画像を上げられなかったとき（スナックバー）
  ///
  /// In ja, this message translates to:
  /// **'画像を変えられませんでした'**
  String get announceImagePhotoFailed;

  /// 週間の告知画像と一緒に共有する文の見出し。range は 11/16–11/22 の形
  ///
  /// In ja, this message translates to:
  /// **'{name}の週間の予定（{range}）'**
  String announceShareHeading(String name, String range);

  /// 共有する文の最後、誘う用のリンクの前に置く1行
  ///
  /// In ja, this message translates to:
  /// **'▼追星で通知を受け取る'**
  String get announceShareInvite;

  /// 週間の告知画像の画面で、共有する文の見本の見出し
  ///
  /// In ja, this message translates to:
  /// **'一緒に共有する文'**
  String get announceShareTextLabel;

  /// 共有する文をクリップボードに写すボタン
  ///
  /// In ja, this message translates to:
  /// **'文をコピー'**
  String get announceShareCopy;

  /// 共有する文をコピーしたときのスナックバー
  ///
  /// In ja, this message translates to:
  /// **'文をコピーしました'**
  String get announceShareCopied;

  /// 週間の告知画像の画面の注記
  ///
  /// In ja, this message translates to:
  /// **'Instagram では文が投稿に入りません。「文をコピー」で写して、キャプションに貼り付けてください。'**
  String get announceShareInstagramNote;

  /// 週間の告知画像：共有の文のリンクが押された数の見出し
  ///
  /// In ja, this message translates to:
  /// **'リンクが押された数'**
  String get announceLinkCountsLabel;

  /// 週間の告知画像：押された数の行で、誘う用のリンクの名前
  ///
  /// In ja, this message translates to:
  /// **'追星に誘うリンク'**
  String get announceLinkInvite;

  /// 週間の告知画像：リンクが押された数
  ///
  /// In ja, this message translates to:
  /// **'{count}回'**
  String announceLinkCount(int count);

  /// 発信者メニュー・数の画面：タイトル
  ///
  /// In ja, this message translates to:
  /// **'届いた数'**
  String get reachTitle;

  /// 数の画面：合計の見出し。{from}・{to} は期間の最初と最後の日
  ///
  /// In ja, this message translates to:
  /// **'直近30日（{from}〜{to}）'**
  String reachLast30Days(String from, String to);

  /// 数の画面：通知を届けた人数
  ///
  /// In ja, this message translates to:
  /// **'通知を届けた人'**
  String get reachDelivered;

  /// 数の画面：通知から開いた人数
  ///
  /// In ja, this message translates to:
  /// **'通知から来た人'**
  String get reachOpened;

  /// 数の画面：予定の詳細を開いた人数
  ///
  /// In ja, this message translates to:
  /// **'予定を見た人'**
  String get reachViewed;

  /// 数の画面：期間の最後の日のフォロワー数
  ///
  /// In ja, this message translates to:
  /// **'フォロワー'**
  String get reachFollowers;

  /// 数の画面：フォロワーの増減
  ///
  /// In ja, this message translates to:
  /// **'30日で {change}（フォロー {followed}・解除 {unfollowed}）'**
  String reachFollowChange(String change, int followed, int unfollowed);

  /// 数の画面：配信・予定ごとの見出し
  ///
  /// In ja, this message translates to:
  /// **'配信・予定ごと'**
  String get reachBySubject;

  /// 数の画面：配信・予定ごとの数がないとき
  ///
  /// In ja, this message translates to:
  /// **'まだありません。配信開始や予定の通知を送ると、ここに数が出ます。'**
  String get reachBySubjectEmpty;

  /// 数の画面：配信の行の種類
  ///
  /// In ja, this message translates to:
  /// **'配信'**
  String get reachKindLive;

  /// 数の画面：予定の行の種類
  ///
  /// In ja, this message translates to:
  /// **'予定'**
  String get reachKindSchedule;

  /// 数の画面：消された予定の行のタイトル
  ///
  /// In ja, this message translates to:
  /// **'消された予定'**
  String get reachDeletedSchedule;

  /// 数の画面：配信・予定ごとの届けた人数
  ///
  /// In ja, this message translates to:
  /// **'届けた {count}'**
  String reachCountDelivered(int count);

  /// 数の画面：配信・予定ごとの通知から来た人数
  ///
  /// In ja, this message translates to:
  /// **'来た {count}'**
  String reachCountOpened(int count);

  /// 数の画面：予定ごとの見た人数
  ///
  /// In ja, this message translates to:
  /// **'見た {count}'**
  String reachCountViewed(int count);

  /// 数の画面：下の注記
  ///
  /// In ja, this message translates to:
  /// **'数は毎日0時すぎに、前の日までの分を足します。人数はその日ごとに数え、誰が見たかは出しません。投稿の数は、誰が見たかを残さずに回数だけを数えます。チームメンバー自身が見た分は、どの数にも入りません。'**
  String get reachNote;

  /// 数の画面：投稿が見られた数の見出し（届ける・広める仕様書 4.2.3）
  ///
  /// In ja, this message translates to:
  /// **'投稿'**
  String get reachPosts;

  /// 数の画面：投稿のカードが画面に出た回数の行
  ///
  /// In ja, this message translates to:
  /// **'投稿が表示された回数'**
  String get reachPostShown;

  /// 数の画面：投稿ビューアで投稿が出た回数の行
  ///
  /// In ja, this message translates to:
  /// **'投稿を開いた回数'**
  String get reachPostOpened;

  /// 発信者メニュー・リンク集の画面：タイトル
  ///
  /// In ja, this message translates to:
  /// **'SNSリンク集'**
  String get creatorLinksTitle;

  /// リンク集：上の説明
  ///
  /// In ja, this message translates to:
  /// **'発信者ページと共有のページに、ボタンで並びます。'**
  String get creatorLinksLead;

  /// リンク集：1件もないとき
  ///
  /// In ja, this message translates to:
  /// **'まだリンクがありません。好きなリンクを足すと、発信者ページに並びます。'**
  String get creatorLinksEmpty;

  /// リンク集：追加のボタンとシートの見出し
  ///
  /// In ja, this message translates to:
  /// **'リンクを追加'**
  String get creatorLinksAdd;

  /// リンクの編集のシート：見出し
  ///
  /// In ja, this message translates to:
  /// **'リンクを編集'**
  String get creatorLinksEdit;

  /// リンク集：押された数
  ///
  /// In ja, this message translates to:
  /// **'{count}回'**
  String creatorLinksClicks(String count);

  /// リンク集の着地の画面の、公開のページの URL を共有シートに渡すボタン（画面定義書（設定・発信者）2.3.17）
  ///
  /// In ja, this message translates to:
  /// **'共有'**
  String get creatorLinksShareButton;

  /// リンク集の着地の画面の、リンク集の編集（2.3.19）を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get creatorLinksEditButton;

  /// リンク集の編集の画面：タイトル（画面定義書（設定・発信者）2.3.19）
  ///
  /// In ja, this message translates to:
  /// **'リンク集を編集'**
  String get creatorLinksEditTitle;

  /// SNSリンク集の画面：見本の読み上げの名前（押すと全体の画面）
  ///
  /// In ja, this message translates to:
  /// **'ページの全体を表示'**
  String get creatorLinksPreviewOpen;

  /// リンク集のページの全体の画面：下の追星への入口の説明（公開のページと同じ文）
  ///
  /// In ja, this message translates to:
  /// **'追星アプリなら、{name}の配信が始まったら通知で知らせます。'**
  String creatorLinksPageAppLead(String name);

  /// リンク集のページの全体の画面：下の追星への入口のボタン（押せない。公開のページと同じ文）
  ///
  /// In ja, this message translates to:
  /// **'App Store で入れる'**
  String get creatorLinksPageInstall;

  /// リンク集のページの全体の画面：App Store のボタンの下の注記（公開のページと同じ文）
  ///
  /// In ja, this message translates to:
  /// **'入れて開くと、このページの発信者が出ます。'**
  String get creatorLinksPageInstallNote;

  /// リンク集のページの全体の画面：アプリで開くの文字（押せない。公開のページと同じ文）
  ///
  /// In ja, this message translates to:
  /// **'アプリをお持ちの方はこちら'**
  String get creatorLinksPageOpenApp;

  /// リンク集の着地の画面：リンクごとの押された数の見出し
  ///
  /// In ja, this message translates to:
  /// **'押された数'**
  String get creatorLinksClicksLabel;

  /// リンク集の着地の画面：リンクが1件もないときの、押された数の所の一言
  ///
  /// In ja, this message translates to:
  /// **'まだリンクがありません'**
  String get creatorLinksClicksEmpty;

  /// リンク集：下の注記
  ///
  /// In ja, this message translates to:
  /// **'押された数は、アプリと共有のページで押された回数の合計です。URL を変えると0に戻ります。誰が押したかは出しません。'**
  String get creatorLinksNote;

  /// リンク集：上限に達したとき
  ///
  /// In ja, this message translates to:
  /// **'リンクは{max}件までです'**
  String creatorLinksLimit(int max);

  /// リンクのシート：題名の欄
  ///
  /// In ja, this message translates to:
  /// **'題名'**
  String get creatorLinksTitleLabel;

  /// リンクのシート：題名の欄の例
  ///
  /// In ja, this message translates to:
  /// **'例：ファンクラブ'**
  String get creatorLinksTitleHint;

  /// リンクのシート：URL の欄
  ///
  /// In ja, this message translates to:
  /// **'URL'**
  String get creatorLinksUrlLabel;

  /// リンクのシート：URL の注記
  ///
  /// In ja, this message translates to:
  /// **'https で始まる URL だけ使えます。短縮 URL（bit.ly など）は使えません。'**
  String get creatorLinksUrlNote;

  /// リンクのシート：題名が空
  ///
  /// In ja, this message translates to:
  /// **'題名を入れてください'**
  String get creatorLinksTitleRequired;

  /// リンクのシート：題名が長すぎる
  ///
  /// In ja, this message translates to:
  /// **'{max}文字までです'**
  String creatorLinksTitleTooLong(int max);

  /// リンクのシート：URL の形が違う
  ///
  /// In ja, this message translates to:
  /// **'https で始まる URL を入れてください'**
  String get creatorLinksUrlInvalid;

  /// リンクのシート：短縮 URL
  ///
  /// In ja, this message translates to:
  /// **'短縮 URL は使えません。行き先の URL をそのまま入れてください'**
  String get creatorLinksShortUrl;

  /// リンク集：削除の確認の見出し
  ///
  /// In ja, this message translates to:
  /// **'「{title}」を消しますか？'**
  String creatorLinksDeleteTitle(String title);

  /// リンク集：削除の確認の本文
  ///
  /// In ja, this message translates to:
  /// **'押された数も消えます。'**
  String get creatorLinksDeleteMessage;

  /// リンク集：削除のボタン
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get creatorLinksDelete;

  /// 発信者ページ：リンクを開く前の確かめの、通報のボタン
  ///
  /// In ja, this message translates to:
  /// **'このリンクを通報する'**
  String get creatorLinkReport;

  /// リンク集の編集：ヘッダーの追加のボタン
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get creatorLinksAddShort;

  /// 発信者メニュー・連携：「SNS」の行の小さな説明（2026-11-19 本人）
  ///
  /// In ja, this message translates to:
  /// **'連携・表示する内容'**
  String get creatorAdminMenuSnsNote;

  /// 発信者メニューの「SNS」と、その画面のタイトル（SNS の連携と、出す内容の切り替えをまとめた画面。2026-11-19 本人）
  ///
  /// In ja, this message translates to:
  /// **'SNS'**
  String get creatorAdminSnsTitle;

  /// 発信者メニューのプロフィールカードの中の、届いた数の要約。押すと届いた数の画面
  ///
  /// In ja, this message translates to:
  /// **'直近30日で {count}人に通知を届けました'**
  String creatorAdminMenuReachSummary(String count);

  /// 発信者メニュー・シェア：リンク集の画面を開く行（2026-11-19 本人）
  ///
  /// In ja, this message translates to:
  /// **'SNSリンク集'**
  String get creatorAdminMenuLinks;

  /// 発信者メニュー：見出し（リンクを共有・追星に誘う・週間の告知画像）
  ///
  /// In ja, this message translates to:
  /// **'シェア'**
  String get creatorAdminMenuSectionShare;

  /// 発信者メニューの行・「追星に誘う」の画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'追星に誘う'**
  String get shareInviteTitle;

  /// 「追星に誘う」：共有シートに渡す文
  ///
  /// In ja, this message translates to:
  /// **'追星で私の配信・予定を追いかけてね\n{link}'**
  String shareInviteMessage(String link);

  /// 「追星に誘う」：下の注記
  ///
  /// In ja, this message translates to:
  /// **'このリンクから追星を入れて開いた人は、あなたをフォローした状態で始まります。'**
  String get shareInviteNote;

  /// 誘う用のリンクから入れて初めて開いたとき：自動でフォローしたことの知らせ
  ///
  /// In ja, this message translates to:
  /// **'{name}をフォローしました'**
  String onboardingInviteFollowed(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
