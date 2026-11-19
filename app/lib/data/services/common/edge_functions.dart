import 'package:supabase_flutter/supabase_flutter.dart';

/// Edge Functions の呼び出しで、返った JSON を読む。
extension EdgeFunctionCalls on FunctionsClient {
  /// [name] を呼び、返った JSON のオブジェクトを返す。オブジェクトでなければ、型の例外を投げる。
  Future<Map<String, dynamic>> invokeData(String name, {Object? body}) async =>
      (await invoke(name, body: body)).data as Map<String, dynamic>;

  /// [name] を呼び、返った JSON の [key]（ふつうは `result`）を返す。
  Future<T> invokeResult<T>(
    String name, {
    Object? body,
    String key = 'result',
  }) async => (await invokeData(name, body: body))[key] as T;
}
