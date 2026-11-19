/// Instagram をこの版で出すか（決定事項 1、機能仕様書 4.6.2）。v1.0.0 は出さない（false）。次の版で true にする。
/// false のあいだ、アカウント連携と表示する内容では「準備中」にし、確認済みの Instagram があっても、
/// 投稿・フォロワー数・アカウントをアプリで読まない（[SnsService.offered]）。サーバーの設定（`instagram_dm_account`）では切り替えない。
const instagramOffered = false;

/// ツイキャスをこの版で出すか（決定事項 1、機能仕様書 4.6.2）。v1.0.0 は出さなかった（ツイキャスの API がメンテナンス中だったため）。
/// v1.1.0 で戻した。false にすると、アカウント連携と表示する内容では「準備中」にし、確認済みのツイキャスがあっても、
/// アカウント・フォロワー数・配信中の情報・取得した配信の予約・配信の実績をアプリで読まない（[SnsService.offered]）。
const twitcastingOffered = true;

/// 一覧の読み直しの間隔。サーバーは配信状態を1分ごとに確かめるので、それに合わせる。
const refreshInterval = Duration(minutes: 1);

/// ホームの全体タイムラインで、1回に読む投稿の件数。
const timelineLimit = 50;

/// ホームの全体タイムラインに出す投稿の期間。サーバーが残す期間（90日）と合わせる。
const timelineWithin = Duration(days: 90);

/// 1人の発信者のページに出す、投稿の最大件数。サーバーが残す件数（YouTube 100、Instagram 100、X 300）の合計より大きくする。
const creatorPostsLimit = 600;

/// 発信者のカバー画像の比率（横3：縦1）。発信者ページとプロフィールの編集で使う（画面定義書 2.4.1）。
const creatorCoverAspectRatio = 3.0;

/// 「次の予定」を探す先。
const nextScheduleRange = Duration(days: 366);

/// ホームの「次の予定」に出す件数（決定事項 5）。
const upcomingScheduleCount = 2;

/// ホームの「イベント」に出す件数（決定事項 5）。
const upcomingEventCount = 2;

/// タイムスケジュールで、近接した投稿を「+N」にまとめる間隔（決定事項 5）。
const postClusterGap = Duration(minutes: 30);

/// 推しの検索で、打ち終わってからサーバーに問い合わせるまで待つ時間（機能仕様書 4.2.2）。
const searchDebounce = Duration(milliseconds: 250);

/// X連携プランの月額（表示する内容の注記に出す。機能仕様書 4.6.3）。価格の画面は、ストアの値を出す。
const xOptionYen = 290;

/// 公開ページ（公開サイトのリポジトリ（別管理）の `oiboshi/`。本文は同じリポジトリの `oiboshi/legal/`）。URL は変えない（ストアと Meta の設定に入れるため）。
const termsUrl = 'https://oiboshi.perrii.app/terms';
const privacyUrl = 'https://oiboshi.perrii.app/privacy';
const creatorTermsUrl = 'https://oiboshi.perrii.app/creator-terms';

/// ストアのサブスクの管理の画面。RevenueCat が URL を返さないときに開く。
const appStoreSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';
const googlePlaySubscriptionsUrl =
    'https://play.google.com/store/account/subscriptions';

/// お問い合わせの宛先。
const supportEmail = 'support.oiboshi@perrii.app';
