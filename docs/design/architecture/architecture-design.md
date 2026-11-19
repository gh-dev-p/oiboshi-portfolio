# アーキテクチャ設計書

**追星（oiboshi）**

- 対象プロジェクト：追星（oiboshi）
- 本書の位置付け：Flutter アプリのアーキテクチャ（MVVM + Riverpod）と、それに対応するフォルダ構成・命名規約・依存関係のルール、接続先の切り替えを定める
- 技術スタック：Flutter、flutter_riverpod 3系、Supabase（`supabase_flutter`）、Firebase（FCM。`firebase_core`・`firebase_messaging`）、RevenueCat（`purchases_flutter`）、ログイン（`sign_in_with_apple`・`flutter_web_auth_2`）、端末の安全な保存場所（`flutter_secure_storage`）、WebView（`webview_flutter`。埋め込みプレイヤーと、チケットのページの読み取り）、動画（`video_player`）
- 対象OS：iOS・Android

---

## 1. 本書の目的・範囲

- 本書は、アプリ（`app/`）の構成のルールを定める。機能の追加・リファクタリングは、本書に従う。
- 画面は[画面定義書](../screens/screen-design.md)、機能は[機能仕様書](../specs/functional-spec.md)、データはデータ設計書が正。本書では扱わない。
- サーバー（`supabase/`・`cloudflare/`）は、置き場所と守り方の決まりだけを 3.3・3.4 に書く。
- 表示文言の多言語化（日本語・英語）は、[i18n設計書](i18n-design.md) で定める。接続先の値・シークレット・コマンドは、環境構成に書く。

---

## 2. 採用方式

### 2.1 MVVM + Riverpod

Flutter 公式のアーキテクチャガイド（App architecture）に従う。状態管理は `flutter_riverpod` で統一する。

| MVVM層 | 公式の層 | 実体 | 責務 |
| --- | --- | --- | --- |
| View | UI層 | `lib/ui/<機能>/widgets/`、共通 Widget（`lib/ui/core/ui/`）、`lib/app.dart` | 描画のみ。ViewModel の state を watch して表示し、操作を ViewModel のメソッド呼び出しに変える |
| ViewModel | UI層 | `lib/ui/<機能>/view_models/`、アプリ全体の状態（`lib/ui/core/view_models/`） | 画面用の状態の保持と加工、操作の受け口。Model を呼び、結果を state にして公開する |
| Model | データ層 | `lib/data/repositories/<機能>/`（Repository）、`lib/data/services/<機能>/`（Service） | データの取得・更新（Supabase・FCM・RevenueCat・端末の機能） |

- ドメインモデルは、データ層と UI 層の両方から使うので、`lib/domain/models/` に置く。
- UseCase の層は置かない。複数の Repository を組み合わせる処理は、ViewModel が行う。

### 2.2 依存の向き

- 依存の向きは、View → ViewModel → Model の一方向だけ。
- View が `data/` を直接 import することは禁止する。Repository と Service は、`lib/config/service_providers.dart` で Provider として公開する。View は `service_providers.dart` を import せず、必ず ViewModel を通す。
- ViewModel と Model は、`BuildContext` に依存しない。表示文言を持たず、エラーは種別（enum）で返す。文言への変換は、View で行う。
- 特定の画面に属さない出来事（アプリを開いているときの通知の受信など）は、ViewModel が状態として公開するだけにする。`MaterialApp` の下の View が `ref.listen` して、自分の `context` で表示する。

---

## 3. フォルダ構成

### 3.1 アプリ（`app/lib/`）

