import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/themes/app_theme.dart';
import 'package:oiboshi/ui/core/ui/sns_style.dart';

/// 他社のサービスのアイコンは、各社の公式の素材を出す（tech-risks.md 2.21）。
void main() {
  String? assetOf(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image));
    return (image.image as AssetImage).assetName;
  }

  Future<void> pump(WidgetTester tester, SnsService service, ThemeData theme) =>
      tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Center(child: PlatformIcon(service, size: 24)),
        ),
      );

  testWidgets('YouTube・Instagram・Twitch は、公式の素材を出す', (tester) async {
    for (final (service, file) in [
      (SnsService.youtube, 'youtube.png'),
      (SnsService.instagram, 'instagram.png'),
      (SnsService.twitch, 'twitch.png'),
    ]) {
      await pump(tester, service, AppTheme.light);
      expect(assetOf(tester), 'assets/brands/$file');
    }
  });

  testWidgets('X は、明るい画面では黒、暗い画面では白の公式のロゴを出す', (tester) async {
    await pump(tester, SnsService.x, AppTheme.light);
    expect(assetOf(tester), 'assets/brands/x_black.png');
    await pump(tester, SnsService.x, AppTheme.dark);
    // テーマの切り替えのアニメーションを終える。
    await tester.pumpAndSettle();
    expect(assetOf(tester), 'assets/brands/x_white.png');
  });

  testWidgets('アイコンは、指定した大きさの枠に収める', (tester) async {
    await pump(tester, SnsService.youtube, AppTheme.light);
    expect(tester.getSize(find.byType(PlatformIcon)), const Size(24, 24));
  });
}
