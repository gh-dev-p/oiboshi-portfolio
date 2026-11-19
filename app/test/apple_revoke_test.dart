import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/data/repositories/auth/auth_repository.dart';
import 'package:oiboshi/data/services/settings/app_preferences_store.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_service.dart';
import 'helpers/samples.dart';

void main() {
  late FakeAuthService auth;
  late AuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthService();
    repo = AuthRepository(
      auth,
      AppPreferencesStore(await SharedPreferences.getInstance()),
    );
  });

  test('Apple で再認証してから退会すると、ユーザーを消す前に、Apple のひも付けを取り消す', () async {
    expect(await repo.reauthenticate(appleLogin), LoginResult.done);
    await repo.withdraw();
    expect(auth.calls, ['revoke:apple-code', 'delete', 'signOut']);
  });

  test('取り消しに失敗しても、退会は進める', () async {
    auth.revokeFails = true;
    await repo.reauthenticate(appleLogin);
    await repo.withdraw();
    expect(auth.calls, ['revoke:apple-code', 'delete', 'signOut']);
  });

  test('コードは1回だけ使う。Apple 以外や、違うユーザーの再認証では、前のコードを捨てる', () async {
    await repo.reauthenticate(appleLogin);
    await repo.reauthenticate(googleLogin);
    await repo.withdraw();
    expect(auth.calls, ['delete', 'signOut']);

    auth
      ..calls.clear()
      ..session = FakeAuthService.sessionFor('user-a');
    await repo.reauthenticate(appleLogin);
    auth.reauthUserId = 'user-b';
    expect(await repo.reauthenticate(appleLogin), LoginResult.wrongAccount);
    await repo.withdraw();
    expect(auth.calls, ['delete', 'signOut']);
  });

  test('再認証のない退会（匿名のユーザー）では、取り消さない', () async {
    await repo.withdraw();
    expect(auth.calls, ['delete', 'signOut']);
  });
}
