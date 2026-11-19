import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oiboshi/app.dart';
import 'package:oiboshi/config/provider_retry.dart';
import 'package:oiboshi/data/repositories/notification/notification_repository.dart';
import 'package:oiboshi/data/services/notification/device_token_service.dart';
import 'package:oiboshi/data/services/notification/notification_permission_service.dart';
import 'package:oiboshi/data/services/notification/push_messaging_service.dart';
import 'package:oiboshi/data/services/settings/app_preferences_store.dart';
import 'package:oiboshi/domain/models/live_notification.dart';
import 'package:oiboshi/domain/models/notification_permission.dart';
import 'package:oiboshi/domain/models/user_settings.dart';
import 'package:oiboshi/ui/core/ui/app_sheet.dart';
import 'package:oiboshi/ui/core/view_models/app_language_provider.dart';
import 'package:oiboshi/ui/core/view_models/auth_session_provider.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/home/widgets/home_body.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';
import 'package:oiboshi/ui/onboarding/view_models/onboarding_providers.dart';
import 'package:oiboshi/ui/schedule/widgets/schedule_detail_sheet.dart';
import 'package:oiboshi/ui/settings/widgets/notification_settings_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';
import 'package:oiboshi/ui/notification/view_models/notification_providers.dart';
import 'package:oiboshi/ui/settings/view_models/settings_viewmodel.dart';

const _notice = LiveNotification(
  creatorId: 'minato',
  title: '星野ミナトが配信を始めました',
  body: '雑談',
);

const _scheduleNotice = LiveNotification(
  creatorId: 'minato',
  title: '星野ミナトの予定',
  body: '20:00からYouTubeで配信予定：雑談の予約',
  scheduleId: 's1',
);

