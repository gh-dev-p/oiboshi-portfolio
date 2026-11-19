/// Supabase のテーブル・ビュー・関数・ストレージの名前（データ設計書）。
abstract final class Tables {
  static const creators = 'creators';
  static const creatorSummaries = 'creator_summaries';
  static const posts = 'posts';
  static const lives = 'lives';
  static const liveRecords = 'live_records';
  static const schedules = 'schedules';
  static const events = 'events';
  static const eventLinks = 'event_links';
  static const follows = 'follows';
  static const userSettings = 'user_settings';
  static const planSubscriptions = 'plan_subscriptions';
  static const deviceTokens = 'device_tokens';
  static const creatorOwners = 'creator_owners';
  static const creatorAccounts = 'creator_accounts';
  static const pendingAccountLinks = 'pending_account_links';
  static const creatorDisplays = 'creator_displays';
  static const creatorTypes = 'creator_types';
  static const hiddenCreators = 'hidden_creators';

  /// 【仮】Instagram の DM での確認のコード（データ設計書 3.1.7）。
  static const instagramDmRequests = 'instagram_dm_requests';
  static const wants = 'wants';
  static const creatorLinks = 'creator_links';
  static const creatorAnnounceImages = 'creator_announce_images';
}

abstract final class Functions {
  static const searchCreators = 'search_creators';
  static const recommendCreators = 'recommend_creators';
  static const registerDeviceToken = 'register_device_token';
  static const unlinkCreatorAccount = 'unlink_creator_account';
  static const reclaimableCreators = 'reclaimable_creators';
  static const setPostHidden = 'set_post_hidden';
  static const ownedHiddenPosts = 'owned_hidden_posts';
  static const saveEvent = 'save_event';
  static const registeredEventUrls = 'registered_event_urls';
  static const startAccountMerge = 'start_account_merge';
  static const finishAccountMerge = 'finish_account_merge';
  static const sharedCreator = 'shared_creator';
  static const recordReach = 'record_reach';
  static const wantAccount = 'want_account';
  static const myWants = 'my_wants';
  static const reachTotals = 'reach_totals';
  static const reachBySubject = 'reach_by_subject';
  static const ownedCreatorLinks = 'owned_creator_links';
  static const reorderCreatorLinks = 'reorder_creator_links';
  static const recordLinkClick = 'record_link_click';
  static const shortLinksFor = 'short_links_for';
  static const shortLinkCounts = 'short_link_counts';
  static const recordPostViews = 'record_post_views';
  static const postViewTotals = 'post_view_totals';

  /// 【仮】Instagram の DM での確認。
  static const instagramDmAccount = 'instagram_dm_account';
  static const requestInstagramDm = 'request_instagram_dm';
}

/// Edge Functions の名前（パスを含む）。
abstract final class EdgeFunctions {
  /// アカウント連携を始める。SNS のログインと許可の画面の URL を返す。
  static const linkAccountStart = 'link-account/start';

  /// SNS のプロフィールを返す（取り込み）。
  static const fetchProfile = 'fetch-profile';

  /// 発信者が開いたチケットのページから取り出した部分を読み、イベントの下書きを返す（イベントの登録）。
  static const readEventUrl = 'read-event-url';

  /// 発信者として登録する。基本プランの加入を確かめてから登録する。
  static const registerCreator = 'register-creator';

  /// オーナーが退会した発信者を取り戻す。基本プランの加入を確かめてから取り戻す。
  static const reclaimCreator = 'reclaim-creator';

  /// 購入のあとに、サーバーの加入の状態を RevenueCat から引き直させる。
  static const syncSubscription = 'sync-subscription';

  /// 退会のときに、Apple のひも付けを取り消す。再認証で受け取った一時的なコードを渡す。
  static const revokeApple = 'revoke-apple';

  /// 退会する。ファンのカバー画像を消し切ってから、ユーザーを消す。
  static const deleteAccount = 'delete-account';

  /// 発信者・イベントの公演を通報する。通報を足し、運営にメールで知らせる。
  static const submitReport = 'submit-report';

  /// 週間の告知画像を作る（POST）。テンプレの一覧は [announceImageTemplates]（GET）。
  static const announceImage = 'announce-image';
  static const announceImageTemplates = 'announce-image/templates';
}

abstract final class Buckets {
  static const covers = 'covers';
  static const creatorImages = 'creator-images';

  /// ファンのカバー画像の置き場（`{ユーザーID}/{発信者ID}.jpg`）。
  static String coverPath(String userId, String creatorId) =>
      '$userId/$creatorId.jpg';

  /// 発信者のアイコン・カバーの置き場（`{発信者ID}/avatar.jpg`・`{発信者ID}/cover.jpg`）。
  static String creatorImagePath(String creatorId, String name) =>
      '$creatorId/$name.jpg';
}
