import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

/// OS の共有シートを開く（届ける・広める仕様書 4.3.2・4.3.5）。
class ShareSheetService {
  const ShareSheetService();

  /// [text] を共有シートに渡す。iPad では [origin]（押した部品の位置）の近くに出す。
  Future<void> shareText(String text, {required Rect? origin}) => SharePlus
      .instance
      .share(ShareParams(text: text, sharePositionOrigin: origin));

  /// PNG の画像を共有シートに渡す。共有シートの「画像を保存」で、写真に保存できる。
  /// [text] を渡すと、画像と一緒に文も渡す（X などは投稿の文に入る。週間の告知画像）。
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    required Rect? origin,
    String? text,
  }) => SharePlus.instance.share(
    ShareParams(
      text: text,
      files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
      fileNameOverrides: [fileName],
      sharePositionOrigin: origin,
    ),
  );
}