```
lib/
  ui/                 UI層（View・ViewModel）。機能ごとのフォルダに分け、各フォルダに widgets/ と view_models/ を置く
    core/
      ui/             共通 Widget（2つ以上の機能で使う部品）
      themes/         色・文字スタイル・テーマ（ライト・ダーク）
      view_models/    アプリ全体の状態と、ViewModel の共通の道具（読み直し・失敗の扱い・保存する設定の土台など）
    onboarding/       初回起動
    home/             ホームの枠（下部ナビ・タブ・固定ビューアを重ねる）と、ホームの本文・埋め込みビューア
    oshi/             推しリスト・推しを探す
    creator/          発信者ページと、固定ビューア
    post/             投稿ビューア
    schedule/         タイムスケジュール・月のカレンダー・予定とイベントの詳細・イベント一覧
    report/           通報
    settings/         設定・ログイン・再認証・退会など
    creator_admin/    発信者向け（登録・発信者メニュー・プロフィール・アカウント連携・予定とイベントの登録・プラン）
    notification/     通知の送り先の登録と受信（画面は持たない）
  domain/models/      ドメインモデル・エラー種別・例外、チケットサイトの検索の手順と解析（4.3）
  data/               データ層。repositories/ と services/ に分け、その中を機能ごとに分ける（共通は common/）
  config/             Repository・Service の Provider、端末内の保存領域、Provider の再試行の設定、接続先（6章）、定数
  utils/              特定の層・機能に属さない処理（書式・サーバーの日時・URL を開く・検索の言葉の正規化など）
  l10n/               表示文言（i18n設計書）
  app.dart            MaterialApp と、起動時の振り分け
  bootstrap.dart      起動処理（6.2）
  main.dart           エントリポイント
```

- 機能のフォルダは、画面定義書の画面のまとまりに合わせる。画面を足したときに、置き場所に迷わないようにするため。
- 公式の構成のうち、`data/model/`（API のモデル）は置かない。ドメインモデルが、Supabase の行との変換を兼ねる。
- ルーターを使わないので、`routing/` も置かない。画面の遷移は、Navigator の push・pop で行う。

### 3.2 テスト（`app/test/`）

```
test/
  fakes.dart          フェイクと見本のデータをまとめて読み込む入り口
  fakes/              Repository ごとのフェイク、共有のデータ（FakeData）、テストのアプリ（testApp）
  helpers/            見本のデータと、Widget のテストの手順（画面を出す・外すなど）
  <対象>_test.dart    単体テスト
  screens/            画面のテスト
```

### 3.3 サーバー（`supabase/`）

```
supabase/
  config.toml         ローカル（Supabase CLI）の設定と、Edge Functions ごとの JWT の確かめの有無
  seed.sql            ローカル専用の初期データ
  migrations/         テーブル・RLS・関数（データ設計書）と、定時実行の登録（一覧と間隔は機能仕様書 4.8.1）
  functions/
    _shared/          Edge Functions の処理の本体
      cron.ts・http.ts          受け口の土台（定時実行用・アプリ用）
      sources/                  SNS ごとの取得
      account_link/             アカウント連携の、SNS ごとの定義
      <処理>.ts                 関数ごとの処理と、その部品（単体テストは <処理>.test.ts）
    <関数名>/index.ts  関数の受け口
  tests/database/     RLS と関数のテスト（`supabase test db`）
  debug/              確認用の発信者とイベント
```

| 呼ばれ方 | 関数 |
| --- | --- |
| 定時実行 | `check-lives`（配信の確認と通知）・`sync-posts-fast`・`sync-posts`（投稿）・`sync-schedules`（予約）・`sync-followers`（フォロワー数）・`sync-live-records`（終わった配信）・`purge-left-creators`（退会して90日を過ぎた発信者の削除）・`purge-deleted-videos`（消えた動画の削除）・`notify-schedules`（予定の事前通知） |
| アプリ | `link-account`（アカウント連携。SNS からの戻りも受ける）・`fetch-profile`（プロフィールの取り込み）・`read-event-url`（チケットのページの読み取り）・`register-creator`・`reclaim-creator`（登録・取り戻し）・`sync-subscription`（購入のあとの加入の書き直し）・`revoke-apple`（Apple のひも付けの取り消し）・`delete-account`（退会）・`submit-report`（通報） |
| Webhook | `revenuecat-webhook`（課金） |

<kbd>守り方</kbd>

