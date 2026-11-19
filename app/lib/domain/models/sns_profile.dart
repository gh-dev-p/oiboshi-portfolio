import 'dart:typed_data';

import 'sns_service.dart';

/// SNS から取り込んだプロフィールの下書き（機能仕様書 4.6.4）。取れなかった項目は null。
class SnsProfileDraft {
  const SnsProfileDraft({
    required this.service,
    this.name,
    this.bio,
    this.avatar,
  });

  final SnsService service;
  final String? name;
  final String? bio;

  /// アイコンの画像（取れなければ null）。保存するときにアップロードする。
  final Uint8List? avatar;
}
