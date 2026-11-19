# ドキュメント一覧

**追星（oiboshi）**

- 対象プロジェクト：追星（oiboshi）
- 本書の位置付け：このコピーに入れた `docs/` のドキュメントの索引

このコピーには、アプリの仕様と設計の文書だけを入れています。開発の運用、検証の記録、決定事項の記録、データ設計書、リリースの手続きの文書は入れていません。本文の中で、入れていない文書を指すところは、リンクを外して名前だけを残しています（「決定事項 1」「技術検証 2.16」「環境構成 10」など）。

---

## 1. 企画

| ドキュメント | 格納先 | 内容 |
| --- | --- | --- |
| コアバリュー | [concept/core-value.md](concept/core-value.md) | コアバリュー |
| リファレンス | [concept/reference.md](concept/reference.md) | 参考アプリの整理、UI方針 |
| 要件定義書 | [requirements/requirements.md](requirements/requirements.md) | 目的、スコープ、非機能要件 |

## 2. 仕様書・設計書

| ドキュメント | 格納先 | 内容 |
| --- | --- | --- |
| 機能仕様書 | [design/specs/functional-spec.md](design/specs/functional-spec.md) | 機能 |
| 機能仕様書（届ける・広める） | [design/specs/functional-spec-reach.md](design/specs/functional-spec-reach.md) | 予定の事前通知、発信者に見せる数、リンクの共有、告知の画像、追いたい |
| 画面定義書 | [design/screens/screen-design.md](design/screens/screen-design.md) | 画面一覧、共通ルール。画面の詳細は、次の3つに分ける |
| 画面定義書（ファン向け） | [design/screens/screen-design-fan.md](design/screens/screen-design-fan.md) | 初回起動、ホーム、推し、発信者ページ、投稿ビューア |
| 画面定義書（スケジュール） | [design/screens/screen-design-schedule.md](design/screens/screen-design-schedule.md) | タイムスケジュールと周りの画面、月のカレンダー |
| 画面定義書（設定・発信者向け） | [design/screens/screen-design-settings.md](design/screens/screen-design-settings.md) | 設定、発信者の登録と設定 |
| アーキテクチャ設計書 | [design/architecture/architecture-design.md](design/architecture/architecture-design.md) | アーキテクチャ（MVVM + Riverpod）、フォルダ構成、規約、接続先の切り替え |
| i18n設計書 | [design/architecture/i18n-design.md](design/architecture/i18n-design.md) | 表示言語（日本語・英語）の切り替え、文言の管理（gen-l10n） |

## 3. 用語

| ドキュメント | 格納先 | 内容 |
| --- | --- | --- |
| 用語集 | [decisions/glossary.md](decisions/glossary.md) | 用語の表記 |
