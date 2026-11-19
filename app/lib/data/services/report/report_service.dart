import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/edge_functions.dart';
import '../common/supabase_names.dart';

/// 通報の送信（Edge Function `submit-report`）。アプリからは、通報を読めない。
class ReportService {
  ReportService(this._client);

  final SupabaseClient _client;

  /// 通報を送る。結果の文字列（`submitted`・`duplicate`・`not_found`）を返す。
  Future<String?> submit({
    String? creatorId,
    String? scheduleId,
    String? linkId,
    required String reason,
    required String detail,
  }) => _client.functions.invokeResult<String?>(
    EdgeFunctions.submitReport,
    body: {
      'creatorId': ?creatorId,
      'scheduleId': ?scheduleId,
      'linkId': ?linkId,
      'reason': reason,
      'detail': detail,
    },
  );
}
