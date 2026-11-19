import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:supabase_flutter/supabase_flutter.dart';

/// [bucket] の [path] に画像を上書きでアップロードし、公開の URL を返す。
/// 同じパスに上書きするので、URL に時刻を付けて画像のキャッシュを避ける。
/// 画像の種類は、中身から決める（[imageContentType]）。
/// バケットは GIF を受け付けないので、GIF は1枚目の PNG にして上げる。
Future<String> uploadImage(
  StorageFileApi bucket,
  String path,
  Uint8List image,
) async {
  final bytes = imageContentType(image) == 'image/gif'
      ? await _firstFramePng(image)
      : image;
  await bucket.uploadBinary(
    path,
    bytes,
    fileOptions: FileOptions(
      contentType: imageContentType(bytes),
      upsert: true,
    ),
  );
  return '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
}

/// 画像の1枚目を PNG にする。
Future<Uint8List> _firstFramePng(Uint8List image) async {
  final codec = await ui.instantiateImageCodec(image);
  try {
    final frame = await codec.getNextFrame();
    try {
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return png!.buffer.asUint8List();
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

/// 画像の先頭のバイトから、種類を決める。わからなければ JPEG。
String imageContentType(Uint8List bytes) {
  bool startsWith(List<int> sig, [int offset = 0]) =>
      bytes.length >= offset + sig.length &&
      [for (var i = 0; i < sig.length; i++) bytes[offset + i]].join(',') ==
          sig.join(',');
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (startsWith(const [0x47, 0x49, 0x46])) return 'image/gif';
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
      startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return 'image/jpeg';
}
