import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/image_upload.dart';
import '../common/supabase_names.dart';

/// 週間の告知画像（届ける・広める仕様書 4.4.1）。画像はサーバー（Edge Functions の `announce-image`）が作る。
/// 発信者が選んだ画像は、発信者の画像の置き場（`creator-images` の `{発信者 ID}/announce.jpg`）と、
/// 表 `creator_announce_images`（データ設計書 3.1.37）に持つ。
class AnnounceImageService {
  AnnounceImageService(this._client);

  final SupabaseClient _client;

  static const _photoName = 'announce';

  /// テンプレの一覧（出すものだけ、並び順）。
  Future<List<Map<String, dynamic>>> fetchTemplates(String lang) async {
    final response = await _client.functions.invoke(
      EdgeFunctions.announceImageTemplates,
      method: HttpMethod.get,
      queryParameters: {'lang': lang},
    );
    return ((response.data as Map<String, dynamic>)['templates'] as List)
        .cast<Map<String, dynamic>>();
  }

  /// [creatorId] の [weekStart]（月曜）の週の告知画像（PNG）を、[templateId] で作る。
  Future<Uint8List> render({
    required String creatorId,
    required DateTime weekStart,
    required String templateId,
    required String lang,
  }) async {
    final date =
        '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-'
        '${weekStart.day.toString().padLeft(2, '0')}';
    final response = await _client.functions.invoke(
      EdgeFunctions.announceImage,
      body: {
        'creatorId': creatorId,
        'weekStart': date,
        'utcOffsetMinutes': weekStart.timeZoneOffset.inMinutes,
        'templateId': templateId,
        'lang': lang,
      },
    );
    return response.data as Uint8List;
  }

  /// 選んだ画像の URL。選んでいなければ null。
  Future<String?> fetchPhoto(String creatorId) async {
    final row = await _client
        .from(Tables.creatorAnnounceImages)
        .select('image_url')
        .eq('creator_id', creatorId)
        .maybeSingle();
    return row?['image_url'] as String?;
  }

  /// [image] を上げて、選んだ画像にする。上げた画像の URL を返す。
  Future<String> uploadPhoto(String creatorId, Uint8List image) async {
    final url = await uploadImage(
      _client.storage.from(Buckets.creatorImages),
      Buckets.creatorImagePath(creatorId, _photoName),
      image,
    );
    await _client.from(Tables.creatorAnnounceImages).upsert({
      'creator_id': creatorId,
      'image_url': url,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return url;
  }

  /// 選んだ画像を外す（アイコンに戻す）。画像も消す。
  Future<void> deletePhoto(String creatorId) async {
    await _client
        .from(Tables.creatorAnnounceImages)
        .delete()
        .eq('creator_id', creatorId);
    await _client.storage.from(Buckets.creatorImages).remove([
      Buckets.creatorImagePath(creatorId, _photoName),
    ]);
  }
}
