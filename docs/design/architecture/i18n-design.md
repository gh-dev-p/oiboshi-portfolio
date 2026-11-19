# 多言語化（i18n）設計書

**追星（oiboshi）**

- 対象プロジェクト：追星（oiboshi）
- 本書の位置付け：表示言語（日本語・英語）の切り替えの仕組みと、表示文言の管理の方法を定める
- 技術スタック：Flutter（`flutter_localizations`・ARB・`flutter gen-l10n`）、`intl`

---

## 1. 本書の目的・範囲

- 本書は、アプリの表示文言を日本語・英語で切り替える仕組みと、文言の追加・管理のルールを定める。
- 対応する言語：日本語（`ja`。元の言語）・英語（`en`）。
- 対象：`app/lib/ui/` の画面に出す文言（Text・ボタン・ツールチップ・スナックバー・ダイアログ・シート・プレースホルダ・空の状態・エラー）、`app/lib/bootstrap.dart` のエラーの画面、日付・時刻・数の表記。
- 対象外：コメント・ログ・画面に出さない例外のメッセージ・サーバーに保存する値。
- サーバーが決める文言（配信開始の通知）は 6.5 に、OS に出す文言（iOS の権限の説明・Android の通知のチャンネル）は 6.6 に書く。
- ViewModel・Model が `BuildContext` と表示文言を持たないという依存のルールは、[アーキテクチャ設計書](architecture-design.md) 2.2 で定める。

---

## 2. 採用方式

Flutter 公式の `flutter_localizations` と、ARB ファイル＋`flutter gen-l10n` のコード生成を使う。設定は `app/l10n.yaml`。

- 文言の正本：`app/lib/l10n/app_ja.arb`（テンプレート）・`app/lib/l10n/app_en.arb`。2つのファイルは、同じキーを持つ。
- 生成物（`app/lib/l10n/app_localizations*.dart`）もコミットする。ビルドのときにも自動で生成する（`pubspec.yaml` の `flutter.generate: true`）。
- 各キーには、`@キー名` の `description` に、使う画面（画面定義書の呼び名）と用途を書く。

---

## 3. 表示言語の決め方

### 3.1 通常の起動

`OiboshiApp`（`app/lib/app.dart`）が、`appLanguageProvider` の値を `MaterialApp.locale` に渡す。View は、`AppLocalizations.of(context)!` で、今の表示言語の文言を引く。

### 3.2 表示言語の保存と復元

`appLanguageProvider`（`app/lib/ui/core/view_models/app_language_provider.dart`）が、表示言語（`AppLanguage`）を持つ。

| `AppLanguage` | `MaterialApp.locale` | 表示 |
| --- | --- | --- |
| `system`（初期値） | `null` | 端末の言語の優先順で、最初に対応している言語。日本語・英語のどちらでもなければ、`supportedLocales` の先頭の英語 |
| `ja` | `Locale('ja')` | 日本語 |
| `en` | `Locale('en')` | 英語 |

- 選んだ値は、端末内（`SharedPreferences` のキー `appLanguage`。画面モードと同じ保存先）に保存する。最初の描画から、保存した言語で出す。
- 切り替えは、`MaterialApp.locale` にすぐ反映する。アプリの再起動は要らない。
- 退会のあとは、端末の設定に従うに戻る（機能仕様書 4.1.3）。

### 3.3 起動に失敗したときの画面

Supabase の初期化に失敗したときの画面（`app/lib/bootstrap.dart` の `StartupErrorApp`）は、専用の `MaterialApp` で出す。Riverpod に頼らず、`locale` を渡さないで端末の言語に従う。設定で選んだ言語は反映しない。

### 3.4 表示言語の切り替え（設定の「言語」）

設定の「言語」から、言語（シート）（画面定義書（設定・発信者向け）2.1.8）で選ぶ。

- 「日本語」「English」は、どの表示言語でも、その言語の表記で出す（`appLanguageName`）。

<kbd>補足・実装メモ</kbd>

- 言語を足すときは、`app_<言語コード>.arb` を足し、`AppLanguage` と、言語（シート）の選択肢を足す。日付・数の書式（7章）で、日本語だけを特別に扱っているところも確かめる。

---

## 4. キーの命名規約

ARB のキーには、使う場所に対応する接頭辞を付ける。画面IDは振らないので（画面定義書 1章）、`app/lib/ui/` の機能のフォルダの名前に合わせる。複数の機能のフォルダにまたがる機能（イベント・公演・固定ビューア）は、フォルダではなく機能の名前を接頭辞にする。

