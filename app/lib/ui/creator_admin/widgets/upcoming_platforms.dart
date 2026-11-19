import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// まだ対応していないプラットフォーム。アカウント連携と表示する内容の画面に、「準備中」で並べる（画面定義書 2.3.2・2.3.3）。
enum UpcomingPlatform {
  tiktok(Icons.music_note),
  niconico(Icons.live_tv);

  const UpcomingPlatform(this.glyph);

  final IconData glyph;

  String label(AppLocalizations l10n) => switch (this) {
    UpcomingPlatform.tiktok => 'TikTok',
    UpcomingPlatform.niconico => l10n.creatorAdminUpcomingNiconico,
  };

  /// 表示する内容の画面に出す、選べるようになる内容。
  String contents(AppLocalizations l10n) => switch (this) {
    UpcomingPlatform.tiktok => l10n.creatorAdminUpcomingTiktokContents,
    UpcomingPlatform.niconico => l10n.creatorAdminUpcomingNiconicoContents,
  };
}

/// まだ対応していないプラットフォームのアイコン。白黒の角丸の四角に、記号を置く。
class UpcomingPlatformIcon extends StatelessWidget {
  const UpcomingPlatformIcon(this.platform, {super.key, required this.size});

  final UpcomingPlatform platform;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        platform.glyph,
        size: size * 0.6,
        color: dark ? Colors.black : Colors.white,
      ),
    );
  }
}
