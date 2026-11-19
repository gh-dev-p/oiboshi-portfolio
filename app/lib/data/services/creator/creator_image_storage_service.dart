import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/image_upload.dart';
import '../common/supabase_names.dart';

/// 発信者のアイコン・カバーの Storage への入出力。
class CreatorImageStorageService {
  CreatorImageStorageService(this._client);

  final SupabaseClient _client;

  /// SNS から取り込んだアイコンは PNG・WebP のこともあるので、中身から種類を決める（[uploadImage]）。
  Future<String> upload(String creatorId, String name, Uint8List image) =>
      uploadImage(
        _client.storage.from(Buckets.creatorImages),
        Buckets.creatorImagePath(creatorId, name),
        image,
      );
}
