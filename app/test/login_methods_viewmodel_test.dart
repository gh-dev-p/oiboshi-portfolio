import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/settings/view_models/login_methods_viewmodel.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  late FakeData data;
  late ProviderContainer container;

  setUp(() async {
    data = FakeData()..loginMethods.add(googleLogin);
    container = await testContainer(data);
    container.listen(loginMethodsViewModelProvider, (_, _) {});
  });

  LoginMethodsViewModel vm() =>
      container.read(loginMethodsViewModelProvider.notifier);

  test('外せたら true を返し、一覧を読み直す', () async {
    await container.read(loginMethodsViewModelProvider.future);
    expect(await vm().unlink(googleLogin), isTrue);
    expect(await container.read(loginMethodsViewModelProvider.future), isEmpty);
  });

  test('一覧に無い方法は、外したことにせず false を返し、一覧を読み直す', () async {
    await container.read(loginMethodsViewModelProvider.future);
    // ほかの端末で外した。
    data.loginMethods.clear();
    expect(container.read(loginMethodsViewModelProvider).value, isNotEmpty);
    expect(await vm().unlink(googleLogin), isFalse);
    expect(await container.read(loginMethodsViewModelProvider.future), isEmpty);
  });
}