- どの関数も `config.toml` で `verify_jwt = false` にし、確かめを関数の中で行う。
  - 定時実行：pg_cron が `invoke_edge_function` で呼び、関数が合言葉（`CRON_SECRET`）を確かめる。SQL だけで済む処理は、pg_cron が SQL の関数を直接呼ぶ。
  - アプリ：ユーザーのトークンを付けて呼び、関数がトークンからユーザーを引いて確かめる（`auth.getUser`）。ない・正しくないときは `unauthorized`（401）。`link-account` の SNS からの戻りにはトークンが付かないので、確かめを関数の中の1か所にそろえるため、どの関数も Supabase の入り口では確かめない。
  - Webhook：`Authorization` ヘッダーを確かめる。
- アプリから呼ぶ関数は、結果を文言ではなくコード（`{ result }`・`{ error }`）で返す。データを返す関数は、そのデータを返す。アプリの Repository が、コードをエラー種別（enum）に変える。

<kbd>秘密を持つ側</kbd>

- SNS の呼び出しは、Edge Functions だけが行う。アプリには、SNS のキー・トークンを持たせない。
- 課金の加入の状態は、サーバーだけが書く。アプリは RevenueCat の SDK で購入し、`sync-subscription` を呼んで、Webhook を待たずに加入を引き直させる。サーバーは REST API（シークレットキー）で状態を引き直す。アプリには、RevenueCat の公開用のキーだけを持たせる。
- Sign in with Apple の鍵は、サーバーのシークレットにだけ置く。アプリは、再認証で受け取った Apple の一時的なコードを `revoke-apple` に渡すだけ（`AuthRepository` の後ろに隠す）。

<kbd>書き方</kbd>

- 関数の処理は、`_shared/` に置く。データベースや外部を呼ばない処理（読み方・組み立て・判定）には、単体テスト（`_shared/xxx.test.ts`）を付ける。
- 各関数の `index.ts` は、受け口と配線（`_shared/` の呼び出し、差し替えられる依存の受け渡し、短い読み書き）までにする。

### 3.4 Cloudflare Workers（`cloudflare/`）

- `report-mail/`：通報のメールを運営に送る Worker。`submit-report` が、合言葉のヘッダー付きで呼ぶ。
- 受け取った中身の確かめ（`src/mail.ts`）は、Deno でテストでき、`supabase/functions` の `deno task test` で一緒に実行する。
- 作り方・binding・シークレットは、環境構成 8章。シークレットと送り先は、リポジトリに書かない。

---

## 4. 命名・実装規約

### 4.1 View

| 種類 | 命名 | 内容 |
| --- | --- | --- |
| Screen | `xxx_screen.dart` | Navigator で push して開く画面 |
| Body | `xxx_body.dart` | ホームのタブの本文（ホーム・推しリスト・スケジュール）。push・pop は使わない。設定と発信者のタブは、Screen をそのままタブの最初の画面にする |
| ホームの枠 | `home_shell.dart` | 下部ナビ、タブごとの Navigator、固定ビューアを重ね、タブを `PageView` で切り替えて残し続ける |
| Sheet | `xxx_sheet.dart` | ボトムシート。開く処理を、同じファイルのトップレベル関数（`showXxxSheet`）で公開する |
| 画面の一部 | `xxx_page.dart`・`xxx_mode.dart`・`xxx_parts.dart`・`xxx_panel.dart` など | 1つの画面を分けた部品 |
| 画面専用の小部品 | － | その機能でだけ使う Widget。同じ `widgets/` に置く。複数の機能で使うものは、`lib/ui/core/ui/` に置く |