| 接頭辞 | 対象 | 例 |
| --- | --- | --- |
| `common*` | 複数の画面で共通する文言（ボタン・共通のエラー・状態表示・フォローのボタンなど） | `commonCancel`, `commonLoadFailedTitle`, `commonFollow` |
| `time*`・`duration*` | 相対時刻・残り時間・長さ（`lib/utils/formatters.dart`・`l10n_labels.dart`） | `timeMinutesAgo`, `durationHoursMinutes` |
| `*Name` | Model の種類（enum）の表示名（6.1） | `snsServiceName`, `postKindName`, `creatorPlanName` |
| `onboarding*` | 初回起動（ウェルカム・推しを選ぶ・通知の説明） | － |
| `home*` | ホーム（外枠・本体） | － |
| `oshi*` | 推しリスト・推しを探す | － |
| `post*` | 投稿ビューア | － |
| `creator*` | 発信者ページ・配信映像 | － |
| `schedule*` | タイムスケジュール・月のカレンダー・絞り込み・予定の詳細 | － |
| `report*` | 通報（シート） | － |
| `settings*` | 設定・通知設定・画面モード・言語・退会・ログイン方法 | － |
| `creatorAdmin*` | 発信者の登録・発信者メニュー・発信者向けの設定・プラン | － |
| `event*` | イベントと、予定の長さ。イベントの一覧・詳細（`schedule/`）と、イベントの管理・登録・候補・チケットサイトで探す（`creator_admin/`） | `eventListAllTitle`, `eventLength` |
| `performance*` | イベントの公演。公演の候補・公演を選ぶ（`creator_admin/`） | `performancePickerTitle` |
| `fixedViewer*` | 固定ビューア。帯・空のときの案内（`home/`・`creator/`） | `fixedViewerModeLive` |
| `appTitle`・`startupErrorTitle`・`priceYen` | 特定の画面に属さないもの | － |

- 複数の画面で使う文言は `common*` にまとめ、同じ文言のキーを画面ごとに作らない。文言を足すときは、まず `common*` で流用できないかを確かめる。
- 共通 Widget（`app/lib/ui/core/ui/`）は、`common*`・`time*`・`duration*`・`*Name` のキーだけを使う。機能の接頭辞のキーは使わない。機能のフォルダから `core/` に移した部品は、キーも `common*` に移す。
- 日本語の文言は、元の言語として先に決め、英語はそれに合わせる。

---

## 5. プレースホルダー

- 値を埋め込む文言は、文字列の連結ではなく、ARB のプレースホルダーを使う。語順が言語で変わるため。複数の値を区切りの記号（「・」など）で並べるだけの表示も、区切りを含めて ARB のキーにする。
- 英語で数によって語が変わる文言は、ICU の `plural` を使う。
- 種類で文言を選ぶ文言は、ICU の `select` を使う（6.1）。

---

## 6. ViewModel・Model での文言の扱い

ViewModel・Service・Model は、表示文言を持たない。種類やエラーは enum か有無で返し、文言への変換は View で `AppLocalizations` を使って行う。

### 6.1 Model の種類（enum）

- enum（`SnsService`・`PostKind`・`CreatorPlan`・`ReportReason`・`AppLanguage` など）は、文言を持たない。表示名は、`app/lib/ui/core/ui/l10n_labels.dart` の `AppLocalizations` の拡張で引く。拡張は、`select` の ARB キー（`snsServiceName` など）に enum の `name` を渡す。
- 予定のように、Model の値から決まる表示（タイトルのない配信の「配信」、予定の日時など）も、同じファイルの拡張・関数で作る。Model は、タイトルを空のままにするなど、値だけを持つ。
- 固有名詞は、どの言語でも同じ表記で、Model に持つ。`LoginProvider` の名前（Apple・Google・X・Twitch）と、チケットサイトの名前（`TicketSite.label`・`EventLink.siteName`）。SNS の名前は、英語で表記が変わる（ツイキャス／TwitCasting）ので、`snsServiceName` で引く。イベントのリンクがツイキャスのページのときは、`EventLink` はツイキャスかどうか（`isTwitCasting`）だけを返し、View が `snsServiceName` で名前を引く（`l10n_labels.dart` の `eventLinkSite`）。

### 6.2 エラー

