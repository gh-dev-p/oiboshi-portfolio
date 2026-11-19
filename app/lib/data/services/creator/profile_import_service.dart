import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/edge_functions.dart';
import '../common/supabase_names.dart';

/// SNS からのプロフィールの取り込み（Edge Function `fetch-profile`）と、アイコンの画像の取得。
class ProfileImportService {
  ProfileImportService(this._client);

  final SupabaseClient _client;

  /// 確認済みのアカウントの、公開のプロフィール（`name`・`bio`・`avatarUrl`）。
  /// [creatorId] が null なら、発信者として登録の手順の、登録待ちの連携から取る。
  Future<Map<String, dynamic>> fetch(String? creatorId, String service) =>
      _client.functions.invokeData(
        EdgeFunctions.fetchProfile,
        body: {'creatorId': creatorId, 'service': service},
      );

  /// 画像を取りに行く。
  Future<Uint8List> download(String url) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}', uri: Uri.parse(url));
      }
      final builder = BytesBuilder(copy: false);
      await res.forEach(builder.add);
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }
}