- View は、ロジックを持たない。`ref.watch` で ViewModel の state を読み、操作は ViewModel のメソッドの呼び出しに変える。入力欄の内容、拡大・縮小、動画・WebView のコントローラなど、その画面の中で完結する表示用の状態は、View が持ってよい。入力値からドメインモデルを組み立てる処理と、入力チェックは、ViewModel に置く。
- 複数の画面から呼ぶ「シートを出して結果を返す」流れは、そのシートのファイルのトップレベル関数にする（例：`reauth_sheet.dart` の `ensureReauthenticated`）。関数は、Provider を直接読まず、シートの ViewModel を通す。
- エラー種別から文言への変換は、その種別を受け取る View のファイルの中に置く。
- View が受け取るデータは、自分の ViewModel から受け取る。読み取り用 Provider（`xxx_providers.dart`）を View から直接 watch しない。読み直し（`ref.invalidate`）も View からは行わず、ViewModel の `retry()`・`refresh()` を呼ぶ。
- 端末の機能（写真を選ぶ、権限を求める）は、View から SDK を直接呼ばず、Service に包み、ViewModel を通して使う。
- 1行の文字は、`Text`（`maxLines: 1`）ではなく、`OneLineText`（`lib/ui/core/ui/one_line_text.dart`）で出す。絵文字の書体で行が高くなり、枠からはみ出すのを防ぐため。`test/one_line_text_test.dart` が見張る。文字を入れる枠の高さは、`MediaQuery.textScalerOf(context)` で伸ばす。
- 文言は、i18n設計書に従う。

<kbd>View が ViewModel を通さずに見てよいもの</kbd>

次に挙げるものだけ。広げない。

- アプリの土台（`app.dart`）：画面モード・表示言語・処理中の表示・初回起動が済んだかを watch する。RevenueCat のユーザー（`billingUserProvider`）と通知の送り先の登録（`pushRegistrationProvider`）は、初回起動が済んでから `ref.listen` し続ける。
- 画面をまたぐ表示の状態（`lib/ui/core/view_models/`）：処理中の表示（`loadingOverlayProvider`）、固定ビューアの状態（`playback_provider.dart`）、音を出している動画（`audio_focus_provider.dart`）。
- 固定ビューアの配信の終わり：固定ビューア（`live_player_host.dart`）は、`creator_providers.dart` の `liveEndWatcherProvider` を `ref.listen` し、ホームの枠に知らせる。
- ホームの機能の中：ホームの枠・本文・埋め込みビューア（`home_live_panel.dart`）は、1つの画面として、`home_providers.dart`（埋め込みビューアで流している推し、いちばん上へ戻す合図）と、互いの ViewModel を読み書きしてよい。
- 通知の受信：アプリの土台が、起動したときから `liveNotificationViewModelProvider` を `ref.listen` し続け、初回起動の途中に受けた出来事も残す。ホームの枠も `ref.listen` し、発信者ページを開くかスナックバーを出して、出来事を消す。

<kbd>機能をまたぐ import</kbd>

- View が、ほかの機能から import してよいのは、遷移先の Screen・Sheet・Dialog（`xxx_screen.dart`・`xxx_sheet.dart`・`xxx_dialog.dart`。トップレベル関数を含む）だけ。
- 例外1：ホームの枠（`home_shell.dart`）は、タブの Body・固定ビューア（`live_player_host.dart`）・通知の ViewModel も import してよい。ほかの機能の読み取り用 Provider や状態は、ホームの枠の ViewModel を通す（タブの選択は `HomeShellViewModel`、ほかの機能から受け取る状態は `HomeShellSourcesViewModel`。4.2）。
- 例外2：`home/widgets/home_tabs.dart` は、どの機能の View も import してよい。画面を受け持ちのタブで開く仕組み（`HomeTabs.open`。画面定義書 5.1.8）と、タブの種類（`HomeTab`）、いま選んでいるタブ（`HomeTabs.currentOf`）を置く。ほかのホームのファイルは、ほかの機能から import しない。
- それ以外の部品を、ほかの機能から使うときは、`lib/ui/core/ui/` に移す。ViewModel 層の import は、4.2 に従う。

### 4.2 ViewModel

