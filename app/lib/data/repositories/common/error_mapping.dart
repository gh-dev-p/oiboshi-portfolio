import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/app_error.dart';

/// PostgREST・Postgres のエラーコード。
abstract final class PgCodes {
  /// 一意の制約に反した（同じ行がすでにある）。
  static const uniqueViolation = '23505';

  /// 1行を求めたが、行がなかった。
  static const noRows = 'PGRST116';
}

/// Supabase の例外を、エラー種別に変える。
Future<T> mapErrors<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } on AuthException catch (e) {
    throw AppException(AppErrorKind.auth, e);
  } on PostgrestException catch (e) {
    throw AppException(
      e.code == PgCodes.noRows ? AppErrorKind.notFound : AppErrorKind.unknown,
      e,
    );
  } on StorageException catch (e) {
    throw AppException(AppErrorKind.unknown, e);
  } on FunctionsFetchException catch (e) {
    // 関数に届かなかった。FunctionException の一種なので、先に受ける。
    throw AppException(AppErrorKind.network, e);
  } on FunctionException catch (e) {
    // 関数が失敗を返した。
    throw AppException(AppErrorKind.unknown, e);
  } on SocketException catch (e) {
    throw AppException(AppErrorKind.network, e);
  } catch (e) {
    throw AppException(AppErrorKind.network, e);
  }
}
