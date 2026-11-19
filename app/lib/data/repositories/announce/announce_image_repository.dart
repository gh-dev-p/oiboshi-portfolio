import 'dart:typed_data';

import '../../../domain/models/announce_template.dart';
import '../../services/share/announce_image_service.dart';
import '../common/error_mapping.dart';

/// 週間の告知画像（届ける・広める仕様書 4.4.1）。画像はサーバーが作り、アプリは取ってきて出すだけ。
class AnnounceImageRepository {
  AnnounceImageRepository(this._service);

  final AnnounceImageService _service;

  /// テンプレの一覧（出すものだけ、並び順）。
  Future<List<AnnounceTemplate>> fetchTemplates(String lang) => mapErrors(
    () async => (await _service.fetchTemplates(
      lang,
    )).map(AnnounceTemplate.fromJson).toList(),
  );

  /// その週の告知画像（PNG）。
  Future<Uint8List> render({
    required String creatorId,
    required DateTime weekStart,
    required String templateId,
    required String lang,
  }) => mapErrors(
    () => _service.render(
      creatorId: creatorId,
      weekStart: weekStart,
      templateId: templateId,
      lang: lang,
    ),
  );

  /// 選んだ画像の URL。選んでいなければ null。
  Future<String?> fetchPhoto(String creatorId) =>
      mapErrors(() => _service.fetchPhoto(creatorId));

  /// [image] を選んだ画像にする。
  Future<String> uploadPhoto(String creatorId, Uint8List image) =>
      mapErrors(() => _service.uploadPhoto(creatorId, image));

  /// 選んだ画像を外す（アイコンに戻す）。
  Future<void> deletePhoto(String creatorId) =>
      mapErrors(() => _service.deletePhoto(creatorId));
}
