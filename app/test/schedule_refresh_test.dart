import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/service_providers.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/view_models/clock_provider.dart';
import 'package:oiboshi/ui/schedule/view_models/schedule_providers.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  testWidgets('読み直しは1分に1回で、読む範囲は変わらない', (tester) async {
    final container = await testContainer(FakeData());
    final repository =
        container.read(scheduleRepositoryProvider) as FakeScheduleRepository;
    final sub = container.listen(nextScheduleProvider('minato'), (_, _) {});
    await tester.pump();
    await tester.pump();
    expect(repository.fetchedFrom, hasLength(1));

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(minutes: 1));
      await tester.pump();
    }
    expect(repository.fetchedFrom, hasLength(4));
    expect(repository.fetchedFrom.toSet(), hasLength(1));

    sub.close();
    container.dispose();
  });

  test('次の予定は、もう始まった予定を選ばない', () async {
    final now = DateTime(2026, 11, 3, 12);
    final data = FakeData()
      ..schedules.addAll([
        sampleSchedule(
          's1',
          '始まった',
          now.subtract(const Duration(hours: 1)),
          service: SnsService.youtube,
        ),
        sampleSchedule(
          's2',
          'これから',
          now.add(const Duration(hours: 1)),
          service: SnsService.youtube,
        ),
      ]);
    final container = await testContainer(
      data,
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    final next = await container.read(nextScheduleProvider('minato').future);
    expect(next?.id, 's2');
  });
}
