import 'dart:convert';
import 'dart:typed_data';

import 'package:oiboshi/data/repositories/announce/announce_image_repository.dart';
import 'package:oiboshi/domain/models/announce_template.dart';

import 'fake_data.dart';

/// 週間の告知画像の代わり。サーバーが作る画像は、1×1 の PNG を返す。
/// テンプレの一覧は [FakeData.announceTemplates]、選んだ画像は [FakeData.announcePhotos]、作った条件は [FakeData.announceRenders]。
class FakeAnnounceImageRepository implements AnnounceImageRepository {
  FakeAnnounceImageRepository(this.data);

  final FakeData data;

  /// 1×1 の透明な PNG。
  static final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  Future<List<AnnounceTemplate>> fetchTemplates(String lang) async {
    if (data.announceTemplatesFail) throw Exception('通信の失敗');
    return data.announceTemplates;
  }

  @override
  Future<Uint8List> render({
    required String creatorId,
    required DateTime weekStart,
    required String templateId,
    required String lang,
  }) async {
    data.announceRenders.add((
      creatorId: creatorId,
      weekStart: weekStart,
      templateId: templateId,
      photo: data.announcePhotos[creatorId],
    ));
    await data.announceRenderGate?.future;
    if (data.announceRenderFail) throw Exception('サーバーの失敗');
    return png;
  }

  @override
  Future<String?> fetchPhoto(String creatorId) async =>
      data.announcePhotos[creatorId];

  @override
  Future<String> uploadPhoto(String creatorId, Uint8List image) async {
    if (data.announcePhotoFail) throw Exception('上げられない');
    final url =
        'https://storage.example/$creatorId/announce.jpg?v=${image.length}';
    data.announcePhotos[creatorId] = url;
    return url;
  }

  @override
  Future<void> deletePhoto(String creatorId) async =>
      data.announcePhotos.remove(creatorId);
}
