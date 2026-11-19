import 'package:flutter/material.dart';

import '../../../config/app_flavor.dart';

/// ストアのスクリーンショット用に、dev の帯を消す（ビルドのときの指定。ふだんは false）。
const _hideForScreenshots = bool.fromEnvironment('HIDE_DEV_BANNER');

/// dev のアプリのとき、画面の右上に「DEV」の斜めの帯を出し続ける（環境構成 10）。
/// 本番のアプリと見分けるため。prod では何も足さない。
/// ストアのスクリーンショットを dev で撮るときだけ、`--dart-define=HIDE_DEV_BANNER=true` で消せる。
class DevEnvBanner extends StatelessWidget {
  const DevEnvBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppFlavor.current != AppFlavor.dev || _hideForScreenshots) return child;
    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      textDirection: TextDirection.ltr,
      layoutDirection: TextDirection.ltr,
      color: Colors.red,
      child: child,
    );
  }
}
