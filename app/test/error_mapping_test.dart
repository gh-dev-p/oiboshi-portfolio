import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/data/repositories/common/error_mapping.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Future<void> expectKind(Object error, AppErrorKind kind) => expectLater(
    mapErrors<void>(() => Future.error(error)),
    throwsA(isA<AppException>().having((e) => e.kind, 'kind', kind)),
  );

  test('関数が失敗を返したら unknown', () async {
    await expectKind(
      const FunctionsHttpException(status: 500),
      AppErrorKind.unknown,
    );
    await expectKind(
      const FunctionsRelayException(status: 502),
      AppErrorKind.unknown,
    );
  });

  test('関数に届かなかったら network', () async {
    await expectKind(
      const FunctionsFetchException(details: 'offline'),
      AppErrorKind.network,
    );
  });
}