| 種類 | 命名 | 内容 |
| --- | --- | --- |
| 読み取り用 Provider | `<機能>_providers.dart` | 機能のフォルダ単位で、複数の画面で共有するデータと、画面をまたぐ手続きの状態を公開する。複数の ViewModel から呼ぶ手続きを、`Ref` を受け取る関数として置いてもよい |
| 操作用 ViewModel | `xxx_viewmodel.dart` | 画面の操作（入力値・読み込み中とエラーの状態・Repository の呼び出し）をまとめる。`XxxViewModel` を `xxxViewModelProvider` として公開する |
| アプリ全体の状態 | `xxx_provider.dart` | どの機能にも属さない状態。`lib/ui/core/view_models/` に置く |

<kbd>置き方</kbd>

- ファイルは、その機能の画面と同じ機能フォルダの `view_models/` に置く。複数の機能から使う状態は、主に扱う機能の `<機能>_providers.dart` に置く。
- View と ViewModel は、1対1にする。1つの画面を構成する Widget の集まり（その画面から開くシートを含む）に、1つの ViewModel。
- 1ファイルに置く ViewModel は1つ。状態クラス・エラー種別の enum・ViewModel・Provider を、この順に並べる。`<機能>_providers.dart` と `playback_provider.dart`（固定ビューアの、互いに関わる状態）を除き、1ファイルに置く Notifier も1つにする。
- その画面だけで使う読み込みは、ViewModel のファイルの中に、非公開の `FutureProvider`（キーを取るときは `.family`）として置く。テストで読むときだけ、非公開にせず `@visibleForTesting` を付ける。
- 読み取り用 Provider をそのまま状態にする ViewModel が複数あるときは、`<機能>_providers.dart` に基底クラスを置いて継ぐ（例：`CreatorAdminDataNotifier`）。同じ入力を扱う画面どうしの入力の組み立てと検証は、機能の `view_models/` に関数として置く（例：`schedule_input.dart`）。

<kbd>Notifier の型と寿命</kbd>

- 入力値・読み込み中・エラーを画面に出すとき：`AsyncNotifier`。1つの `AsyncValue` に収まらない状態は、`Notifier` で独自の状態クラスを公開する。
- 状態を持たず、操作だけを受け持つとき：`Notifier<void>`。失敗は結果の値（bool・enum）で返す。`guard.dart` の `succeeded`・`guard` で囲む。
- `StateNotifier`・`AutoDisposeNotifier`・`FamilyNotifier` は使わない。キーを取る ViewModel（`.family`）は、キーをコンストラクタで受け取る。
- 破棄するかどうかは、Provider の宣言（`.autoDispose`）で決める。
  - push で開く画面とシートの ViewModel：`.autoDispose` にする。
  - タブの Body とホームの枠の ViewModel：`.autoDispose` にしない。タブは残り続け、切り替えても状態（検索語・選んだ日など）を保つため。ただし、`HomeShellSourcesViewModel` は `.autoDispose` にする（`.autoDispose` の `ownedCreatorProvider` を、ホームの枠が見ている間だけ生かすため）。
  - 状態を持たない初回起動の ViewModel：`.autoDispose` にしない。初回起動を済みにすると、処理の途中で画面ごと入れ替わるため。
  - ログインのシートの ViewModel（`loginViewModelProvider`）：`.autoDispose` にしない。シートを閉じたあとも、ユーザーの切り替えのあとの処理を終える必要があるため。
- `await` のあとに `state`・`ref` を使う前は、`ref.mounted` を確かめる。
- 画面の表示に関わる値（検索語・選択など）は、ViewModel のフィールドではなく state に入れる。

<kbd>読み込みと読み直し</kbd>

