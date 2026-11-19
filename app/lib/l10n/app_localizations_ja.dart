// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '追星';

  @override
  String get startupErrorTitle => '起動できませんでした';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonSave => '保存';

  @override
  String get commonBack => '戻る';

  @override
  String get commonSearch => '検索';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonTryAgain => 'もう一度試す';

  @override
  String get commonNotFound => '見つかりませんでした';

  @override
  String get commonPageOpenFailed => 'ページを開けませんでした';

  @override
  String get commonRefreshFailed => '更新できませんでした';

  @override
  String get commonLoadFailedTitle => '読み込めませんでした';

  @override
  String get commonLoadFailedMessage => '通信の状態を確認して、もう一度お試しください。';

  @override
  String get commonSaveFailed => '保存できませんでした';

  @override
  String get commonSettingChangeFailed => '設定を変えられませんでした';

  @override
  String get commonNotificationSettingChangeFailed => '通知の設定を変えられませんでした';

  @override
  String get commonFollow => 'フォロー';

  @override
  String get commonFollowing => 'フォロー中';

  @override
  String get commonFollowChangeFailed => 'フォローを変えられませんでした';

  @override
  String get commonTabHome => 'ホーム';

  @override
  String get commonTabSchedule => 'スケジュール';

  @override
  String get commonTabOshiList => '推しリスト';

  @override
  String get commonTabSettings => '設定';

  @override
  String get commonFixedViewer => '固定ビューア';

  @override
  String get commonFixedViewerPlayLive => '配信に切り替える';

  @override
  String get fixedViewerEmptyMessage => '配信や動画を投稿している推しを見つけよう';

  @override
  String get fixedViewerModeLive => '配信モードに切り替えました';

  @override
  String get fixedViewerNoLive => '配信中の推しはいません';

  @override
  String get fixedViewerControlPlay => '再生';

  @override
  String get fixedViewerControlPause => '停止';

  @override
  String get fixedViewerControlNext => '次へ';

  @override
  String get fixedViewerControlPrevious => '前へ';

  @override
  String get fixedViewerPaused => '停止しました';

  @override
  String get fixedViewerResumed => '再生を再開しました';

  @override
  String get fixedViewerModeShuffle => '動画シャッフルモードに切り替えました';

  @override
  String get fixedViewerLiveEndedShuffle => '配信が終わりました。動画シャッフルモードに切り替えました';

  @override
  String get commonNotSet => '未設定';

  @override
  String get commonToday => '今日';

  @override
  String get commonTomorrow => '明日';

  @override
  String get commonAllDay => '終日';

  @override
  String get commonLive => '配信';

  @override
  String get commonPost => '投稿';

  @override
  String get commonNoPostsYet => 'まだ投稿がありません';

  @override
  String get commonComingSoon => '準備中';

  @override
  String get commonSuspended => '停止中';

  @override
  String get commonOpenCreatorPage => '発信者のページを開く';

  @override
  String get commonOpenPost => '投稿を開く';

  @override
  String get commonEvent => 'イベント';

  @override
  String get commonLink => 'リンク';

  @override
  String get commonTicket => 'チケット';

  @override
  String get scheduleDetailOpenTicket => 'チケットを見る';

  @override
  String get commonLivePin => '固定ビューアで流す';

  @override
  String get commonLivePrevious => '前の配信';

  @override
  String get commonLiveNext => '次の配信';

  @override
  String get commonLiveOpenCreator => '発信者ページを開く';

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get timeStarted => '開始済み';

  @override
  String get timeSoon => 'まもなく';

  @override
  String timeHoursLeft(int count) {
    return 'あと$count時間';
  }

  @override
  String timeDaysLater(int count) {
    return '$count日後';
  }

  @override
  String priceYen(String amount) {
    return '$amount円';
  }

  @override
  String snsServiceName(String service) {
    String _temp0 = intl.Intl.selectLogic(service, {
      'twitcasting': 'ツイキャス',
      'youtube': 'YouTube',
      'instagram': 'Instagram',
      'twitch': 'Twitch',
      'x': 'X',
      'other': '$service',
    });
    return '$_temp0';
  }

  @override
  String postKindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'video': '動画',
      'short': 'ショート',
      'image': '画像',
      'reel': 'リール',
      'carousel': 'カルーセル',
      'other': '投稿',
    });
    return '$_temp0';
  }

  @override
  String displayContentName(String content) {
    String _temp0 = intl.Intl.selectLogic(content, {
      'live': '配信',
      'video': '動画・ショート',
      'post': '投稿',
      'schedule': '予約',
      'other': '$content',
    });
    return '$_temp0';
  }

  @override
  String creatorPlanName(String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'standard': '基本プラン',
      'complimentary': '永年無料',
      'admin': '運営',
      'debug': '確認用',
      'other': '$plan',
    });
    return '$_temp0';
  }

  @override
  String displayModeName(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'system': '端末の設定に従う',
      'light': 'ライト',
      'dark': 'ダーク',
      'other': '$mode',
    });
    return '$_temp0';
  }

  @override
  String appLanguageName(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'system': '端末の設定に従う',
      'ja': '日本語',
      'en': 'English',
      'other': '$language',
    });
    return '$_temp0';
  }

  @override
  String get commonTermsOfService => '利用規約';

  @override
  String get commonPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get creatorCoverChangeFailed => 'カバーを変えられませんでした';

  @override
  String get creatorWatchLive => '固定ビューアで見る';

  @override
  String get creatorChangeCover => 'カバーを変える';

  @override
  String get creatorCoverPickPhoto => '写真を選ぶ';

  @override
  String get creatorCoverReset => '推しが設定したカバーに戻す';

  @override
  String get creatorFlipCover => 'カバーを裏返す';

  @override
  String get fixedViewerLiveEnded => '配信が終わりました';

  @override
  String get creatorTotalFollowers => '合計フォロワー';

  @override
  String get creatorBioExpand => 'もっと見る';

  @override
  String get creatorBioCollapse => '閉じる';

  @override
  String creatorNextScheduleHeader(String until) {
    return '次の予定 ・ $until';
  }

  @override
  String creatorNextScheduleMeta(String source, String date, String time) {
    return '$source ・ $date $time〜';
  }

  @override
  String get creatorNextScheduleEvent => 'イベント';

  @override
  String get creatorNewPostsDivider => 'ここまで新着';

  @override
  String get creatorBellNotifyOn => '通知をオンにする';

  @override
  String get creatorBellNotifyOff => '通知をオフにする';

  @override
  String get creatorBellUnfollow => 'フォローをやめる';

  @override
  String get creatorBellMenu => '通知とフォロー';

  @override
  String get creatorMonthCalendar => '月のカレンダー';

  @override
  String get creatorMenu => 'メニュー';

  @override
  String get creatorReport => '通報する';

  @override
  String get creatorHide => 'この発信者を表示しない';

  @override
  String creatorHideConfirmTitle(String name) {
    return '$nameを表示しないようにしますか？';
  }

  @override
  String get creatorHideConfirmMessage =>
      'フォローを外し、検索やタイムラインにも出さなくなります。設定から元に戻せます。';

  @override
  String get creatorHideConfirmAction => '表示しない';

  @override
  String get creatorHidden => 'この発信者を表示しないようにしました';

  @override
  String get creatorHideFailed => '表示しないにできませんでした';

  @override
  String get reportTitle => '通報する';

  @override
  String reportReasonName(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'impersonation': 'なりすまし',
      'inappropriate': '不適切な内容',
      'dangerousLink': '危険なリンク',
      'other': 'その他',
    });
    return '$_temp0';
  }

  @override
  String get reportDetailLabel => '詳しい内容（任意）';

  @override
  String get reportNote => '運営が内容を確かめ、必要に応じて表示を止めます。結果はお知らせしません。';

  @override
  String get reportSubmit => '送信';

  @override
  String get reportSubmitted => '通報しました。運営が確認します';

  @override
  String get reportAlreadySubmitted => 'この内容は、すでに通報を受け付けています';

  @override
  String get reportFailed => '通報できませんでした';

  @override
  String get commonLiveVideoFailed => '映像を再生できませんでした';

  @override
  String get commonLiveMute => 'ミュート';

  @override
  String get commonLiveUnmute => 'ミュートを解除';

  @override
  String get commonCreatorMenu => '発信者メニュー';

  @override
  String get creatorAdminSuspendedNotice =>
      'この発信者は、運営が表示を止めています。くわしくは、お問い合わせください。';

  @override
  String get creatorAdminMenuSectionLinks => '連携';

  @override
  String get creatorAdminProfileEditTitle => 'プロフィールの編集';

  @override
  String get creatorAdminAccountLinkTitle => 'SNS の連携';

  @override
  String creatorAdminMenuLinkedCount(int count) {
    return '$count件';
  }

  @override
  String get creatorAdminMenuSectionContent => 'コンテンツ';

  @override
  String get creatorAdminMenuEventManage => 'イベントの管理';

  @override
  String get creatorAdminPostManageTitle => '投稿の管理';

  @override
  String get creatorAdminPlanTitle => 'プラン';

  @override
  String get creatorAdminUpcomingNiconico => 'ニコニコ';

  @override
  String get creatorAdminUpcomingTiktokContents => '配信・ショート動画';

  @override
  String get creatorAdminUpcomingNiconicoContents => '配信・動画';

  @override
  String creatorAdminLinked(String service) {
    return '$serviceを連携しました';
  }

  @override
  String get creatorAdminLinkDuplicate => 'このアカウントは、ほかの発信者で連携されています';

  @override
  String get creatorAdminLinkNoChannel => 'YouTube のチャンネルが見つかりませんでした';

  @override
  String get creatorAdminLinkFailed => '連携できませんでした。もう一度お試しください';

  @override
  String creatorAdminUnlinkConfirmTitle(String service) {
    return '$serviceの連携を解除しますか？';
  }

  @override
  String get creatorAdminUnlinkConfirmMessage => '追星に表示されなくなります。';

  @override
  String get creatorAdminUnlinkConfirmAction => '解除する';

  @override
  String creatorAdminUnlinked(String service) {
    return '$serviceの連携を解除しました';
  }

  @override
  String get creatorAdminUnlinkFailed => '解除できませんでした。もう一度お試しください';

  @override
  String get creatorAdminAccountLinkIntro =>
      '連携して、そのアカウントが本人のものだと確認されると、追星に表示できます。';

  @override
  String get creatorAdminAccountLinkNote =>
      '確認が済んでいないアカウントは、追星には表示されません。連携したあとも、追星に出す内容をオフにできます。連携は、いつでも解除できます。';

  @override
  String get creatorAdminLinkAction => '連携する';

  @override
  String get creatorAdminNotLinked => '未連携';

  @override
  String get creatorAdminDisplayContentsHideNote =>
      'オフにすると、取得済みの投稿も、すぐにファンに見えなくなります。';

  @override
  String creatorAdminDisplayNeedsXOption(String price) {
    return 'X連携プラン（月$price）に加入すると使えます';
  }

  @override
  String get creatorAdminRegistered => '発信者として登録しました';

  @override
  String get creatorAdminRegisteredPartially =>
      '発信者として登録しました。プロフィールの一部を保存できなかったので、プロフィールの編集で直してください';

  @override
  String get creatorAdminRegisterIdTaken => 'このIDは、すでに使われています';

  @override
  String get creatorAdminRegisterDuplicate => '連携したアカウントが、ほかの発信者で使われています';

  @override
  String get creatorAdminRegisterClosed => '発信者の登録は、準備中です';

  @override
  String get creatorAdminRegisterFailed => '登録できませんでした。もう一度お試しください';

  @override
  String get creatorAdminRegisterTitle => '発信者として登録';

  @override
  String get creatorAdminRegisterHeadline => 'あなたの配信・投稿・イベントを\nファンに届けます';

  @override
  String get creatorAdminRegisterEyebrow => 'FOR CREATORS';

  @override
  String get creatorAdminRegisterLead =>
      '連携したいSNSアカウントにサインインしてください。\n投稿やフォロワー数、リンクなどがアプリに表示されます。';

  @override
  String get creatorAdminRegisterStepLink => 'SNSアカウントを連携';

  @override
  String creatorAdminRegisterStepLinkDone(String services) {
    return '$services を連携済み';
  }

  @override
  String get commonListSeparator => '・';

  @override
  String get creatorAdminRegisterStepProfile => 'プロフィールを入力';

  @override
  String creatorAdminRegisterStepProfileDone(String name, String id) {
    return '$name（@$id）として入力済み';
  }

  @override
  String get creatorAdminRegisterAgreePrefix => '';

  @override
  String get creatorAdminRegisterAgreeSeparator => '・';

  @override
  String get creatorAdminRegisterAgreeLastSeparator => '・';

  @override
  String get creatorAdminRegisterTerms => '発信者向けの利用規約';

  @override
  String get creatorAdminRegisterAgreeSuffix => 'に同意する';

  @override
  String get creatorAdminRegisterAction => '発信者として登録する';

  @override
  String creatorAdminImportFailed(String service) {
    return '$serviceから取り込めませんでした';
  }

  @override
  String creatorAdminImportEmpty(String service) {
    return '$serviceに、取り込める項目がありませんでした';
  }

  @override
  String creatorAdminImportLimited(String service) {
    return '$serviceからの取り込みは、しばらく時間をおいてお試しください';
  }

  @override
  String creatorAdminImported(String service) {
    return '$serviceから、下書きを入れました';
  }

  @override
  String creatorAdminDraftBadge(String service) {
    return '下書き・$serviceから';
  }

  @override
  String get creatorAdminNameInvalid => '名前は、1〜100文字で入力してください';

  @override
  String get creatorAdminIdInvalid => 'IDは、英小文字・数字・_・- の1〜40文字で入力してください';

  @override
  String get creatorAdminChangeCover => 'カバーを変える';

  @override
  String get creatorAdminChangeAvatar => 'アイコンを変える';

  @override
  String get creatorAdminImportTitle => '連携したSNSから入力';

  @override
  String get creatorAdminImportDescription =>
      '名前・アイコン・プロフィール文を、下書きとして入れます。保存するまでは、反映されません。';

  @override
  String get creatorAdminFieldName => '名前';

  @override
  String get creatorAdminFieldBio => 'プロフィール文';

  @override
  String get creatorAdminIdNote => 'IDは、あとから変えられません。';

  @override
  String get creatorAdminIdHint => '英小文字・数字・_・-';

  @override
  String get creatorAdminEventRequiredMissing => '必須の項目を入力してください';

  @override
  String get creatorAdminEventFieldTitle => 'タイトル';

  @override
  String get creatorAdminEventTitleHint => '例：新衣装のお披露目';

  @override
  String get creatorAdminEventFieldDate => '日付';

  @override
  String creatorAdminEventDate(String date, String weekday) {
    return '$date（$weekday）';
  }

  @override
  String get creatorAdminEventPickDate => '日付を選ぶ';

  @override
  String get creatorAdminEventFieldStart => '開始';

  @override
  String get creatorAdminEventFieldEnd => '終了（任意）';

  @override
  String get creatorAdminEventEndNote => '指定しない場合は、その日の終わりまで表示します';

  @override
  String get creatorAdminEventFieldVenue => '会場（任意）';

  @override
  String get creatorAdminEventVenueHint => '例：東京・渋谷 ○○ホール';

  @override
  String get creatorAdminEventPromotion => 'このリンクは広告です';

  @override
  String get creatorAdminEventPromotionHint => '「PR」と表示します（チケットの販売など）';

  @override
  String get creatorAdminEventTitleTooLong => 'タイトルは、1〜200文字で入力してください';

  @override
  String get creatorAdminEventLinkInvalid => 'https:// で始まる URL を入れてください';

  @override
  String get creatorAdminEventDelete => '削除';

  @override
  String get creatorAdminEventDeleteFailed => '削除できませんでした';

  @override
  String get creatorAdminEventListAdd => '登録';

  @override
  String get creatorAdminEventListEmpty => 'イベントはまだありません';

  @override
  String get creatorAdminEventListPast => '過去のイベント';

  @override
  String get commonRequired => '必須';

  @override
  String get creatorAdminPlanPurchasePending => '支払いの承認を待っています';

  @override
  String get creatorAdminPlanPurchaseFailed => '購入できませんでした。もう一度お試しください';

  @override
  String get creatorAdminPlanRestored => '購入を復元しました';

  @override
  String get creatorAdminPlanNothingToRestore => '復元できる購入がありません';

  @override
  String get creatorAdminPlanRestoreFailed => '復元できませんでした。もう一度お試しください';

  @override
  String get creatorAdminPlanCurrent => 'いまのプラン';

  @override
  String get creatorAdminPlanFree => '無料';

  @override
  String get creatorAdminPlanSubscribe => '加入する';

  @override
  String get creatorAdminPlanSubscribed => '加入中';

  @override
  String creatorAdminPlanPerMonth(String price) {
    return '月$price';
  }

  @override
  String creatorAdminPlanBasicFeatureFetch(String services) {
    return '$services の取得と表示';
  }

  @override
  String get creatorAdminPlanBasicFeatureReservations => '配信の予約の取得';

  @override
  String get creatorAdminPlanBasicFeatureCalendar => 'イベントの登録';

  @override
  String get creatorAdminPlanAddOns => 'オプション';

  @override
  String get creatorAdminPlanXOptionTitle => 'X連携プラン';

  @override
  String get creatorAdminPlanXFeatureFetch => 'X の投稿の取得と表示';

  @override
  String get creatorAdminPlanXFeatureNoReposts => 'リポスト・リプライは、取りません';

  @override
  String get creatorAdminPlanCancel => '解約する';

  @override
  String get creatorAdminPlanCancelConfirmTitle => 'ストアのサブスクの管理を開きます';

  @override
  String get creatorAdminPlanCancelConfirmMessage =>
      '解約は、ストアの画面で行います。期間の終わりまでは、X の連携を使えます。';

  @override
  String get creatorAdminPlanCancelConfirmAction => '開く';

  @override
  String get creatorAdminPlanRestore => '購入を復元';

  @override
  String get creatorAdminPlanSubscriptionTerms =>
      'お支払いは、ストアのアカウントに請求されます。X連携プランは、1か月ごとの自動更新のサブスクです。期間の終わりの24時間前までに解約しないと、自動で更新されます。解約は、ストアのサブスクの管理で行えます。';

  @override
  String get creatorAdminPlanLegalSeparator => '・';

  @override
  String creatorAdminPlanRenewsOn(String date) {
    return '次の更新日 $date';
  }

  @override
  String creatorAdminPlanEndsOn(String date) {
    return '$dateに終了';
  }

  @override
  String get creatorAdminPlanUnavailableTitle => 'この端末では、まだ X連携プランに加入できません';

  @override
  String get creatorAdminPlanUnavailableMessage => '準備ができるまで、お待ちください。';

  @override
  String get creatorAdminPlanIncludedNote => '料金はかかりません（X の連携を含む）';

  @override
  String get onboardingWelcomeTagline => '推しの配信・投稿・予定が、\nひとつに集まります。';

  @override
  String get onboardingStart => 'はじめる';

  @override
  String get onboardingForCreators => '発信者の方はこちら';

  @override
  String get onboardingAgreePrefix => '「はじめる」を押すと、';

  @override
  String get onboardingAgreeAnd => 'と';

  @override
  String get onboardingAgreeSuffix => 'に\n同意したものとします。';

  @override
  String get onboardingChooseTitle => '推しをフォローしましょう';

  @override
  String get onboardingChooseMessage => 'フォローした推しの、配信・投稿・予定が、ホームに集まります。';

  @override
  String get onboardingChooseSearchHint => '名前やIDで探す';

  @override
  String get onboardingNext => '次へ';

  @override
  String onboardingNextFollowing(int count) {
    return '次へ（$count人をフォロー中）';
  }

  @override
  String get onboardingLater => 'あとで';

  @override
  String get onboardingNotificationTitle => '配信が始まったら、\nお知らせします';

  @override
  String get onboardingNotificationMessage =>
      '推しが配信を始めたときに、通知でお知らせします。\nあとから、設定で変えられます。';

  @override
  String get onboardingNotificationEnable => '通知をオンにする';

  @override
  String get onboardingNotificationSkip => 'いまはしない';

  @override
  String get onboardingNotificationSampleTitle => '星野ミナトが配信を始めました';

  @override
  String get onboardingNotificationSampleBody => '【Apex】プラチナ帯ソロランク耐久！';

  @override
  String get commonLiveOpenSource => '配信元で開く';

  @override
  String get fixedViewerShufflePlay => '推しの動画をランダムに流す';

  @override
  String get homeShuffleEmpty => '流せる動画がありません';

  @override
  String get commonVideoPrevious => '前の動画';

  @override
  String get commonVideoNext => '次の動画';

  @override
  String get homeEmptyTitle => '推しを探しましょう';

  @override
  String get homeEmptyMessage => '推しをフォローすると、配信や予定、投稿が、ここに集まります。';

  @override
  String get homeTimelineEnd => '過去90日ぶんを、すべて表示しました';

  @override
  String get homeUpcomingTitle => '次の予定';

  @override
  String get homeUpcomingEmpty => '今日はこれからの予定はありません';

  @override
  String get commonEventsTitle => 'イベント';

  @override
  String get commonEventsEmpty => 'これからのイベントはありません';

  @override
  String commonMoreCount(int count) {
    return 'ほか $count 件';
  }

  @override
  String get commonFindCreatorsTitle => '推しを探す';

  @override
  String oshiListCount(int count) {
    return '$count人フォロー中';
  }

  @override
  String get oshiListSortLiveFirst => '並び替え：配信中が先';

  @override
  String oshiListLiveNow(String title) {
    return '配信中：$title';
  }

  @override
  String oshiListNextSchedule(String when, String title) {
    return '$when $title';
  }

  @override
  String get oshiListNoSchedule => '予定はありません';

  @override
  String get oshiListEmptyTitle => '推しがいません';

  @override
  String get oshiListEmptyMessage => '推しをフォローすると、ここに並びます。';

  @override
  String oshiListNoMatch(String query) {
    return '「$query」に合う推しは、フォロー中にいません。';
  }

  @override
  String get oshiListUnfollowFailed => 'フォローを解除できませんでした';

  @override
  String commonFindNoMatch(String query) {
    return '「$query」に合う推しは、まだ追星にいません。名前やIDを、もう一度確かめてください。';
  }

  @override
  String get oshiFindRecommended => 'おすすめ';

  @override
  String get commonViewOnX => 'Xで見る';

  @override
  String get postOpen => '開く';

  @override
  String get postVideoPlay => '再生';

  @override
  String get commonVideoUnplayable => 'この動画はアプリ上では再生できません';

  @override
  String get creatorAdminPostManageNote =>
      'ここで隠しても、元の SNS の投稿は消えません。追星でファンに出さなくなるだけです。';

  @override
  String get creatorAdminPostVisibleSwitch => 'ファンに出す';

  @override
  String get creatorAdminPostHidden => '隠しました';

  @override
  String get creatorAdminPostShown => 'また出しました';

  @override
  String get creatorAdminPostHideFailed => '隠せませんでした';

  @override
  String get creatorAdminPostShowFailed => 'また出せませんでした';

  @override
  String get homeLiveStartedFallback => '推しが配信を始めました';

  @override
  String get homeLiveStartedOpen => '開く';

  @override
  String get homeScheduleNoticeFallback => '推しの予定のお知らせ';

  @override
  String get homeWantArrivalFallback => '追いたい人が追星に来ました';

  @override
  String scheduleOpenEndedTime(String time) {
    return '$time〜';
  }

  @override
  String get scheduleDayEmpty => 'この日の予定はありません';

  @override
  String get scheduleDayEmptyHint => 'ほかの日は、上の日付から選べます。';

  @override
  String get scheduleLiveNow => '配信中';

  @override
  String get scheduleWatchLive => '配信を見る';

  @override
  String schedulePostsGroupTitle(String name) {
    return '$nameの投稿';
  }

  @override
  String schedulePostsGroupSubtitle(int hour, int count) {
    return '$hour時ごろ ・ $count件';
  }

  @override
  String schedulePostsGroupSemantics(int count, String services) {
    return '$count件の投稿（$services）';
  }

  @override
  String get scheduleFilterTitle => '絞り込み';

  @override
  String get scheduleFilterReset => 'リセット';

  @override
  String get scheduleFilterCreatorsTitle => '表示する推し';

  @override
  String get scheduleFilterSelectAll => 'すべて選ぶ';

  @override
  String get scheduleFilterDeselectAll => 'すべて外す';

  @override
  String get scheduleFilterAllCreators => '全員';

  @override
  String scheduleFilterCreatorCount(int count) {
    return '$count人';
  }

  @override
  String get scheduleFilterPlatforms => 'プラットフォーム';

  @override
  String get scheduleFilterContent => '表示する内容';

  @override
  String get scheduleFilterHideEmpty => '配信・投稿・予定のない推しを隠す';

  @override
  String get scheduleHideEmptyOn => '配信・投稿・予定のない推しを隠しました';

  @override
  String get scheduleHideEmptyOff => 'すべての推しを表示しました';

  @override
  String scheduleFilterApply(int creators, int services) {
    return '$creators人・$servicesつのSNSで表示';
  }

  @override
  String get commonNoService => 'イベント';

  @override
  String get scheduleEmptyTitle => '推しの予定が、ここに並びます';

  @override
  String get scheduleEmptyMessage => '推しをフォローすると、配信やイベントを、時間の表で見られます。';

  @override
  String get scheduleOpenCalendar => 'カレンダーへ';

  @override
  String scheduleAllDayMore(String title, int count) {
    return '$title +$count';
  }

  @override
  String get scheduleCalendarAllTitle => 'みんなのカレンダー';

  @override
  String scheduleCalendarCreatorTitle(String name) {
    return '$nameのカレンダー';
  }

  @override
  String get eventListAllTitle => 'みんなのイベント';

  @override
  String eventListCreatorTitle(String name) {
    return '$nameのイベント';
  }

  @override
  String commonWhenVenue(String when, String venue) {
    return '$when・$venue';
  }

  @override
  String get eventListEmptyMessage => 'イベントが登録されると、ここに出ます';

  @override
  String get schedulePreviousMonth => '前の月';

  @override
  String get scheduleNextMonth => '次の月';

  @override
  String get scheduleCalendarDayPosts => 'この日に行われた投稿';

  @override
  String schedulePostCount(int count) {
    return '$count件';
  }

  @override
  String get scheduleDetailLiveKind => '配信の予定';

  @override
  String get scheduleDetailEnded => '終了しました';

  @override
  String get scheduleDetailUpcoming => 'これから';

  @override
  String commonScheduleDateAllDay(String date) {
    return '$date 終日';
  }

  @override
  String commonScheduleDateTime(String date, String start, String end) {
    return '$date$start〜$end';
  }

  @override
  String commonScheduleDateTimeSpan(
    String startDate,
    String start,
    String endDate,
    String end,
  ) {
    return '$startDate$start〜$endDate$end';
  }

  @override
  String get scheduleDetailEndOpen => '終了時刻は未定です';

  @override
  String get scheduleDetailLinkHint => '押すと、外部のページが開きます';

  @override
  String get scheduleDetailReport => 'この予定を通報する';

  @override
  String get scheduleDetailOpenLink => 'リンクを開く';

  @override
  String get scheduleDetailEdit => '編集';

  @override
  String get commonLinkConfirmTitle => '外部のサイトを開きます';

  @override
  String get commonLinkConfirmOpen => '開く';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSignedIn => 'ログインしました';

  @override
  String get settingsLogoutConfirmTitle => 'ログアウトしますか？';

  @override
  String get settingsLogoutConfirmMessage => '結び付けたログイン方法で、またログインできます。';

  @override
  String get settingsLogout => 'ログアウト';

  @override
  String get settingsLoggedOut => 'ログアウトしました';

  @override
  String get settingsLogoutFailed => 'ログアウトできませんでした';

  @override
  String get settingsOn => 'オン';

  @override
  String get settingsOff => 'オフ';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsDisplayMode => '画面モード';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsRegisterAsCreator => '発信者として登録する';

  @override
  String get settingsSectionAccount => 'アカウント';

  @override
  String get settingsLoginMethods => 'ログイン方法';

  @override
  String get settingsAccountRequired => '先にアカウントを作成してください';

  @override
  String get settingsHiddenCreators => '表示しない発信者';

  @override
  String settingsHiddenCreatorCount(int count) {
    return '$count人';
  }

  @override
  String get settingsHiddenCreatorsDescription =>
      '表示しないにした発信者は、検索やタイムラインに出ません。';

  @override
  String get settingsHiddenCreatorsEmpty => '表示しない発信者はいません';

  @override
  String get settingsHiddenCreatorShow => '表示する';

  @override
  String get settingsHiddenCreatorRestored => '表示するように戻しました';

  @override
  String get settingsHiddenCreatorRestoreFailed => '戻せませんでした';

  @override
  String get settingsAccountEntry => 'アカウント作成／ログイン';

  @override
  String get settingsSectionSupport => 'サポート';

  @override
  String get commonContact => 'お問い合わせ';

  @override
  String get settingsWithdraw => '退会';

  @override
  String get creatorAdminMenuProfileCardHint => 'プロフィールを編集する';

  @override
  String get commonVerified => '確認済み';

  @override
  String get settingsContactAddressPreparing => '宛先のメールアドレスは、準備中です。';

  @override
  String get settingsContactByEmail => '次の宛先に、メールでお問い合わせください。';

  @override
  String get settingsUserId => 'ユーザーID';

  @override
  String get settingsCopyUserId => 'ユーザーIDをコピー';

  @override
  String get commonContactSubject => '追星へのお問い合わせ';

  @override
  String commonContactBody(String userId, String version, String os) {
    return '\n\n----\nユーザーID: $userId\nアプリのバージョン: $version\nOS: $os\n';
  }

  @override
  String get commonContactNotSignedIn => '（サインインしていません）';

  @override
  String settingsLoginLinked(String provider) {
    return '$providerのログインを結び付けました';
  }

  @override
  String get settingsAccountAlreadyUsed => 'このアカウントは、ほかのユーザーで使われています';

  @override
  String get settingsLinkFailed => '結び付けられませんでした。もう一度お試しください';

  @override
  String settingsUnlinkConfirmTitle(String provider) {
    return '$providerのログインを外しますか？';
  }

  @override
  String settingsUnlinkConfirmMessage(String provider) {
    return '$providerでは、ログインできなくなります。';
  }

  @override
  String get settingsUnlink => '外す';

  @override
  String settingsUnlinked(String provider) {
    return '$providerのログインを外しました';
  }

  @override
  String get settingsUnlinkFailed => '外せませんでした。もう一度お試しください';

  @override
  String get settingsLoginMethodsDescription =>
      '結び付けたどれかで、別の端末からもログインできます。発信者は、2つ以上がおすすめです。';

  @override
  String get settingsLoginMethodsNote =>
      'SNS のアカウント連携とは別です。ログイン方法を外しても、連携は残ります。';

  @override
  String get settingsLink => '結び付ける';

  @override
  String get settingsLoginMethodSet => '設定済み';

  @override
  String get settingsLoginFailed => 'ログインできませんでした。もう一度お試しください';

  @override
  String get settingsAdminLogin => 'アプリ運営用ログイン';

  @override
  String get settingsAdminLoginLead => '運営が用意したアカウントで入ります。新しい登録はできません。';

  @override
  String get settingsAdminLoginEmail => 'メールアドレス';

  @override
  String get settingsAdminLoginPassword => 'パスワード';

  @override
  String get settingsAdminLoginSubmit => 'ログイン';

  @override
  String get settingsAdminLoginInvalid => 'メールアドレスかパスワードが違います';

  @override
  String get settingsAdminLoginTooMany => 'しばらくしてからやり直してください';

  @override
  String get settingsLoginSheetCreatorLead => '発信者として登録するには、アカウントが要ります。';

  @override
  String get settingsAccountCreated => 'アカウントを作成しました';

  @override
  String get settingsContinueWithApple => 'Appleで続ける';

  @override
  String get settingsContinueWithGoogle => 'Google で続行';

  @override
  String get settingsLoginWithApple => 'Appleでサインイン';

  @override
  String get settingsLoginWithGoogle => 'Google でログイン';

  @override
  String settingsContinueWith(String provider) {
    return '$providerで続ける';
  }

  @override
  String settingsLoginWith(String provider) {
    return '$providerでログイン';
  }

  @override
  String get settingsNotificationSettingsTitle => '通知設定';

  @override
  String get settingsDeviceNotificationsOff =>
      '端末の通知がオフになっています。配信の開始や予定をお知らせするには、端末の設定で通知を許可してください。';

  @override
  String get settingsOpenDeviceSettings => '端末の設定を開く';

  @override
  String get settingsNotificationPermissionPrompt =>
      '通知を許可すると、推しの配信の開始と予定をお知らせします。';

  @override
  String get settingsAllowNotifications => '通知を許可する';

  @override
  String get settingsLiveStartNotification => '配信と予定の通知';

  @override
  String get settingsLiveStartNotificationDescription =>
      '推しが配信を始めたときと、予定の前に、お知らせします';

  @override
  String get settingsPerCreatorNotificationNote =>
      '推しごとの通知は、それぞれの推しのページで変えられます。';

  @override
  String get settingsReauthLoadFailed => '読み込めませんでした。もう一度お試しください';

  @override
  String get settingsReauthAppleMessage =>
      'Apple でのサインインのひも付けも取り消すため、Apple で、もう一度ログインしてください。';

  @override
  String get settingsWrongAccount => '結び付けたアカウントで、ログインしてください';

  @override
  String get settingsReauthTitle => '本人の確認';

  @override
  String get settingsReauthUnavailable =>
      'この端末では、結び付けたログイン方法を使えません。iPhone で操作してください。';

  @override
  String get settingsReauthMessage => '大事な操作の前に、結び付けたログイン方法で、もう一度ログインしてください。';

  @override
  String get settingsWithdrawWarning =>
      '退会すると、フォロー中の推し、通知や表示の設定が、すべて削除されます。この操作は取り消せません。';

  @override
  String get settingsWithdrawAppleElsewhere =>
      'この端末では、Apple でのサインインのひも付けを取り消せません。iPhone で退会するか、退会のあとに、iPhone の設定の「Apple でサインイン」から外してください。';

  @override
  String get settingsWithdrawAppleOnly =>
      'Apple だけでログインしているので、この端末では本人の確認ができません。iPhone で退会してください。';

  @override
  String get settingsWithdrawButton => '退会する';

  @override
  String get settingsWithdrawFailed => '退会できませんでした';

  @override
  String get creatorAdminLinkReclaimable =>
      'オーナーが退会した発信者のアカウントです。登録の画面から、取り戻せます';

  @override
  String get creatorAdminUnlinkConfirmHeldMessage =>
      'すぐに、追星に表示されなくなります。取得した投稿・配信・予定・実績は、90日残してから消します。90日のうちに、同じアカウントを連携し直すと、元に戻ります。';

  @override
  String get settingsWithdrawCreatorNote =>
      'あなたの発信者は、すぐに追星に表示されなくなり、90日後に消えます。90日のうちなら、発信者として登録の画面で、同じSNSのアカウントを連携すると、取り戻せます。';

  @override
  String get settingsWithdrawSubscriptionNote =>
      '退会しても、ストアのサブスクは解約されません。先に、サブスクの管理から解約してください。';

  @override
  String get settingsWithdrawManageSubscription => 'サブスクの管理を開く';

  @override
  String get creatorAdminProfileTypesLabel => 'タイプ';

  @override
  String creatorAdminProfileTypesNote(int count) {
    return '$countつまで選べます。おすすめに使います。';
  }

  @override
  String get creatorAdminProfileTypesLoadFailed => 'タイプを読み込めませんでした';

  @override
  String creatorAdminReclaimed(String name) {
    return '$nameを取り戻しました';
  }

  @override
  String get creatorAdminReclaimNotReclaimable => 'この発信者は、もう取り戻せません';

  @override
  String get creatorAdminReclaimDuplicate => '連携したアカウントが、ほかの発信者で使われています';

  @override
  String get creatorAdminReclaimFailed => '取り戻せませんでした。もう一度お試しください';

  @override
  String get creatorAdminReclaimTitle => '発信者を取り戻せます';

  @override
  String creatorAdminReclaimMessage(
    String name,
    String id,
    String date,
    String plan,
  ) {
    return '連携したアカウントの発信者「$name」（@$id）は、オーナーの退会で、いまは追星に表示されていません。$dateまでに取り戻すと、プロフィール・連携・予定が、そのまま戻ります。$plan';
  }

  @override
  String get creatorAdminReclaimNeedsPlan =>
      'X連携プランに加入していたなら、取り戻したあとに、プランの画面の「購入を復元」で引き継げます。';

  @override
  String get creatorAdminReclaimAction => '取り戻す';

  @override
  String commonPostKindTime(String kind, String time) {
    return '$kind ・ $time';
  }

  @override
  String commonServiceTime(String service, String time) {
    return '$service ・ $time';
  }

  @override
  String get creatorAdminProfileIdLabel => 'ID';

  @override
  String get creatorAdminDmTitle => 'Instagram を DM で確認';

  @override
  String creatorAdminDmIntro(String account) {
    return 'Instagram のユーザー名を入れて、コードを出してください。そのアカウントから、運営の Instagram（@$account）にコードを DM で送ると、運営が確かめて「確認済み」にします。';
  }

  @override
  String get creatorAdminDmUsernameLabel => 'Instagram のユーザー名';

  @override
  String get creatorAdminDmRequest => 'コードを出す';

  @override
  String creatorAdminDmTarget(String account) {
    return '確かめるアカウント：@$account';
  }

  @override
  String get creatorAdminDmCopy => 'コピー';

  @override
  String get creatorAdminDmCopied => 'コードをコピーしました';

  @override
  String creatorAdminDmSendTo(String account) {
    return '送り先：@$account';
  }

  @override
  String get creatorAdminDmOpen => 'Instagram で DM を送る';

  @override
  String creatorAdminDmNote(String date) {
    return '運営が確かめるまで、数日かかることがあります。コードの期限は $date までです。';
  }

  @override
  String get creatorAdminDmCancel => '取り消す';

  @override
  String get creatorAdminDmInvalid => 'Instagram のユーザー名を確かめてください';

  @override
  String get creatorAdminDmFailed => 'コードを出せませんでした。もう一度お試しください';

  @override
  String get creatorAdminDmCancelFailed => '取り消せませんでした。もう一度お試しください';

  @override
  String get creatorAdminDmPending => '確認待ち';

  @override
  String get eventRegisterTitle => 'イベントの登録';

  @override
  String get eventRegisterUrlLabel => 'チケットの URL';

  @override
  String get eventRegisterUrlHint =>
      'チケットのページを開いて、タイトル・日時・会場を読み取ります。読み取れなかった項目は、手で入れてください。';

  @override
  String get eventRegisterRead => '読み取る';

  @override
  String get eventRegisterReadDone => '読み取りました。内容を確かめてください';

  @override
  String get eventRegisterReadFailed => '読み取れませんでした。手で入れてください';

  @override
  String get eventRegisterPerformance => '公演';

  @override
  String get performancePickerTitle => '公演を選ぶ';

  @override
  String get performancePickerNote => '1つのイベントには、1つの公演を登録します。';

  @override
  String get eventRegisterSaved => 'イベントを登録しました';

  @override
  String get eventPageReaderRead => 'このページから読み取る';

  @override
  String get eventPageReaderNote => '表示しているページから、タイトル・日時・会場を読み取ります。';

  @override
  String get eventPageReaderRegister => 'このイベントを登録';

  @override
  String eventPageReaderCandidates(int count) {
    return 'このページのイベントから選ぶ（$count件）';
  }

  @override
  String get eventCandidatesTitle => 'イベントの候補';

  @override
  String get eventCandidatesNote => '押すとページを開きます。内容を確かめて、「このイベントを登録」を押してください。';

  @override
  String get eventCandidatesRegistered => '登録済み';

  @override
  String get eventPageReaderReadTime => 'このページから時刻を読む';

  @override
  String get eventCandidatesSavedTimeTbd => 'イベントを登録しました。時刻未定の公演は、編集で時刻を足せます';

  @override
  String get eventSearchTitle => 'チケットサイトで探す';

  @override
  String get eventSearchName => 'アーティスト名';

  @override
  String get eventSearchNote =>
      'チケットぴあ・イープラス・ローチケ・楽天チケットで、この名前のアーティストを探します。同じ名前の別の人も出るので、確かめてから選んでください。';

  @override
  String get eventRegisterTimeTbd => '時刻未定';

  @override
  String get eventRegisterTimeTbdHint => '開演の時刻が決まっていない・分からない公演';

  @override
  String get eventRegisterReadTime => 'ページから時刻を読む';

  @override
  String get eventRegisterTimeRead => '時刻を読み取りました';

  @override
  String get eventRegisterTimeReadFailed => '時刻を読み取れませんでした';

  @override
  String get commonTimeTbd => '時刻未定';

  @override
  String commonScheduleDateTimeTbd(String date) {
    return '$date 時刻未定';
  }

  @override
  String get eventSearchButton => '探す';

  @override
  String get eventSearchNoArtist => 'アーティストが見つかりませんでした';

  @override
  String get eventCandidatesEmpty => 'イベントが見つかりませんでした';

  @override
  String get performanceCandidatesNote =>
      '押すと公演のページを開きます。内容を確かめて、「このイベントを登録」を押してください。';

  @override
  String get performanceCandidatesEmpty => '公演が見つかりませんでした';

  @override
  String performanceCandidatesLoading(int done, int total) {
    return '公演を集めています（$done/$total）';
  }

  @override
  String performanceCandidatesFailedEvents(int count) {
    return '読み込めなかったページが $count 件あります';
  }

  @override
  String get performanceCandidatesTitle => '公演の候補';

  @override
  String eventSearchShowPerformances(int count) {
    return '公演を見る（$count件）';
  }

  @override
  String get eventSearchMaintenance => 'メンテナンス中のため、いまは探せません';

  @override
  String eventSearchRakutenEvents(String name, int count) {
    return '「$name」を含むイベント（$count件）';
  }

  @override
  String get eventRegisterUpdated => 'イベントを保存しました';

  @override
  String get eventRegisterDuplicateLink => 'このチケットリンクは、ほかのイベントで登録済みです';

  @override
  String get eventRegisterDeleteConfirmTitle => 'このイベントを消しますか？';

  @override
  String get eventRegisterDeleteConfirmMessage => '公演とチケットリンクも消えます。';

  @override
  String get eventEditTitle => 'イベントの編集';

  @override
  String get eventRegisterLinksLabel => 'チケットリンク';

  @override
  String get eventRegisterAddLink => '＋ チケットリンクを足す';

  @override
  String get eventRegisterRemoveLink => 'このチケットリンクを消す';

  @override
  String get eventRegisterDelete => 'このイベントを消す';

  @override
  String eventDetailOpenSite(String site) {
    return '$siteで購入';
  }

  @override
  String get shareLinkAction => 'リンクを共有';

  @override
  String shareLinkMessage(String name, String link) {
    return '$nameの配信と予定を、追星で追えます\n$link';
  }

  @override
  String get shareLinkUnavailable =>
      'ファンに見せていない状態のため、リンクを共有できません（確認済みのアカウントがない、または停止中です）';

  @override
  String get shareLinkFailed => 'リンクを共有できませんでした';

  @override
  String get shareLinkNotFound => 'リンクの発信者が見つかりませんでした';

  @override
  String get shareLinkTitle => 'リンクを共有';

  @override
  String get shareLinkShareButton => 'リンクを共有する';

  @override
  String get shareLinkSaveQr => 'QR を画像で保存・共有';

  @override
  String get shareLinkNote =>
      'リンクや QR から開いた人は、アプリが無ければ App Store へ進み、入れて開くとこの発信者をフォローした状態で始まります。アプリがあれば、このページへ進みます。';

  @override
  String get shareLinkCopied => 'リンクをコピーしました';

  @override
  String get shareLinkCopy => 'リンクをコピー';

  @override
  String get shareLinkQrLabel => '共有のリンクの QR';

  @override
  String get shareLinkUnavailableTitle => 'まだ共有できません';

  @override
  String get wantTitle => '追いたい';

  @override
  String get wantIntro =>
      '追星にまだいない人を、SNS の URL か ID で申告できます。その人が追星に来たら、お知らせして自動でフォローします。';

  @override
  String get wantServiceLabel => 'SNS（ID だけのときに選ぶ）';

  @override
  String get wantInputLabel => 'URL か ID';

  @override
  String get wantInputHint => 'https://x.com/… や @ID';

  @override
  String get wantParsed => '申告する ID';

  @override
  String get wantSubmit => '追いたい';

  @override
  String get wantPrivacyNote =>
      '追星が持つのは、SNS と ID と押した人数だけです。誰が押したかは、ほかの人に見せません。';

  @override
  String get wantListTitle => 'あなたの追いたい';

  @override
  String get wantListEmpty => 'まだ追いたいはありません';

  @override
  String wantCount(int count) {
    return '$count人が追いたい';
  }

  @override
  String get wantUnverified => '本人確認なし';

  @override
  String get wantCancel => '取り消す';

  @override
  String get wantAdded => '追いたいにしました';

  @override
  String get wantAlreadyHere => 'この人は、もう追星にいます';

  @override
  String get wantLimit => '今日はこれ以上申告できません';

  @override
  String get wantInvalid => 'この形の URL は読めません';

  @override
  String get wantChooseService => 'ID だけのときは、SNS を選んでください';

  @override
  String get wantFailed => '申告できませんでした';

  @override
  String get wantCancelFailed => '取り消せませんでした';

  @override
  String get oshiFindWantButton => '追いたいで申告する';

  @override
  String get announceImageTitle => '週間の告知画像';

  @override
  String get announceImageThisWeek => '今週';

  @override
  String get announceImageNextWeek => '来週';

  @override
  String get announceImageShare => '画像とリンクを共有';

  @override
  String get announceImageNote => '共有シートの「画像を保存」で、写真に保存できます。';

  @override
  String get announceImageShareFailed => '画像を共有できませんでした';

  @override
  String get announceImageChangePhoto => '画像を変える';

  @override
  String get announceImageResetPhoto => 'アイコンに戻す';

  @override
  String get announceImagePhotoNote => '画像は真ん中で切り抜きます。どのテンプレでも同じ画像を使います。';

  @override
  String get announceImageRenderFailed => '画像を作れませんでした';

  @override
  String get announceImageRendering => '画像を作っています';

  @override
  String get announceImagePhotoFailed => '画像を変えられませんでした';

  @override
  String announceShareHeading(String name, String range) {
    return '$nameの週間の予定（$range）';
  }

  @override
  String get announceShareInvite => '▼追星で通知を受け取る';

  @override
  String get announceShareTextLabel => '一緒に共有する文';

  @override
  String get announceShareCopy => '文をコピー';

  @override
  String get announceShareCopied => '文をコピーしました';

  @override
  String get announceShareInstagramNote =>
      'Instagram では文が投稿に入りません。「文をコピー」で写して、キャプションに貼り付けてください。';

  @override
  String get announceLinkCountsLabel => 'リンクが押された数';

  @override
  String get announceLinkInvite => '追星に誘うリンク';

  @override
  String announceLinkCount(int count) {
    return '$count回';
  }

  @override
  String get reachTitle => '届いた数';

  @override
  String reachLast30Days(String from, String to) {
    return '直近30日（$from〜$to）';
  }

  @override
  String get reachDelivered => '通知を届けた人';

  @override
  String get reachOpened => '通知から来た人';

  @override
  String get reachViewed => '予定を見た人';

  @override
  String get reachFollowers => 'フォロワー';

  @override
  String reachFollowChange(String change, int followed, int unfollowed) {
    return '30日で $change（フォロー $followed・解除 $unfollowed）';
  }

  @override
  String get reachBySubject => '配信・予定ごと';

  @override
  String get reachBySubjectEmpty => 'まだありません。配信開始や予定の通知を送ると、ここに数が出ます。';

  @override
  String get reachKindLive => '配信';

  @override
  String get reachKindSchedule => '予定';

  @override
  String get reachDeletedSchedule => '消された予定';

  @override
  String reachCountDelivered(int count) {
    return '届けた $count';
  }

  @override
  String reachCountOpened(int count) {
    return '来た $count';
  }

  @override
  String reachCountViewed(int count) {
    return '見た $count';
  }

  @override
  String get reachNote =>
      '数は毎日0時すぎに、前の日までの分を足します。人数はその日ごとに数え、誰が見たかは出しません。投稿の数は、誰が見たかを残さずに回数だけを数えます。チームメンバー自身が見た分は、どの数にも入りません。';

  @override
  String get reachPosts => '投稿';

  @override
  String get reachPostShown => '投稿が表示された回数';

  @override
  String get reachPostOpened => '投稿を開いた回数';

  @override
  String get creatorLinksTitle => 'SNSリンク集';

  @override
  String get creatorLinksLead => '発信者ページと共有のページに、ボタンで並びます。';

  @override
  String get creatorLinksEmpty => 'まだリンクがありません。好きなリンクを足すと、発信者ページに並びます。';

  @override
  String get creatorLinksAdd => 'リンクを追加';

  @override
  String get creatorLinksEdit => 'リンクを編集';

  @override
  String creatorLinksClicks(String count) {
    return '$count回';
  }

  @override
  String get creatorLinksShareButton => '共有';

  @override
  String get creatorLinksEditButton => '編集';

  @override
  String get creatorLinksEditTitle => 'リンク集を編集';

  @override
  String get creatorLinksPreviewOpen => 'ページの全体を表示';

  @override
  String creatorLinksPageAppLead(String name) {
    return '追星アプリなら、$nameの配信が始まったら通知で知らせます。';
  }

  @override
  String get creatorLinksPageInstall => 'App Store で入れる';

  @override
  String get creatorLinksPageInstallNote => '入れて開くと、このページの発信者が出ます。';

  @override
  String get creatorLinksPageOpenApp => 'アプリをお持ちの方はこちら';

  @override
  String get creatorLinksClicksLabel => '押された数';

  @override
  String get creatorLinksClicksEmpty => 'まだリンクがありません';

  @override
  String get creatorLinksNote =>
      '押された数は、アプリと共有のページで押された回数の合計です。URL を変えると0に戻ります。誰が押したかは出しません。';

  @override
  String creatorLinksLimit(int max) {
    return 'リンクは$max件までです';
  }

  @override
  String get creatorLinksTitleLabel => '題名';

  @override
  String get creatorLinksTitleHint => '例：ファンクラブ';

  @override
  String get creatorLinksUrlLabel => 'URL';

  @override
  String get creatorLinksUrlNote =>
      'https で始まる URL だけ使えます。短縮 URL（bit.ly など）は使えません。';

  @override
  String get creatorLinksTitleRequired => '題名を入れてください';

  @override
  String creatorLinksTitleTooLong(int max) {
    return '$max文字までです';
  }

  @override
  String get creatorLinksUrlInvalid => 'https で始まる URL を入れてください';

  @override
  String get creatorLinksShortUrl => '短縮 URL は使えません。行き先の URL をそのまま入れてください';

  @override
  String creatorLinksDeleteTitle(String title) {
    return '「$title」を消しますか？';
  }

  @override
  String get creatorLinksDeleteMessage => '押された数も消えます。';

  @override
  String get creatorLinksDelete => '削除';

  @override
  String get creatorLinkReport => 'このリンクを通報する';

  @override
  String get creatorLinksAddShort => '追加';

  @override
  String get creatorAdminMenuSnsNote => '連携・表示する内容';

  @override
  String get creatorAdminSnsTitle => 'SNS';

  @override
  String creatorAdminMenuReachSummary(String count) {
    return '直近30日で $count人に通知を届けました';
  }

  @override
  String get creatorAdminMenuLinks => 'SNSリンク集';

  @override
  String get creatorAdminMenuSectionShare => 'シェア';

  @override
  String get shareInviteTitle => '追星に誘う';

  @override
  String shareInviteMessage(String link) {
    return '追星で私の配信・予定を追いかけてね\n$link';
  }

  @override
  String get shareInviteNote => 'このリンクから追星を入れて開いた人は、あなたをフォローした状態で始まります。';

  @override
  String onboardingInviteFollowed(String name) {
    return '$nameをフォローしました';
  }
}