void main() {
  group('配信開始の通知の中身', () {
    test('配信開始の通知なら、発信者 ID とタイトル・本文を読む', () {
      final n = LiveNotification.fromMessage(
        {'type': 'live_start', 'creator_id': 'minato'},
        title: 'タイトル',
        body: '本文',
      );
      expect(n?.creatorId, 'minato');
      expect(n?.title, 'タイトル');
      expect(n?.body, '本文');
    });

    test('予定の事前通知なら、予定の ID も読む', () {
      final n = LiveNotification.fromMessage({
        'type': 'schedule_notice',
        'creator_id': 'minato',
        'schedule_id': 's1',
      });
      expect(n?.creatorId, 'minato');
      expect(n?.scheduleId, 's1');
      final live = LiveNotification.fromMessage({
        'type': 'live_start',
        'creator_id': 'minato',
        'service': 'twitch',
        'live_id': '123',
      });
      expect(live?.service, 'twitch');
      expect(live?.liveId, '123');
      expect(
        LiveNotification.fromMessage({
          'type': 'schedule_notice',
          'creator_id': 'minato',
        }),
        isNull,
      );
      expect(
        LiveNotification.fromMessage({
          'type': 'live_start',
          'creator_id': 'minato',
        })?.scheduleId,
        isNull,
      );
    });

    test('追いたいの人の登録の通知も読む', () {
      final n = LiveNotification.fromMessage({
        'type': 'want_arrival',
        'creator_id': 'mio',
      });
      expect(n?.creatorId, 'mio');
      expect(n?.wantArrival, isTrue);
      expect(n?.scheduleId, isNull);
    });

    test('ほかの通知や、発信者 ID のない通知は、読まない', () {
      expect(LiveNotification.fromMessage({'creator_id': 'minato'}), isNull);
      expect(LiveNotification.fromMessage({'type': 'live_start'}), isNull);
      expect(
        LiveNotification.fromMessage({'type': 'live_start', 'creator_id': ''}),
        isNull,
      );
    });
  });

  group('通知の送り先の登録', () {
    late FakeData data;
    late FakeNotificationRepository notification;
    late ProviderContainer container;

    Future<void> setUpContainer() async {
      container = await testContainer(data, notification: notification);
      container.listen(pushRegistrationProvider, (_, _) {});
    }

    setUp(() {
      data = FakeData();
      notification = FakeNotificationRepository();
    });

    test('端末の通知が許可されていれば、送り先を登録する', () async {
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      expect(notification.registered, ['fid-1']);
    });

    test('許可されていなければ、登録しない', () async {
      notification.granted = false;
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      expect(notification.registered, isEmpty);
    });

    test('Firebase の接続の値がない端末では、登録しない', () async {
      notification.pushAvailable = false;
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      expect(notification.registered, isEmpty);
    });

    test('FCM が送り先を変えたら、登録し直す', () async {
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      notification.changeRegistration('fid-2');
      await Future<void>.delayed(Duration.zero);
      expect(notification.registered, ['fid-1', 'fid-2']);
    });

    test('ユーザーが変わったら、登録し直す', () async {
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      container.invalidate(authSessionProvider);
      await container.read(pushRegistrationProvider.future);
      expect(notification.registered, ['fid-1', 'fid-1']);
    });

    test('送り先と一緒に、アプリの表示言語を登録する', () async {
      data.appLanguage = AppLanguage.en;
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      expect(notification.registeredLanguages, ['en']);
    });

    test('表示言語を変えたら、新しい言語で登録し直す', () async {
      data.appLanguage = AppLanguage.ja;
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      await container.read(appLanguageProvider.notifier).set(AppLanguage.en);
      await Future<void>.delayed(Duration.zero);
      expect(notification.registered, ['fid-1', 'fid-1']);
      expect(notification.registeredLanguages, ['ja', 'en']);
    });

    test('FCM が送り先を変えたときも、いまの表示言語で登録する', () async {
      data.appLanguage = AppLanguage.en;
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      notification.changeRegistration('fid-2');
      await Future<void>.delayed(Duration.zero);
      expect(notification.registeredLanguages, ['en', 'en']);
    });

    test('ログアウトの前に、いまのユーザーから登録を消し、新しいユーザーで登録し直す', () async {
      await setUpContainer();
      await container.read(pushRegistrationProvider.future);
      final sub = container.listen(settingsViewModelProvider, (_, _) {});
      final ok = await container
          .read(settingsViewModelProvider.notifier)
          .signOut();
      sub.close();
      expect(ok, isTrue);
      expect(notification.unregisters, 1);
      await container.read(pushRegistrationProvider.future);
      expect(notification.registered, ['fid-1', 'fid-1']);
    });
  });

  group('NotificationRepository', () {
    late _FakePermissionService permission;
    late _FakeDeviceTokenService tokens;
    late AppPreferencesStore prefs;
    late NotificationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = AppPreferencesStore(await SharedPreferences.getInstance());
      permission = _FakePermissionService();
      tokens = _FakeDeviceTokenService();
      repo = NotificationRepository(
        permission,
        PushMessagingService(null),
        tokens,
        prefs,
      );
    });

    test('許可を求めたことを端末内に残し、許可の状態を分ける印にする', () async {
      expect(await repo.permissionState(), NotificationPermission.notRequested);
      expect(permission.lastRequestedBefore, isFalse);
      await repo.requestPermission();
      expect(prefs.notificationPermissionRequested, isTrue);
      expect(await repo.permissionState(), NotificationPermission.denied);
      expect(permission.lastRequestedBefore, isTrue);
    });

    test('言語を変えたら、この起動で登録した送り先を、新しい言語で登録し直す', () async {
      await repo.updateLanguage('en');
      expect(tokens.calls, isEmpty, reason: 'まだ登録していなければ、何もしない');
      await repo.saveRegistration('fid-1', 'ja');
      await repo.updateLanguage('en');
      expect(tokens.calls.map((c) => c.$1), ['fid-1', 'fid-1']);
      expect(tokens.calls.map((c) => c.$3), ['ja', 'en']);
    });
  });

  group('通知の文言の言語', () {
    test('日本語・English を選んでいれば、その言語', () {
      expect(AppLanguage.ja.notificationLanguage([const Locale('en')]), 'ja');
      expect(AppLanguage.en.notificationLanguage([const Locale('ja')]), 'en');
    });

    test('端末の設定に従うときは、端末の言語の優先順から選ぶ（どちらでもなければ英語）', () {
      expect(
        AppLanguage.system.notificationLanguage([
          const Locale('fr'),
          const Locale('ja', 'JP'),
        ]),
        'ja',
      );
      expect(
        AppLanguage.system.notificationLanguage([const Locale('en', 'US')]),
        'en',
      );
      expect(
        AppLanguage.system.notificationLanguage([const Locale('fr')]),
        'en',
      );
    });
  });

  group('通知設定の許可のカード', () {
    late FakeData data;
    late FakeNotificationRepository notification;

    setUp(() {
      data = FakeData()..onboardingDone = true;
      notification = FakeNotificationRepository();
    });

    Future<void> pumpSettings(WidgetTester tester) async {
      await pumpScreen(
        tester,
        data,
        const _RegisteringScreen(),
        notification: notification,
      );
    }

    testWidgets('許可を一度も求めていなければ、許可カードを出す', (tester) async {
      notification
        ..granted = false
        ..requestedBefore = false;
      await pumpSettings(tester);
      expect(find.text('通知を許可すると、推しの配信の開始と予定をお知らせします。'), findsOneWidget);
      expect(find.text('通知を許可する'), findsOneWidget);
      expect(find.text('端末の設定を開く'), findsNothing);
    });

    testWidgets('「通知を許可する」で許可されたら、カードを消し、送り先を登録する', (tester) async {
      notification
        ..granted = false
        ..requestedBefore = false
        ..grantOnRequest = true;
      await pumpSettings(tester);
      expect(notification.registered, isEmpty);
      await tester.tap(find.text('通知を許可する'));
      await tester.pumpAndSettle();
      expect(notification.requests, 1);
      expect(find.text('通知を許可する'), findsNothing);
      expect(find.text('端末の設定を開く'), findsNothing);
      expect(notification.registered, ['fid-1']);
    });

    testWidgets('「通知を許可する」で許可されなかったら、注意カードを出す', (tester) async {
      notification
        ..granted = false
        ..requestedBefore = false;
      await pumpSettings(tester);
      await tester.tap(find.text('通知を許可する'));
      await tester.pumpAndSettle();
      expect(find.text('通知を許可する'), findsNothing);
      expect(find.text('端末の設定を開く'), findsOneWidget);
      expect(notification.registered, isEmpty);
    });

    testWidgets('一度断ったあとは、注意カードだけを出す', (tester) async {
      notification.granted = false;
      await pumpSettings(tester);
      expect(find.text('端末の設定を開く'), findsOneWidget);
      expect(find.text('通知を許可する'), findsNothing);
    });

    testWidgets('許可されていれば、カードを出さない', (tester) async {
      await pumpSettings(tester);
      expect(find.text('端末の設定を開く'), findsNothing);
      expect(find.text('通知を許可する'), findsNothing);
    });

    testWidgets('英語でも、許可カードの文言を出す', (tester) async {
      notification
        ..granted = false
        ..requestedBefore = false;
      await pumpScreen(
        tester,
        data,
        const _RegisteringScreen(),
        notification: notification,
        locale: const Locale('en'),
      );
      expect(
        find.text(
          'Allow notifications to know when your favorites go live and before their schedules.',
        ),
        findsOneWidget,
      );
      expect(find.text('Allow notifications'), findsOneWidget);
    });
  });

  group('通知を受けたとき（ホーム）', () {
    late FakeData data;
    late FakeNotificationRepository notification;

    setUp(() {
      data = FakeData()
        ..creators.add(sampleCreator())
        ..posts.add(samplePost())
        ..onboardingDone = true;
      notification = FakeNotificationRepository();
    });

    Future<void> pumpHome(WidgetTester tester) async {
      await pumpScreen(
        tester,
        data,
        const HomeShell(),
        notification: notification,
      );
    }

    testWidgets('通知を押して開いたら、発信者ページを開く', (tester) async {
      await pumpHome(tester);
      expect(find.byType(CreatorScreen), findsNothing);
      notification.openNotification(_notice);
      await tester.pumpAndSettle();
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('アプリが終わっていたときに押して開いたら、起動のあとに発信者ページを開く', (tester) async {
      notification.initialOpened = _notice;
      await pumpHome(tester);
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('通知を押して開いたら、タブの中で開いたシートも閉じる', (tester) async {
      await pumpHome(tester);
      showAppSheet<void>(
        tester.element(find.byType(HomeBody)),
        builder: (_) => const Text('タブの中のシート'),
      );
      await tester.pumpAndSettle();
      expect(find.text('タブの中のシート'), findsOneWidget);
      notification.openNotification(_notice);
      await tester.pumpAndSettle();
      // 発信者ページの下に隠れて残っていないか（隠れた画面も探す）。
      expect(find.text('タブの中のシート', skipOffstage: false), findsNothing);
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('予定の事前通知を押して開いたら、その予定の詳細を開く', (tester) async {
      data.schedules.add(
        sampleSchedule(
          's1',
          '雑談の予約',
          DateTime.now().add(const Duration(minutes: 15)),
        ),
      );
      await pumpHome(tester);
      notification.openNotification(_scheduleNotice);
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleDetailSheet), findsOneWidget);
      expect(find.text('雑談の予約'), findsWidgets);
      expect(find.byType(CreatorScreen), findsNothing);
      await unmount(tester);
    });

    testWidgets('追いたいの人の登録の通知を押して開いたら、その発信者ページを開く', (tester) async {
      await pumpHome(tester);
      notification.openNotification(
        const LiveNotification(
          creatorId: 'minato',
          title: '',
          body: '',
          wantArrival: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('通知を押して開いたら、「通知から開いた」を対象つきで記録する', (tester) async {
      final reach = FakeReachRepository();
      data.schedules.add(
        sampleSchedule(
          's1',
          '雑談の予約',
          DateTime.now().add(const Duration(minutes: 15)),
        ),
      );
      await pumpScreen(
        tester,
        data,
        const HomeShell(),
        notification: notification,
        reach: reach,
      );
      notification.openNotification(
        const LiveNotification(
          creatorId: 'minato',
          title: '',
          body: '',
          service: 'twitch',
          liveId: '123',
        ),
      );
      await tester.pumpAndSettle();
      notification.openNotification(_scheduleNotice);
      await tester.pumpAndSettle();
      expect(reach.records, [
        'opened minato live:twitch:123',
        'opened minato schedule:s1',
        // 予定の通知で開いた予定の詳細も、「予定を開いた」として数える。
        'viewed minato schedule:s1',
      ]);
      await unmount(tester);
    });

    testWidgets('アプリを開いているときに届いただけでは、「通知から開いた」を記録しない', (tester) async {
      final reach = FakeReachRepository();
      await pumpScreen(
        tester,
        data,
        const HomeShell(),
        notification: notification,
        reach: reach,
      );
      notification.receiveNotification(_notice);
      await tester.pumpAndSettle();
      expect(reach.records, isEmpty);
      await unmount(tester);
    });

    testWidgets('予定がもう消えていれば、発信者ページを開く', (tester) async {
      await pumpHome(tester);
      notification.openNotification(_scheduleNotice);
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleDetailSheet), findsNothing);
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('予定の事前通知がアプリを開いているときに届いたら、スナックバーの「開く」で予定の詳細を開く', (
      tester,
    ) async {
      data.schedules.add(
        sampleSchedule(
          's1',
          '雑談の予約',
          DateTime.now().add(const Duration(minutes: 15)),
        ),
      );
      await pumpHome(tester);
      notification.receiveNotification(_scheduleNotice);
      await tester.pumpAndSettle();
      expect(find.text('星野ミナトの予定'), findsOneWidget);
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleDetailSheet), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('アプリを開いているときに届いたら、スナックバーを出し、「開く」で発信者ページを開く', (tester) async {
      await pumpHome(tester);
      notification.receiveNotification(_notice);
      await tester.pumpAndSettle();
      expect(find.text('星野ミナトが配信を始めました'), findsOneWidget);
      expect(find.byType(CreatorScreen), findsNothing);
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });
  });

  group('初回起動の途中に受けた通知', () {
    late FakeData data;
    late FakeNotificationRepository notification;

    setUp(() {
      data = FakeData()
        ..creators.add(sampleCreator())
        ..posts.add(samplePost());
      notification = FakeNotificationRepository();
    });

    /// アプリの土台から出す（初回起動が済んでいないので、ウェルカムから）。
    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: noProviderRetry,
          overrides: await testOverrides(data, notification: notification),
          child: const OiboshiApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsNothing);
      return ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
    }

    Future<void> finishOnboarding(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      await container.read(onboardingDoneProvider.notifier).complete();
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
    }

    testWidgets('押して開いた通知は、ホームに着いてから発信者ページを開く', (tester) async {
      final container = await pumpApp(tester);
      notification.openNotification(_notice);
      // あとで届いた通知で、押した出来事を消さない。
      notification.receiveNotification(_notice);
      await tester.pumpAndSettle();
      await finishOnboarding(tester, container);
      expect(find.byType(CreatorScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('届いた通知は、ホームに着いてからスナックバーを出す', (tester) async {
      final container = await pumpApp(tester);
      notification.receiveNotification(_notice);
      await tester.pumpAndSettle();
      await finishOnboarding(tester, container);
      expect(find.text('星野ミナトが配信を始めました'), findsOneWidget);
      expect(find.byType(CreatorScreen), findsNothing);
      await unmount(tester);
    });
  });
}

/// 端末の通知の許可の代わり。許可されていない端末として、受け取った印で状態を返す。
class _FakePermissionService extends NotificationPermissionService {
  bool? lastRequestedBefore;

  @override
  Future<NotificationPermission> status({required bool requestedBefore}) async {
    lastRequestedBefore = requestedBefore;
    return requestedBefore
        ? NotificationPermission.denied
        : NotificationPermission.notRequested;
  }

  @override
  Future<bool> request() async => false;
}

/// 通知の送り先のサーバーの代わり。登録した（送り先・端末の種類・言語）を残す。
class _FakeDeviceTokenService implements DeviceTokenService {
  final calls = <(String, String, String)>[];

  @override
  Future<void> register(String token, String platform, String language) async =>
      calls.add((token, platform, language));

  @override
  Future<void> delete(String token) async {}
}

/// 通知設定。アプリの土台（`app.dart` の `_UserSync`）と同じく、通知の送り先の登録を監視する。
class _RegisteringScreen extends ConsumerWidget {
  const _RegisteringScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pushRegistrationProvider, (_, _) {});
    return const NotificationSettingsScreen();
  }
}
