# スプラッシュの絵（LaunchImage）

iOS の起動の画面（`Runner/Base.lproj/LaunchScreen.storyboard`）の真ん中に出す絵。画面定義書（ファン向け）2.1.5。

- 元の絵：`app/assets/logo/home_logo.png`（明るい画面）・`home_logo_dark.png`（暗い画面）。ホームのヘッダーのロゴと同じ。背景は透明にしておく。
- 大きさ：340×60pt。@1x・@2x・@3x を、元の絵から縮めて作る。
- 背景の色：`Assets.xcassets/LaunchBackground.colorset`（明るい画面と暗い画面の2色）。

## 作り直す手順

`app/` で、次を実行する（絵の縦横の比が変わるときは、60 と storyboard の `<image name="LaunchImage" width=… height=…>` も合わせる）。

```bash
D=ios/Runner/Assets.xcassets/LaunchImage.imageset; for s in 1 2 3; do suf=""; [ $s -gt 1 ] && suf="@${s}x"; sips -z $((60*s)) $((340*s)) assets/logo/home_logo.png --out $D/LaunchImage$suf.png; sips -z $((60*s)) $((340*s)) assets/logo/home_logo_dark.png --out $D/LaunchImageDark$suf.png; done
```

端末やシミュレーターは起動の画面を覚えているので、確かめるときはアプリを消してから入れ直す。