- エラーの種類で表示を変えるときは、enum で返し、View で文言にする（例：`AccountLinkResult`）。
- エラーが1種類しかないときは、enum を作らず、View が `AsyncValue.hasError` や戻り値の有無を見て、共通の文言（`commonSaveFailed` など）を出す。
- Edge Functions は、アプリに文言ではなく、結果のコード（`{ result }`・`{ error }`）を返す。Repository がコードを enum に変え、View が文言にする。

### 6.3 文言を引数で受け取る

ViewModel の処理に文言が要るときは、呼び出し元の View から引数で受け取る（例：お問い合わせのメールの件名と本文）。

### 6.4 ストアの価格

- 日本円の金額は、`priceYen` の書式で書く（日本語は「290円」、英語は「¥290」）。
- ストアの価格（`PlanPrice`）は、日本円なら `priceYen` で書き、ほかの通貨はストアが整えた書式（`formatted`）のまま出す。どの画面で、どの価格を出すかは、画面定義書（設定・発信者向け）2.3.6 に従う。

### 6.5 サーバーが決める文言

- 配信開始の通知の文言（機能仕様書 4.3.3）・予定の事前通知と追いたいの人の登録の通知の文言（機能仕様書（届ける・広める）4.1.1・4.5.2）は、サーバー（`supabase/functions/_shared/fcm_message.ts`）が、送り先ごとに、その端末の言語（`device_tokens.language`）で作る。英語では、ツイキャスを「TwitCasting」、追星を「Oiboshi」と書く。
- アプリは、送り先を登録するときに、通知の言語（`ja`・`en`）も送る。通知の言語は、アプリの表示言語と同じにする。端末の設定に従うときは、`MaterialApp` と同じ決め方（`basicLocaleListResolution`）で、端末の言語の優先順から選ぶ（`AppLanguage.notificationLanguage`）。
- 設定の「言語」を変えたら、送り先を、新しい言語で登録し直す。端末の言語を変えたとき（端末の設定に従うとき）は、次の登録（アプリの起動など。機能仕様書 4.3.3）で反映する。
- 言語を送らない古いアプリの送り先は、日本語にする。

### 6.6 OS に出す文言

- iOS の権限の説明（`Info.plist` の `NS…UsageDescription`）は、`app/ios/Runner/ja.lproj/InfoPlist.strings`・`en.lproj/InfoPlist.strings` に書く。`Info.plist` の値は、日本語のまま置く（どちらの言語のファイルもないときに出る）。権限の説明を足すときは、この3か所に書く。`Info.plist` の `CFBundleLocalizations` に、`ja`・`en` を入れる。
- Android の通知のチャンネルの名前と説明は、`app/android/app/src/main/res/values/strings.xml`（英語）・`values-ja/strings.xml`（日本語）に書く。端末の言語で出る（アプリの表示言語には従わない）。

---

## 7. 日付・時刻・数の表記

- 日付・時刻・数は、`app/lib/utils/formatters.dart` の関数で整形する。表示言語は、View が `AppLocalizations` を渡す。
- 日本語は、日本で一般的な書式（`10/12(日)`・`2026年10月`・`4.5万` など）を関数の中で指定し、英語は `intl` の表示言語の書式を使う。
- 数の縮め方（万・億、K・M）は、機能仕様書 4.2.5 に従う。

次の関数は、表示言語を受け取らず、どの言語でも同じ表記にする。

| 関数 | 表記 | 理由 |
| --- | --- | --- |
| `clockTime`・`clockOfDay` | 24時間表記（`21:00`） | タイムスケジュールの目盛りとそろえるため |
| `monthDay` | `10/16` | 日本語・英語のどちらでも読めるため |
| `elapsed` | 配信の経過時間（`1:05:09`、`05:09`） | 映像に重ねる時計の表記のため |
| `withCommas` | 3桁区切り（`1,234`） | 日本語・英語で区切りが同じため |

---

## 8. テスト

- テストのアプリ（`app/test/fakes/test_app.dart` の `testApp`）は、端末の言語に左右されないように、`locale` を日本語に決めて作る。既存のテストは、日本語の文言で探す。
- `testApp(..., locale: const Locale('en'))` で、英語の画面を確かめる。`locale: null` にすると、設定で選んだ言語（`appLanguageProvider`）に従う。
- 書式の単体テストは、`lookupAppLocalizations(const Locale('ja'))` で文言を引く。
