import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/announce/announce_image_repository.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/billing/billing_repository.dart';
import '../data/repositories/creator/creator_repository.dart';
import '../data/repositories/creator_admin/creator_admin_repository.dart';
import '../data/repositories/creator_admin/instagram_dm_repository.dart';
import '../data/repositories/follow/follow_repository.dart';
import '../data/repositories/follow/hidden_creator_repository.dart';
import '../data/repositories/notification/notification_repository.dart';
import '../data/repositories/post/post_repository.dart';
import '../data/repositories/creator_link/creator_link_repository.dart';
import '../data/repositories/post_view/post_view_repository.dart';
import '../data/repositories/reach/reach_repository.dart';
import '../data/repositories/report/report_repository.dart';
import '../data/repositories/want/want_repository.dart';
import '../data/repositories/schedule/schedule_repository.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/services/share/announce_image_service.dart';
import '../data/services/auth/auth_service.dart';
import '../data/services/billing/billing_service.dart';
import '../data/services/billing/subscription_sync_service.dart';
import '../data/services/creator/account_link_service.dart';
import '../data/services/creator/instagram_dm_service.dart';
import '../data/services/creator/creator_image_storage_service.dart';
import '../data/services/creator/creator_service.dart';
import '../data/services/creator/profile_import_service.dart';
import '../data/services/follow/cover_storage_service.dart';
import '../data/services/follow/follow_service.dart';
import '../data/services/follow/hidden_creator_service.dart';
import '../data/services/notification/device_token_service.dart';
import '../data/services/notification/notification_permission_service.dart';
import '../data/services/notification/push_messaging_service.dart';
import '../data/services/post/post_service.dart';
import '../data/services/creator/creator_link_service.dart';
import '../data/services/post_view/post_view_service.dart';
import '../data/services/reach/reach_service.dart';
import '../data/services/report/report_service.dart';
import '../data/services/want/want_service.dart';
import '../data/services/schedule/schedule_service.dart';
import '../data/services/settings/app_info_service.dart';
import '../data/services/settings/app_preferences_store.dart';
import '../data/services/settings/user_settings_service.dart';
import '../data/services/common/image_picker_service.dart';
import '../data/services/share/app_link_service.dart';
import '../data/services/share/clipboard_service.dart';
import '../data/services/share/share_sheet_service.dart';
import 'app_env.dart';
import 'preferences_provider.dart';

