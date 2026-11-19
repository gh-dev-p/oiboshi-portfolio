import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/image_upload.dart';
import '../common/supabase_names.dart';

/// ファンのカバー画像の Storage への入出力。
class CoverStorageService {
  CoverStorageService(this._client);

  final SupabaseClient _client;

  StorageFileApi get _bucket => _client.storage.from(Buckets.covers);

  /// 端末は、ふつう JPEG にして返すが、Android は透過のある画像を PNG のまま返すので、中身から種類を決める（[uploadImage]）。
  Future<String> upload(String userId, String creatorId, Uint8List image) =>
      uploadImage(_bucket, Buckets.coverPath(userId, creatorId), image);

  /// 画像を消す。なければ何もしない。
  Future<void> remove(String userId, String creatorId) =>
      _bucket.remove([Buckets.coverPath(userId, creatorId)]);
}