- データを読む Provider は、`auth_session_provider.dart` の `withSession(ref, (userId) => …)` で囲み、先にサインインを待つ。サインインに失敗したら、各画面が「読み込めない」を出す。
- 一覧は、`refresh.dart` の `refreshPeriodically` で、1分ごと（`app_constants.dart`）に Repository を呼び直す。リアルタイムの購読は使わない。作り直しの間と失敗したときは、前の値を残す。
- View は、読み込みの状態の判定を `async_state.dart` で行う（値があれば内容、なくて読み込み中ならスケルトン、なくて失敗なら「読み込めない」）。
- 「もう一度試す」と引いて更新は、`refresh.dart` の `reloadFrom` で、サインインと読み込みの Provider を作り直す。
- `.family` のキーに一覧を含む値を使うときは、`value_key.dart` の `ProviderKey` を継いだクラスにする（レコードは一覧の中身を比べず、作り直しが止まらなくなるため）。
- 端末内に保存する設定の Notifier は、`stored_setting.dart` の `StoredSetting` を継ぐ。
- ボタンを押したときなどの、画面全体の読み込み中表示は、View が `loadingOverlayProvider` の `run` で処理を囲んで出す。ViewModel は、読み込み中を個別に持たない。

<kbd>機能をまたぐ import</kbd>

- ViewModel は、ほかの機能の読み取り用 Provider（`<機能>_providers.dart`）と、共有のための状態クラス・基底クラス（例：`oshi/view_models/creator_search_state.dart`）を import してよい。
- ほかの機能の操作用 ViewModel（`xxx_viewmodel.dart`）は import しない。
- 読み取り用 Provider を、ViewModel のファイルから再 export しない。

<kbd>Riverpod 3 の既定の挙動</kbd>

- 失敗した Provider の自動再試行：行わない。`ProviderScope` に `retry: noProviderRetry`（`provider_retry.dart`）を渡す。テストにも渡す。
- 見えない画面の監視の一時停止：上に別の画面が積まれて見えない画面の `ref.watch` は止まる。画面が見えない間も続ける副作用（通知を押して開く画面、通知の送り先の登録、RevenueCat のユーザー）は、`ref.listen`・`ref.listenManual` で監視する。

### 4.3 Model

- **ドメインモデル**（`lib/domain/models/`）：データクラス。Supabase の行との変換（`fromRow` など）と、データだけで完結する処理（新着の判定、タイムスケジュールの配置など）は置いてよい。通信・Provider・表示文言には依存しない。保存した名前から enum を引くときは、`enum_name.dart` の `byNameOrNull` を使う。
- **チケットサイトの検索**（`ticket_search.dart`）：検索の URL、ページから取り出す JavaScript、結果の解析を、状態を持たない関数として `lib/domain/models/` に置く。ページを開くのは View の WebView なので、`data/services` には分けない（View は `data/` を import しないため）。
- **エラー種別と例外**：Repository が返すもの（例：`AppErrorKind`・`AppException`）は、`lib/domain/models/` に置く。ViewModel が自分で決めるもの（入力チェック・保存の結果）は、その ViewModel のファイルに置く。
- **Repository**（`lib/data/repositories/<機能>/xxx_repository.dart`）：Service から取ったデータをドメインモデルに変換し、外部のエラーをエラー種別・例外に変換して返す。1つの Repository が、複数の Service を使ってよい。PostgREST・Postgres のエラーコードは、`common/error_mapping.dart` の `PgCodes` で見る。
- **Service**（`lib/data/services/<機能>/`。共通は `common/`）：外部の SDK・API を包むだけにし、状態を持たず、結果・エラーをそのまま返す。

| 命名 | 内容 |
| --- | --- |
| `xxx_service.dart` | Supabase（Auth・テーブル・Edge Functions）・FCM・RevenueCat・端末の機能などの SDK のラッパー |
| `xxx_storage_service.dart` | Supabase Storage への入出力 |
| `xxx_store.dart` | 端末内の保存領域（`SharedPreferences`） |
| `xxx_storage.dart` | SDK に渡す保存の実装（例：Supabase のログインの情報を、端末の安全な保存場所に置く） |

