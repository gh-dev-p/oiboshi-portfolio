# 追星（oiboshi）

推しの発信者の更新（配信・投稿・予定）を、1つのアプリで追うための iOS・Android アプリです。複数の SNS に散らばった更新を、ファンが1か所で追えるようにします。発信者は、自分の SNS のアカウントを連携し、イベントの予定を登録します。

## このコピーについて

- 作品の紹介のために公開している、閲覧用のコピーです。開発しているリポジトリから、クライアント（Flutter）と仕様・設計の文書だけを取り出しています。履歴は持ち込んでいません。
- 含まないもの：サーバ側の実装（Supabase のテーブル・RLS・Edge Functions、Cloudflare Workers）、公開用のウェブサイト、ストアの掲載情報、開発と運用の文書（環境構成、検証の記録、決定事項の記録、データ設計書、リリースの手続き）。
- 接続設定（`app/dart_defines*.example.json`）は、値を空にしています。そのため、実機やシミュレーターでは動きません。
- Firebase・Supabase・RevenueCat の接続先と、署名（Team ID・鍵）は入れていません。バンドル ID とパッケージ名は、見本の値（`com.example.oiboshi`）にしています。
- テストのデータに出てくる発信者・アカウント・イベントは、架空のものです。

## 主な機能

ファン向け：

- 発信者のフォロー、検索、新着の表示、発信者を表示しない設定
- YouTube・Instagram・X の投稿の表示（タイムラインと全画面のビューア）
- ツイキャス・Twitch・YouTube の配信中の表示と、アプリ内の再生、配信開始の通知
- 配信か推しの動画を画面の上に据え付けて流し続ける固定ビューア
- 配信の予定とイベントを見るタイムスケジュールと、月のカレンダー、予定の事前通知
- まだいない発信者の SNS アカウントを申告して「追いたい」を押す（登録されたら知らせて、自動でフォロー）
- 発信者・イベント・リンクの通報
- 匿名での利用と、Apple・Google・X・Twitch のログイン、退会

発信者向け：

- 発信者の登録と、SNS のアカウント連携（本人であることの確認）
- イベントの登録（チケットサイトのページから読み取る候補を含む）
- プロフィールの編集、表示するコンテンツの選択、自分の投稿を隠す
- リンク集（好きなリンクの登録・並べ替え、行き先の公式アイコン、押された数）
- 発信者ページの共有のリンクと QR、追星に誘うリンク
- 1週間の予定から作る告知の画像
- 通知が届いた数・予定や投稿が見られた数などの表示
- プランの確認と加入（X の連携だけ有料のサブスク）

共通：

- ライト・ダークの画面モード
- 日本語・英語の切り替え

機能の一覧は、[機能仕様書](docs/design/specs/functional-spec.md) と [機能仕様書（届ける・広める）](docs/design/specs/functional-spec-reach.md) の3章にあります。

## 技術スタック

| 分類 | 内容 |
| --- | --- |
| クライアント | Flutter（Dart）、対象は iOS・Android |
| 状態管理 | flutter_riverpod |
| バックエンドのクライアント | supabase_flutter |
| 通知 | firebase_core、firebase_messaging |
| 課金 | purchases_flutter（RevenueCat） |
| 再生・表示 | video_player、webview_flutter |
| ログイン | flutter_web_auth_2、sign_in_with_apple |
| 多言語化 | flutter_localizations、intl（gen-l10n） |

依存の全体は [app/pubspec.yaml](app/pubspec.yaml) にあります。

## ディレクトリ構成

```
app/
  lib/
    ui/        画面と ViewModel。機能ごとのフォルダーに分ける（共通は core/）
    domain/    ドメインモデル
    data/      Repository と Service
    config/    Provider、定数、接続設定の読み込み、Flavor
    utils/     層や機能に属さない処理
    l10n/      表示文言（日本語・英語）
    app.dart、bootstrap.dart、main_dev.dart、main_prod.dart
  test/        単体テストとウィジェットテスト
  tool/        キャラクターの画像の切り抜き
  android/、ios/
  dart_defines*.example.json   接続設定の見本（値は空）
docs/          仕様書・設計書
scripts/       文書の目次を作り直す道具
```

## アーキテクチャの要点

- Flutter 公式のアーキテクチャガイドに沿った MVVM です。状態管理は Riverpod で統一しています。
- 依存の向きは、View → ViewModel → Model の一方向だけです。View は `data/` を直接 import しません。
- Repository と Service は、`lib/config/service_providers.dart` で Provider として公開します。
- ViewModel と Model は `BuildContext` に依存しません。表示文言を持たず、エラーは種別で返し、View が文言に変えます。
- UseCase の層は置きません。複数の Repository を組み合わせる処理は、ViewModel が行います。
- アプリは SNS を直接呼ばず、サーバーが取って保存したデータだけを読みます。SNS のキーとトークンは、サーバーだけが持ちます。
- dev と prod の2つの Flavor を持ち、エントリポイント（`main_dev.dart`・`main_prod.dart`）で分けます。

詳しくは [アーキテクチャ設計書](docs/design/architecture/architecture-design.md) にあります。

## 文書

文書の入口は [docs/README.md](docs/README.md) です。要件定義書、機能仕様書、画面定義書、アーキテクチャ設計書、i18n設計書、用語集があります。

## 確認の手順

`app/` で実行します。

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

## ライセンス

[LICENSE](LICENSE) を参照してください。
