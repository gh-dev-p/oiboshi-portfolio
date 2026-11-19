import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';

import '../fakes.dart';
import '../helpers/widget_helpers.dart';

export '../helpers/widget_helpers.dart';

/// 画面のテストで共有するデータ。[setUpScreenTests] で、テストごとに作り直す。
late FakeData data;

/// 各テストの前に、発信者1人と投稿1件の入ったデータを用意する。
void setUpScreenTests() {
  setUp(() {
    data = FakeData()
      ..creators.add(sampleCreator())
      ..posts.add(samplePost());
  });
}

/// オンボーディングを済ませた状態で、ホームを出す。
Future<void> pumpHome(WidgetTester tester) async {
  data.onboardingDone = true;
  await pumpScreen(tester, data, const HomeShell());
}
