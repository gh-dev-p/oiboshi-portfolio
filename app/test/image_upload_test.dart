import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/data/services/common/image_upload.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 上げられたバイト列と種類を覚えておくバケットの代わり。
class _RecordingBucket extends Fake implements StorageFileApi {
  Uint8List? data;
  String? contentType;

  @override
  Future<String> uploadBinary(
    String path,
    Uint8List data, {
    FileOptions fileOptions = const FileOptions(),
    int? retryAttempts,
    StorageRetryController? retryController,
  }) async {
    this.data = data;
    contentType = fileOptions.contentType;
    return path;
  }

  @override
  String getPublicUrl(
    String path, {
    String? cacheNonce,
    DownloadBehavior? download,
    TransformOptions? transform,
  }) => 'https://example.test/$path';
}

void main() {
  // 1×1 の赤い GIF。
  final gif = Uint8List.fromList([
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, //
    0x00, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x21, 0xF9, 0x04, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
    0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B,
  ]);

  test('GIF は、バケットが受け付ける PNG にして上げる', () async {
    final bucket = _RecordingBucket();

    await uploadImage(bucket, 'id/avatar.jpg', gif);

    expect(bucket.contentType, 'image/png');
    expect(imageContentType(bucket.data!), 'image/png');
    final codec = await ui.instantiateImageCodec(bucket.data!);
    final frame = await codec.getNextFrame();
    expect((frame.image.width, frame.image.height), (1, 1));
  });

  test('JPEG はそのまま上げる', () async {
    final bucket = _RecordingBucket();
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF]);

    final url = await uploadImage(bucket, 'id/avatar.jpg', jpeg);

    expect(bucket.data, same(jpeg));
    expect(bucket.contentType, 'image/jpeg');
    expect(url, startsWith('https://example.test/id/avatar.jpg?v='));
  });
}