/// Repository と Service の Provider。View からは使わず、ViewModel を通す（アーキテクチャ設計書 2.2）。
/// 接続先（[SupabaseClient]）は、起動時に上書きする。テストでは、Repository を差し替える。
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider(
  (ref) => AuthService(
    ref.watch(supabaseClientProvider),
    authUrl: '${AppEnv.supabaseUrl}/auth/v1',
  ),
);
final creatorServiceProvider = Provider(
  (ref) => CreatorService(ref.watch(supabaseClientProvider)),
);
final creatorImageStorageServiceProvider = Provider(
  (ref) => CreatorImageStorageService(ref.watch(supabaseClientProvider)),
);
final accountLinkServiceProvider = Provider(
  (ref) => AccountLinkService(ref.watch(supabaseClientProvider)),
);
// 【仮】Instagram の DM での確認（機能仕様書 4.6.2.1）。Meta の審査が通ったら外す。
final instagramDmServiceProvider = Provider(
  (ref) => InstagramDmService(ref.watch(supabaseClientProvider)),
);
final profileImportServiceProvider = Provider(
  (ref) => ProfileImportService(ref.watch(supabaseClientProvider)),
);
final followServiceProvider = Provider(
  (ref) => FollowService(ref.watch(supabaseClientProvider)),
);
final hiddenCreatorServiceProvider = Provider(
  (ref) => HiddenCreatorService(ref.watch(supabaseClientProvider)),
);
final reportServiceProvider = Provider(
  (ref) => ReportService(ref.watch(supabaseClientProvider)),
);
final coverStorageServiceProvider = Provider(
  (ref) => CoverStorageService(ref.watch(supabaseClientProvider)),
);
final postServiceProvider = Provider(
  (ref) => PostService(ref.watch(supabaseClientProvider)),
);
final scheduleServiceProvider = Provider(
  (ref) => ScheduleService(ref.watch(supabaseClientProvider)),
);
final userSettingsServiceProvider = Provider(
  (ref) => UserSettingsService(ref.watch(supabaseClientProvider)),
);
final appPreferencesStoreProvider = Provider(
  (ref) => AppPreferencesStore(ref.watch(sharedPreferencesProvider)),
);
final notificationPermissionServiceProvider = Provider(
  (ref) => const NotificationPermissionService(),
);
final pushMessagingServiceProvider = Provider(
  (ref) => PushMessagingService(PushMessagingService.instanceIfReady()),
);
final deviceTokenServiceProvider = Provider(
  (ref) => DeviceTokenService(ref.watch(supabaseClientProvider)),
);
final appInfoServiceProvider = Provider((ref) => const AppInfoService());
final reachRepositoryProvider = Provider(
  (ref) => ReachRepository(ReachService(ref.watch(supabaseClientProvider))),
);
final postViewRepositoryProvider = Provider(
  (ref) =>
      PostViewRepository(PostViewService(ref.watch(supabaseClientProvider))),
);
final creatorLinkRepositoryProvider = Provider(
  (ref) => CreatorLinkRepository(
    CreatorLinkService(ref.watch(supabaseClientProvider)),
  ),
);
final appLinkServiceProvider = Provider((ref) => AppLinkService(AppLinks()));
final clipboardServiceProvider = Provider((ref) => const ClipboardService());
final shareSheetServiceProvider = Provider((ref) => const ShareSheetService());
final billingServiceProvider = Provider(
  (ref) => BillingService(switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppEnv.revenueCatIosKey,
    TargetPlatform.android => AppEnv.revenueCatAndroidKey,
    _ => '',
  }),
);
final subscriptionSyncServiceProvider = Provider(
  (ref) => SubscriptionSyncService(ref.watch(supabaseClientProvider)),
);

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(appPreferencesStoreProvider),
  ),
);
final creatorRepositoryProvider = Provider(
  (ref) => CreatorRepository(ref.watch(creatorServiceProvider)),
);
final followRepositoryProvider = Provider(
  (ref) => FollowRepository(
    ref.watch(followServiceProvider),
    ref.watch(coverStorageServiceProvider),
    ref.watch(authServiceProvider),
  ),
);
final hiddenCreatorRepositoryProvider = Provider(
  (ref) => HiddenCreatorRepository(ref.watch(hiddenCreatorServiceProvider)),
);
final reportRepositoryProvider = Provider(
  (ref) => ReportRepository(ref.watch(reportServiceProvider)),
);
final wantRepositoryProvider = Provider(
  (ref) => WantRepository(WantService(ref.watch(supabaseClientProvider))),
);
final postRepositoryProvider = Provider(
  (ref) => PostRepository(ref.watch(postServiceProvider)),
);
final scheduleRepositoryProvider = Provider(
  (ref) => ScheduleRepository(ref.watch(scheduleServiceProvider)),
);
final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(
    ref.watch(userSettingsServiceProvider),
    ref.watch(appPreferencesStoreProvider),
    ref.watch(appInfoServiceProvider),
  ),
);
final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(
    ref.watch(notificationPermissionServiceProvider),
    ref.watch(pushMessagingServiceProvider),
    ref.watch(deviceTokenServiceProvider),
    ref.watch(appPreferencesStoreProvider),
  ),
);
final creatorAdminRepositoryProvider = Provider(
  (ref) => CreatorAdminRepository(
    ref.watch(creatorServiceProvider),
    ref.watch(creatorImageStorageServiceProvider),
    ref.watch(accountLinkServiceProvider),
    ref.watch(profileImportServiceProvider),
  ),
);
// 【仮】Instagram の DM での確認（機能仕様書 4.6.2.1）。Meta の審査が通ったら外す。
final instagramDmRepositoryProvider = Provider(
  (ref) => InstagramDmRepository(ref.watch(instagramDmServiceProvider)),
);
final billingRepositoryProvider = Provider(
  (ref) => BillingRepository(
    ref.watch(billingServiceProvider),
    ref.watch(subscriptionSyncServiceProvider),
  ),
);

/// 週間の告知画像（届ける・広める仕様書 4.4.1）。画像はサーバーが作る。
final announceImageRepositoryProvider = Provider(
  (ref) => AnnounceImageRepository(
    AnnounceImageService(ref.watch(supabaseClientProvider)),
  ),
);

/// 端末の写真を選ぶ。発信者のカバー・アイコンの変更で使う。
final imagePickerServiceProvider = Provider(
  (ref) => ImagePickerService(ImagePicker()),
);