- ViewModel は Repository を使い、Service を直接使わない。ただし、端末の画像の選択（`ImagePickerService`）は、データを扱わないので、ViewModel から直接使ってよい。
- Repository と Service は、接続先（`SupabaseClient`・`ImagePicker` など）をコンストラクタで受け取る。実体は `service_providers.dart` で渡す。静的な API しかない SDK（RevenueCat・Sign in with Apple・アプリ内のブラウザ・権限・アプリの情報）と FCM は、Service の中で直接呼ぶ。FCM は、Firebase を初期化できていなければ null を受け取り、通知の機能を止める。
- Supabase のテーブル名・列名・ストレージのパス・Edge Functions の名前は、`common/supabase_names.dart` にまとめる。
- Service の書き方：
  - Edge Functions の結果は、`common/edge_functions.dart` の `invokeResult`・`invokeData` で読む。
  - RPC は、型付き（`rpc<PostgrestList>` など）で呼ぶ。
  - 画像のアップロードは `common/image_upload.dart`、アプリ内のブラウザでの OAuth は `common/web_auth.dart` を使う。
  - 渡す一覧が空のときに読まずに済ませる確かめは、Service の1か所で行う。
- `data/` は、公式では種類（`repositories/`・`services/`）ごとに分けるだけだが、探しやすさのため、その中を機能ごとのフォルダに分ける。

### 4.4 共通（ui/core・config・utils）

- `lib/utils/` は、ui・data に依存しない。ドメインモデルからも使ってよい。日付・時刻の書式は、表示言語（`AppLocalizations`）を引数で受け取る。
- 定数・`utils/`・テーマ・共通 Widget は、各機能のフォルダと `data/` に依存させない。共通 Widget は、必要なデータを引数で受け取る。画面遷移が必要なものは、遷移先の画面を import せず、コールバックとして受け取る。

### 4.5 テスト

- ViewModel・Repository・ドメインモデル・書式・共通 Widget の単体テストは、`app/test/` の直下に `<対象>_test.dart` で置く。
- 画面のテストは、`app/test/screens/` に、機能ごとにまとめる。大きい画面と、機能をまたぐ仕組み（固定ビューア・読み直しなど）は、その名前の `xxx_screens_test.dart` に分ける。実際の View と ViewModel を、フェイクの Repository で動かす。
- フェイクは、Repository の単位で作る（`FakeXxxRepository implements XxxRepository`）。データは共有の `FakeData` に持たせ、テストから中身を確かめる。Repository の中の処理を確かめるときは、その Repository の Service をフェイクにする（`fake_auth_service.dart`）。
- `testApp` は、`ProviderScope` に、フェイクの Repository と `retry: noProviderRetry` を渡して、アプリを作る。
- 1分ごとの読み直しのタイマーが残らないように、画面のテストの最後に画面を外す（`helpers/widget_helpers.dart` の `unmount`）。

---

## 5. 新機能追加時のチェックリスト

1. 画面を追加する　→　`lib/ui/<機能>/widgets/xxx_screen.dart`（ホームのタブの本文なら `xxx_body.dart`、ボトムシートなら `xxx_sheet.dart`）
2. その画面が状態を持つ・データを操作する　→　`lib/ui/<機能>/view_models/xxx_viewmodel.dart` を、画面ごとに1つ用意する。画面から `data/` を直接呼ばない。その画面だけの読み込みは、ViewModel のファイルの非公開の `FutureProvider` に置く
3. 複数の画面で共有する読み取りデータ・手続きの状態がある　→　`lib/ui/<機能>/view_models/<機能>_providers.dart` に追加する
4. 新しいデータの形が必要　→　`lib/domain/models/` に、通信を持たないクラスとして追加する
5. Supabase・FCM・RevenueCat・端末の機能とのやりとりが必要　→　`lib/data/repositories/<機能>/`・`lib/data/services/<機能>/` に 4.3 の命名で追加し、`lib/config/service_providers.dart` に Provider を追加する
6. Repository を追加する・メソッドを足す　→　`app/test/fakes/` にフェイクを足し（`fakes.dart` から export する）、`testApp` で差し替える
7. テストを書く　→　ViewModel・モデルは `app/test/` の直下、画面は `app/test/screens/` に置く。`flutter analyze`・`flutter test` を行う
8. テーブル・RLS・Edge Functions を変える　→　データ設計書を先に直してから、`supabase/` を直す。`supabase test db` と、`supabase/functions` での `deno task test`・`deno task check` を行う
9. Edge Function を追加する　→　`supabase/functions/<名前>/index.ts` を作り、`deno.json` の `check` タスクと、`config.toml` の `verify_jwt = false` を足す（3.3）。定時実行から呼ぶ関数は、migration で `cron.schedule` と `invoke_edge_function` の登録を足し、機能仕様書 4.8.1 に間隔を書く
10. エラーを表示する　→　ViewModel・Model はエラー種別を返し、View で文言に変換する
11. 文言を足す　→　i18n設計書 4章に従い、`lib/l10n/app_ja.arb`・`app_en.arb` の両方に足す。生成物もコミットする

