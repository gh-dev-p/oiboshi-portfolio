import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/login_method.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/guard.dart';
import '../../core/view_models/refresh.dart';
import 'settings_providers.dart';

/// ログイン方法の画面（画面定義書 2.1.5）。状態は、結び付いたログイン方法（[loginMethodsProvider]）。
class LoginMethodsViewModel extends AsyncNotifier<List<LoginMethod>> {
  @override
  Future<List<LoginMethod>> build() => ref.watch(loginMethodsProvider.future);

  /// いまのユーザーに、ログインを結び付ける。
  Future<LoginResult> link(LoginProvider provider) => linkLogin(ref, provider);

  /// ログイン方法を外す。失敗したら false。
  /// 失敗しても一覧を読み直す（一覧に無い方法を外そうとしたときは、ほかの端末で変わっているため。機能仕様書 4.1.4）。
  Future<bool> unlink(LoginMethod method) async {
    final ok = await succeeded(
      () => ref.read(authRepositoryProvider).unlinkLogin(method),
    );
    ref.invalidate(loginMethodsProvider);
    return ok;
  }

  /// 読めなかったときに、読み直す。
  void retry() => reloadFrom(ref, [authSessionProvider, loginMethodsProvider]);
}

final loginMethodsViewModelProvider =
    AsyncNotifierProvider.autoDispose<LoginMethodsViewModel, List<LoginMethod>>(
      LoginMethodsViewModel.new,
    );