---

## 6. 環境分離（接続先の切り替え）

### 6.1 方式

- 接続先と公開用のキーは、`--dart-define-from-file` で渡す。値は `lib/config/app_env.dart` が読む。ファイル・キー・起動コマンドは、環境構成 1・2・10章。
- 環境は、prod（本番の Supabase プロジェクト）、dev（dev の Supabase プロジェクト）、ローカル（Supabase CLI）の3つ。
- アプリは、ビルドの単位（Flavor）で、prod と dev の別のアプリに分ける。アプリ ID・表示名・アイコン・エントリポイント（`lib/main_prod.dart`・`lib/main_dev.dart`）が違い、dev は全画面に「DEV」の帯を出す。ローカルの Supabase には、dev のアプリでつなぐ。
- Flavor と接続先の組み合わせは、起動のはじめに確かめる（`lib/config/app_flavor.dart` の `flavorMismatch`）。prod のアプリは本番の Supabase だけ、dev のアプリは本番以外にだけつなぐ。
- 値がないときは、次のように動く。

| 値 | ないとき |
| --- | --- |
| Supabase の URL と公開用のキー | 起動に失敗し、エラーの画面を出す（prod のアプリは、本番の URL でないときも） |
| RevenueCat の公開用の SDK キー（OS ごと） | その端末で、課金の機能を出さない |
| Firebase（FCM）の接続の値 | その端末で、通知の送り先を登録しない |

### 6.2 起動処理

エントリポイント（`lib/main_prod.dart`・`lib/main_dev.dart`）が、Flavor を付けて `lib/bootstrap.dart` の `bootstrap()` を呼ぶ。`bootstrap()` は、次の順に行う。

1. Flavor を `AppFlavor.current` に入れ、接続先と食い違わないかを確かめる。食い違えば、つながずにエラーの画面を出す。
2. `SharedPreferences` を読み込む。`ProviderScope` で `sharedPreferencesProvider` を上書きし、最初の描画から、保存した画面モードと表示言語で出す。
3. Supabase を初期化する。ログインの情報の保存先に `SecureSessionStorage` を渡す。SNS のログインは、アプリ内のブラウザから戻ったコードを `AuthService` が換えるので、`detectSessionInUri` は false にする。
4. Firebase（FCM）を、設定ファイルを使わず、`AppEnv.firebaseOptions` で初期化する。
5. `ProviderScope`（`retry: noProviderRetry`）で `app.dart` を起動する。

<kbd>異常系</kbd>

- `SharedPreferences` の読み込みか Supabase の初期化に失敗したとき、または Supabase の初期化が10秒で終わらないとき　→　白い画面にせず、エラーの内容を出す画面（`StartupErrorApp`）を出す
- Firebase の値がないとき・初期化に失敗したとき・10秒で終わらないとき　→　止めずに起動し、通知の送り先の登録だけをしない

<kbd>起動のあと</kbd>

- RevenueCat は、起動処理では初期化しない。`BillingService` が最初に使うときに初期化する。
- アプリの土台（`app.dart`）が、初回起動が済んでから、ユーザーに合わせて、RevenueCat のユーザーと、通知の送り先の登録をそろえ続ける。
- 届いた通知と、通知を押して開いたことは、`lib/ui/notification/view_models/` が状態として公開し、ホームの枠が発信者ページを開くかスナックバーを出す。
