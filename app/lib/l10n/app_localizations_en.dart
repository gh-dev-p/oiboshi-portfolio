// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oiboshi';

  @override
  String get startupErrorTitle => 'Couldn\'t start the app';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonNotFound => 'No results';

  @override
  String get commonPageOpenFailed => 'Couldn\'t open the page';

  @override
  String get commonRefreshFailed => 'Couldn\'t refresh';

  @override
  String get commonLoadFailedTitle => 'Couldn\'t load';

  @override
  String get commonLoadFailedMessage => 'Check your connection and try again.';

  @override
  String get commonSaveFailed => 'Couldn\'t save';

  @override
  String get commonSettingChangeFailed => 'Couldn\'t change the setting';

  @override
  String get commonNotificationSettingChangeFailed =>
      'Couldn\'t change the notification setting';

  @override
  String get commonFollow => 'Follow';

  @override
  String get commonFollowing => 'Following';

  @override
  String get commonFollowChangeFailed => 'Couldn\'t update follow';

  @override
  String get commonTabHome => 'Home';

  @override
  String get commonTabSchedule => 'Schedule';

  @override
  String get commonTabOshiList => 'Favorites';

  @override
  String get commonTabSettings => 'Settings';

  @override
  String get commonFixedViewer => 'Pinned viewer';

  @override
  String get commonFixedViewerPlayLive => 'Switch to live';

  @override
  String get fixedViewerEmptyMessage =>
      'Find favorites who stream or post videos';

  @override
  String get fixedViewerModeLive => 'Switched to live';

  @override
  String get fixedViewerNoLive => 'None of your favorites are live';

  @override
  String get fixedViewerControlPlay => 'Play';

  @override
  String get fixedViewerControlPause => 'Pause';

  @override
  String get fixedViewerControlNext => 'Next';

  @override
  String get fixedViewerControlPrevious => 'Previous';

  @override
  String get fixedViewerPaused => 'Paused';

  @override
  String get fixedViewerResumed => 'Resumed';

  @override
  String get fixedViewerModeShuffle => 'Switched to video shuffle';

  @override
  String get fixedViewerLiveEndedShuffle =>
      'The stream ended. Switched to video shuffle';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonAllDay => 'All day';

  @override
  String get commonLive => 'Live';

  @override
  String get commonPost => 'Post';

  @override
  String get commonNoPostsYet => 'No posts yet';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get commonSuspended => 'Suspended';

  @override
  String get commonOpenCreatorPage => 'Open creator page';

  @override
  String get commonOpenPost => 'Open post';

  @override
  String get commonEvent => 'Event';

  @override
  String get commonLink => 'Link';

  @override
  String get commonTicket => 'Tickets';

  @override
  String get scheduleDetailOpenTicket => 'View tickets';

  @override
  String get commonLivePin => 'Play in pinned viewer';

  @override
  String get commonLivePrevious => 'Previous stream';

  @override
  String get commonLiveNext => 'Next stream';

  @override
  String get commonLiveOpenCreator => 'Open creator page';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get timeStarted => 'Started';

  @override
  String get timeSoon => 'Soon';

  @override
  String timeHoursLeft(int count) {
    return 'In ${count}h';
  }

  @override
  String timeDaysLater(int count) {
    return 'In $count days';
  }

  @override
  String priceYen(String amount) {
    return '¥$amount';
  }

  @override
  String snsServiceName(String service) {
    String _temp0 = intl.Intl.selectLogic(service, {
      'twitcasting': 'TwitCasting',
      'youtube': 'YouTube',
      'instagram': 'Instagram',
      'twitch': 'Twitch',
      'x': 'X',
      'other': '$service',
    });
    return '$_temp0';
  }

  @override
  String postKindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'video': 'Video',
      'short': 'Short',
      'image': 'Image',
      'reel': 'Reel',
      'carousel': 'Carousel',
      'other': 'Post',
    });
    return '$_temp0';
  }

  @override
  String displayContentName(String content) {
    String _temp0 = intl.Intl.selectLogic(content, {
      'live': 'Live',
      'video': 'Videos & Shorts',
      'post': 'Posts',
      'schedule': 'Scheduled streams',
      'other': '$content',
    });
    return '$_temp0';
  }

  @override
  String creatorPlanName(String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'standard': 'Basic plan',
      'complimentary': 'Free forever',
      'admin': 'Operator',
      'debug': 'Testing',
      'other': '$plan',
    });
    return '$_temp0';
  }

  @override
  String displayModeName(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'system': 'Use device setting',
      'light': 'Light',
      'dark': 'Dark',
      'other': '$mode',
    });
    return '$_temp0';
  }

  @override
  String appLanguageName(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'system': 'Use device setting',
      'ja': '日本語',
      'en': 'English',
      'other': '$language',
    });
    return '$_temp0';
  }

  @override
  String get commonTermsOfService => 'Terms of Service';

  @override
  String get commonPrivacyPolicy => 'Privacy Policy';

  @override
  String get creatorCoverChangeFailed => 'Couldn\'t change the cover';

  @override
  String get creatorWatchLive => 'Watch in the viewer';

  @override
  String get creatorChangeCover => 'Change cover';

  @override
  String get creatorCoverPickPhoto => 'Choose a photo';

  @override
  String get creatorCoverReset => 'Use the creator\'s cover';

  @override
  String get creatorFlipCover => 'Flip cover';

  @override
  String get fixedViewerLiveEnded => 'The stream has ended';

  @override
  String get creatorTotalFollowers => 'total followers';

  @override
  String get creatorBioExpand => 'More';

  @override
  String get creatorBioCollapse => 'Less';

  @override
  String creatorNextScheduleHeader(String until) {
    return 'Next · $until';
  }

  @override
  String creatorNextScheduleMeta(String source, String date, String time) {
    return '$source · $date $time–';
  }

  @override
  String get creatorNextScheduleEvent => 'Event';

  @override
  String get creatorNewPostsDivider => 'New posts above';

  @override
  String get creatorBellNotifyOn => 'Turn on notifications';

  @override
  String get creatorBellNotifyOff => 'Turn off notifications';

  @override
  String get creatorBellUnfollow => 'Unfollow';

  @override
  String get creatorBellMenu => 'Notifications and follow';

  @override
  String get creatorMonthCalendar => 'Monthly calendar';

  @override
  String get creatorMenu => 'Menu';

  @override
  String get creatorReport => 'Report';

  @override
  String get creatorHide => 'Hide this creator';

  @override
  String creatorHideConfirmTitle(String name) {
    return 'Hide $name?';
  }

  @override
  String get creatorHideConfirmMessage =>
      'You\'ll unfollow them, and they won\'t appear in search or your timeline. You can undo this in Settings.';

  @override
  String get creatorHideConfirmAction => 'Hide';

  @override
  String get creatorHidden => 'Creator hidden';

  @override
  String get creatorHideFailed => 'Couldn\'t hide this creator';

  @override
  String get reportTitle => 'Report';

  @override
  String reportReasonName(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'impersonation': 'Impersonation',
      'inappropriate': 'Inappropriate content',
      'dangerousLink': 'Dangerous link',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get reportDetailLabel => 'Details (optional)';

  @override
  String get reportNote =>
      'We\'ll review this and hide it if needed. We won\'t notify you of the outcome.';

  @override
  String get reportSubmit => 'Send';

  @override
  String get reportSubmitted => 'Report sent. We\'ll review it.';

  @override
  String get reportAlreadySubmitted => 'You\'ve already reported this.';

  @override
  String get reportFailed => 'Couldn\'t send the report';

  @override
  String get commonLiveVideoFailed => 'Couldn\'t play the stream';

  @override
  String get commonLiveMute => 'Mute';

  @override
  String get commonLiveUnmute => 'Unmute';

  @override
  String get commonCreatorMenu => 'Creator menu';

  @override
  String get creatorAdminSuspendedNotice =>
      'The Oiboshi team has suspended this creator. Please contact us for details.';

  @override
  String get creatorAdminMenuSectionLinks => 'Links';

  @override
  String get creatorAdminProfileEditTitle => 'Edit profile';

  @override
  String get creatorAdminAccountLinkTitle => 'Linked SNS accounts';

  @override
  String creatorAdminMenuLinkedCount(int count) {
    return '$count';
  }

  @override
  String get creatorAdminMenuSectionContent => 'Content';

  @override
  String get creatorAdminMenuEventManage => 'Manage events';

  @override
  String get creatorAdminPostManageTitle => 'Manage posts';

  @override
  String get creatorAdminPlanTitle => 'Plan';

  @override
  String get creatorAdminUpcomingNiconico => 'Niconico';

  @override
  String get creatorAdminUpcomingTiktokContents => 'Live & short videos';

  @override
  String get creatorAdminUpcomingNiconicoContents => 'Live & videos';

  @override
  String creatorAdminLinked(String service) {
    return '$service linked';
  }

  @override
  String get creatorAdminLinkDuplicate =>
      'This account is already linked to another creator';

  @override
  String get creatorAdminLinkNoChannel => 'No YouTube channel found';

  @override
  String get creatorAdminLinkFailed => 'Couldn\'t link. Please try again';

  @override
  String creatorAdminUnlinkConfirmTitle(String service) {
    return 'Unlink $service?';
  }

  @override
  String get creatorAdminUnlinkConfirmMessage =>
      'It will no longer appear on Oiboshi.';

  @override
  String get creatorAdminUnlinkConfirmAction => 'Unlink';

  @override
  String creatorAdminUnlinked(String service) {
    return '$service unlinked';
  }

  @override
  String get creatorAdminUnlinkFailed => 'Couldn\'t unlink. Please try again';

  @override
  String get creatorAdminAccountLinkIntro =>
      'Once you link an account and it\'s verified as yours, it can appear on Oiboshi.';

  @override
  String get creatorAdminAccountLinkNote =>
      'Unverified accounts aren\'t shown on Oiboshi. After linking, you can still turn off what Oiboshi shows. You can unlink anytime.';

  @override
  String get creatorAdminLinkAction => 'Link';

  @override
  String get creatorAdminNotLinked => 'Not linked';

  @override
  String get creatorAdminDisplayContentsHideNote =>
      'Turning this off also hides already-fetched posts from fans right away.';

  @override
  String creatorAdminDisplayNeedsXOption(String price) {
    return 'Available with the X Integration plan ($price/month)';
  }

  @override
  String get creatorAdminRegistered => 'You\'re now registered as a creator';

  @override
  String get creatorAdminRegisteredPartially =>
      'You\'re now registered as a creator, but part of your profile couldn\'t be saved. Please fix it in Edit profile';

  @override
  String get creatorAdminRegisterIdTaken => 'This ID is already taken';

  @override
  String get creatorAdminRegisterDuplicate =>
      'A linked account is already used by another creator';

  @override
  String get creatorAdminRegisterClosed =>
      'Creator registration is coming soon';

  @override
  String get creatorAdminRegisterFailed =>
      'Couldn\'t register. Please try again';

  @override
  String get creatorAdminRegisterTitle => 'Become a creator';

  @override
  String get creatorAdminRegisterHeadline =>
      'Bring your streams, posts, and events\nto your fans';

  @override
  String get creatorAdminRegisterEyebrow => 'FOR CREATORS';

  @override
  String get creatorAdminRegisterLead =>
      'Sign in to the social accounts you want to link.\nYour posts, follower counts, links, and more will appear in the app.';

  @override
  String get creatorAdminRegisterStepLink => 'Link your social accounts';

  @override
  String creatorAdminRegisterStepLinkDone(String services) {
    return 'Linked $services';
  }

  @override
  String get commonListSeparator => ', ';

  @override
  String get creatorAdminRegisterStepProfile => 'Enter your profile';

  @override
  String creatorAdminRegisterStepProfileDone(String name, String id) {
    return 'Entered as $name (@$id)';
  }

  @override
  String get creatorAdminRegisterAgreePrefix => 'I agree to the ';

  @override
  String get creatorAdminRegisterAgreeSeparator => ', ';

  @override
  String get creatorAdminRegisterAgreeLastSeparator => ', and ';

  @override
  String get creatorAdminRegisterTerms => 'Creator Terms of Use';

  @override
  String get creatorAdminRegisterAgreeSuffix => '';

  @override
  String get creatorAdminRegisterAction => 'Register as a creator';

  @override
  String creatorAdminImportFailed(String service) {
    return 'Couldn\'t import from $service';
  }

  @override
  String creatorAdminImportEmpty(String service) {
    return 'Nothing to import from $service';
  }

  @override
  String creatorAdminImportLimited(String service) {
    return 'Too many imports from $service. Please try again later';
  }

  @override
  String creatorAdminImported(String service) {
    return 'Draft filled in from $service';
  }

  @override
  String creatorAdminDraftBadge(String service) {
    return 'Draft from $service';
  }

  @override
  String get creatorAdminNameInvalid => 'Name must be 1–100 characters';

  @override
  String get creatorAdminIdInvalid =>
      'ID must be 1–40 characters: lowercase letters, numbers, _ or -';

  @override
  String get creatorAdminChangeCover => 'Change cover';

  @override
  String get creatorAdminChangeAvatar => 'Change icon';

  @override
  String get creatorAdminImportTitle => 'Fill in from linked accounts';

  @override
  String get creatorAdminImportDescription =>
      'Fills in your name, icon, and bio as a draft. Nothing changes until you save.';

  @override
  String get creatorAdminFieldName => 'Name';

  @override
  String get creatorAdminFieldBio => 'Bio';

  @override
  String get creatorAdminIdNote => 'Your ID can\'t be changed later.';

  @override
  String get creatorAdminIdHint => 'Lowercase letters, numbers, _ -';

  @override
  String get creatorAdminEventRequiredMissing =>
      'Please fill in the required fields';

  @override
  String get creatorAdminEventFieldTitle => 'Title';

  @override
  String get creatorAdminEventTitleHint => 'e.g. New outfit reveal';

  @override
  String get creatorAdminEventFieldDate => 'Date';

  @override
  String creatorAdminEventDate(String date, String weekday) {
    return '$weekday, $date';
  }

  @override
  String get creatorAdminEventPickDate => 'Choose a date';

  @override
  String get creatorAdminEventFieldStart => 'Start';

  @override
  String get creatorAdminEventFieldEnd => 'End (optional)';

  @override
  String get creatorAdminEventEndNote =>
      'If not set, it is shown until the end of the day';

  @override
  String get creatorAdminEventFieldVenue => 'Venue (optional)';

  @override
  String get creatorAdminEventVenueHint => 'e.g. XX Hall, Shibuya, Tokyo';

  @override
  String get creatorAdminEventPromotion => 'This link is an ad';

  @override
  String get creatorAdminEventPromotionHint =>
      'Shows a \"PR\" label (e.g. ticket sales)';

  @override
  String get creatorAdminEventTitleTooLong => 'Title must be 1–200 characters';

  @override
  String get creatorAdminEventLinkInvalid =>
      'Enter a URL that starts with https://';

  @override
  String get creatorAdminEventDelete => 'Delete';

  @override
  String get creatorAdminEventDeleteFailed => 'Couldn\'t delete';

  @override
  String get creatorAdminEventListAdd => 'Add';

  @override
  String get creatorAdminEventListEmpty => 'No events yet';

  @override
  String get creatorAdminEventListPast => 'Past events';

  @override
  String get commonRequired => 'Required';

  @override
  String get creatorAdminPlanPurchasePending => 'Waiting for payment approval';

  @override
  String get creatorAdminPlanPurchaseFailed =>
      'Couldn\'t complete the purchase. Please try again';

  @override
  String get creatorAdminPlanRestored => 'Purchases restored';

  @override
  String get creatorAdminPlanNothingToRestore => 'No purchases to restore';

  @override
  String get creatorAdminPlanRestoreFailed =>
      'Couldn\'t restore. Please try again';

  @override
  String get creatorAdminPlanCurrent => 'Current plan';

  @override
  String get creatorAdminPlanFree => 'Free';

  @override
  String get creatorAdminPlanSubscribe => 'Subscribe';

  @override
  String get creatorAdminPlanSubscribed => 'Active';

  @override
  String creatorAdminPlanPerMonth(String price) {
    return '$price/month';
  }

  @override
  String creatorAdminPlanBasicFeatureFetch(String services) {
    return 'Fetch and show content from $services';
  }

  @override
  String get creatorAdminPlanBasicFeatureReservations =>
      'Fetch scheduled streams';

  @override
  String get creatorAdminPlanBasicFeatureCalendar => 'Add events';

  @override
  String get creatorAdminPlanAddOns => 'Add-ons';

  @override
  String get creatorAdminPlanXOptionTitle => 'X Integration plan';

  @override
  String get creatorAdminPlanXFeatureFetch => 'Fetch and show X posts';

  @override
  String get creatorAdminPlanXFeatureNoReposts =>
      'Reposts and replies aren\'t included';

  @override
  String get creatorAdminPlanCancel => 'Cancel';

  @override
  String get creatorAdminPlanCancelConfirmTitle => 'Open subscription settings';

  @override
  String get creatorAdminPlanCancelConfirmMessage =>
      'You\'ll cancel in the store. You can keep using the X integration until the end of the current period.';

  @override
  String get creatorAdminPlanCancelConfirmAction => 'Open';

  @override
  String get creatorAdminPlanRestore => 'Restore purchases';

  @override
  String get creatorAdminPlanSubscriptionTerms =>
      'Payment will be charged to your store account. The X Integration plan is a monthly auto-renewing subscription. It renews automatically unless canceled at least 24 hours before the end of the current period. You can cancel in your store subscription settings.';

  @override
  String get creatorAdminPlanLegalSeparator => ' · ';

  @override
  String creatorAdminPlanRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String creatorAdminPlanEndsOn(String date) {
    return 'Ends on $date';
  }

  @override
  String get creatorAdminPlanUnavailableTitle =>
      'The X Integration plan isn\'t available on this device yet';

  @override
  String get creatorAdminPlanUnavailableMessage => 'Please check back later.';

  @override
  String get creatorAdminPlanIncludedNote =>
      'No charge (includes X integration)';

  @override
  String get onboardingWelcomeTagline =>
      'Your favorites\' streams, posts,\nand schedules, all in one place.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingForCreators => 'Are you a creator?';

  @override
  String get onboardingAgreePrefix =>
      'By tapping “Get started”, you agree to the\n';

  @override
  String get onboardingAgreeAnd => ' and ';

  @override
  String get onboardingAgreeSuffix => '.';

  @override
  String get onboardingChooseTitle => 'Follow your favorites';

  @override
  String get onboardingChooseMessage =>
      'Streams, posts, and schedules from creators you follow will appear on Home.';

  @override
  String get onboardingChooseSearchHint => 'Search by name or ID';

  @override
  String get onboardingNext => 'Next';

  @override
  String onboardingNextFollowing(int count) {
    return 'Next ($count following)';
  }

  @override
  String get onboardingLater => 'Later';

  @override
  String get onboardingNotificationTitle =>
      'We\'ll let you know\nwhen a stream starts';

  @override
  String get onboardingNotificationMessage =>
      'Get notified when your favorites go live.\nYou can change this later in Settings.';

  @override
  String get onboardingNotificationEnable => 'Turn on notifications';

  @override
  String get onboardingNotificationSkip => 'Not now';

  @override
  String get onboardingNotificationSampleTitle =>
      'Minato Hoshino started a live stream';

  @override
  String get onboardingNotificationSampleBody =>
      '[Apex] Platinum solo ranked marathon!';

  @override
  String get commonLiveOpenSource => 'Open on the streaming site';

  @override
  String get fixedViewerShufflePlay => 'Shuffle your favorites\' videos';

  @override
  String get homeShuffleEmpty => 'No videos to play';

  @override
  String get commonVideoPrevious => 'Previous video';

  @override
  String get commonVideoNext => 'Next video';

  @override
  String get homeEmptyTitle => 'Find your favorites';

  @override
  String get homeEmptyMessage =>
      'Follow creators to see their streams, schedules, and posts here.';

  @override
  String get homeTimelineEnd => 'You\'ve seen everything from the past 90 days';

  @override
  String get homeUpcomingTitle => 'Up next';

  @override
  String get homeUpcomingEmpty => 'Nothing else scheduled today';

  @override
  String get commonEventsTitle => 'Events';

  @override
  String get commonEventsEmpty => 'No upcoming events';

  @override
  String commonMoreCount(int count) {
    return '$count more';
  }

  @override
  String get commonFindCreatorsTitle => 'Find creators';

  @override
  String oshiListCount(int count) {
    return 'Following $count';
  }

  @override
  String get oshiListSortLiveFirst => 'Sort: Live first';

  @override
  String oshiListLiveNow(String title) {
    return 'Live: $title';
  }

  @override
  String oshiListNextSchedule(String when, String title) {
    return '$when $title';
  }

  @override
  String get oshiListNoSchedule => 'No upcoming events';

  @override
  String get oshiListEmptyTitle => 'No favorites yet';

  @override
  String get oshiListEmptyMessage => 'Follow creators to see them here.';

  @override
  String oshiListNoMatch(String query) {
    return 'None of your favorites match “$query”.';
  }

  @override
  String get oshiListUnfollowFailed => 'Couldn\'t unfollow';

  @override
  String commonFindNoMatch(String query) {
    return 'No creators matching “$query” on Oiboshi yet. Check the name or ID and try again.';
  }

  @override
  String get oshiFindRecommended => 'Recommended';

  @override
  String get commonViewOnX => 'View on X';

  @override
  String get postOpen => 'Open';

  @override
  String get postVideoPlay => 'Play';

  @override
  String get commonVideoUnplayable => 'This video can\'t be played in the app';

  @override
  String get creatorAdminPostManageNote =>
      'Hiding a post here doesn\'t delete it from the original social network. It just stops showing it to fans on Oiboshi.';

  @override
  String get creatorAdminPostVisibleSwitch => 'Show to fans';

  @override
  String get creatorAdminPostHidden => 'Post hidden';

  @override
  String get creatorAdminPostShown => 'Post shown again';

  @override
  String get creatorAdminPostHideFailed => 'Couldn\'t hide the post';

  @override
  String get creatorAdminPostShowFailed => 'Couldn\'t show the post';

  @override
  String get homeLiveStartedFallback => 'A favorite started streaming';

  @override
  String get homeLiveStartedOpen => 'Open';

  @override
  String get homeScheduleNoticeFallback => 'Upcoming from a favorite';

  @override
  String get homeWantArrivalFallback => 'A creator you wanted joined Oiboshi';

  @override
  String scheduleOpenEndedTime(String time) {
    return '$time–';
  }

  @override
  String get scheduleDayEmpty => 'No events on this day';

  @override
  String get scheduleDayEmptyHint => 'Pick another day from the dates above.';

  @override
  String get scheduleLiveNow => 'Live now';

  @override
  String get scheduleWatchLive => 'Watch live';

  @override
  String schedulePostsGroupTitle(String name) {
    return 'Posts by $name';
  }

  @override
  String schedulePostsGroupSubtitle(int hour, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return 'Around $hour:00 · $_temp0';
  }

  @override
  String schedulePostsGroupSemantics(int count, String services) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return '$_temp0 ($services)';
  }

  @override
  String get scheduleFilterTitle => 'Filter';

  @override
  String get scheduleFilterReset => 'Reset';

  @override
  String get scheduleFilterCreatorsTitle => 'Favorites to show';

  @override
  String get scheduleFilterSelectAll => 'Select all';

  @override
  String get scheduleFilterDeselectAll => 'Deselect all';

  @override
  String get scheduleFilterAllCreators => 'All';

  @override
  String scheduleFilterCreatorCount(int count) {
    return '$count';
  }

  @override
  String get scheduleFilterPlatforms => 'Platforms';

  @override
  String get scheduleFilterContent => 'Content to show';

  @override
  String get scheduleFilterHideEmpty =>
      'Hide favorites with no streams, posts, or events';

  @override
  String get scheduleHideEmptyOn =>
      'Hid favorites with no streams, posts, or events';

  @override
  String get scheduleHideEmptyOff => 'Showing all favorites';

  @override
  String scheduleFilterApply(int creators, int services) {
    String _temp0 = intl.Intl.pluralLogic(
      creators,
      locale: localeName,
      other: '$creators creators',
      one: '1 creator',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$services platforms',
      one: '1 platform',
    );
    return 'Show $_temp0 on $_temp1';
  }

  @override
  String get commonNoService => 'Event';

  @override
  String get scheduleEmptyTitle => 'Your favorites\' schedules show up here';

  @override
  String get scheduleEmptyMessage =>
      'Follow creators to see their streams and events on a timeline.';

  @override
  String get scheduleOpenCalendar => 'Calendar';

  @override
  String scheduleAllDayMore(String title, int count) {
    return '$title +$count';
  }

  @override
  String get scheduleCalendarAllTitle => 'Everyone\'s calendar';

  @override
  String scheduleCalendarCreatorTitle(String name) {
    return '$name\'s calendar';
  }

  @override
  String get eventListAllTitle => 'Everyone\'s events';

  @override
  String eventListCreatorTitle(String name) {
    return '$name\'s events';
  }

  @override
  String commonWhenVenue(String when, String venue) {
    return '$when · $venue';
  }

  @override
  String get eventListEmptyMessage =>
      'Events will appear here once they\'re added';

  @override
  String get schedulePreviousMonth => 'Previous month';

  @override
  String get scheduleNextMonth => 'Next month';

  @override
  String get scheduleCalendarDayPosts => 'Posts on this day';

  @override
  String schedulePostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return '$_temp0';
  }

  @override
  String get scheduleDetailLiveKind => 'Scheduled stream';

  @override
  String get scheduleDetailEnded => 'Ended';

  @override
  String get scheduleDetailUpcoming => 'Upcoming';

  @override
  String commonScheduleDateAllDay(String date) {
    return '$date · All day';
  }

  @override
  String commonScheduleDateTime(String date, String start, String end) {
    return '$date, $start–$end';
  }

  @override
  String commonScheduleDateTimeSpan(
    String startDate,
    String start,
    String endDate,
    String end,
  ) {
    return '$startDate, $start – $endDate, $end';
  }

  @override
  String get scheduleDetailEndOpen => 'End time not set';

  @override
  String get scheduleDetailLinkHint => 'Opens an external page';

  @override
  String get scheduleDetailReport => 'Report this event';

  @override
  String get scheduleDetailOpenLink => 'Open link';

  @override
  String get scheduleDetailEdit => 'Edit';

  @override
  String get commonLinkConfirmTitle => 'Open external site?';

  @override
  String get commonLinkConfirmOpen => 'Open';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSignedIn => 'Logged in';

  @override
  String get settingsLogoutConfirmTitle => 'Log out?';

  @override
  String get settingsLogoutConfirmMessage =>
      'You can log in again with a linked login method.';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLoggedOut => 'Logged out';

  @override
  String get settingsLogoutFailed => 'Couldn\'t log out';

  @override
  String get settingsOn => 'On';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDisplayMode => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsRegisterAsCreator => 'Register as a creator';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsLoginMethods => 'Login methods';

  @override
  String get settingsAccountRequired => 'Please create an account first';

  @override
  String get settingsHiddenCreators => 'Hidden creators';

  @override
  String settingsHiddenCreatorCount(int count) {
    return '$count';
  }

  @override
  String get settingsHiddenCreatorsDescription =>
      'Hidden creators won\'t appear in search or your timeline.';

  @override
  String get settingsHiddenCreatorsEmpty => 'No hidden creators';

  @override
  String get settingsHiddenCreatorShow => 'Show';

  @override
  String get settingsHiddenCreatorRestored => 'Creator is visible again';

  @override
  String get settingsHiddenCreatorRestoreFailed => 'Couldn\'t undo';

  @override
  String get settingsAccountEntry => 'Create account / Log in';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get commonContact => 'Contact us';

  @override
  String get settingsWithdraw => 'Delete account';

  @override
  String get creatorAdminMenuProfileCardHint => 'Edit your profile';

  @override
  String get commonVerified => 'Verified';

  @override
  String get settingsContactAddressPreparing =>
      'The contact email address isn\'t ready yet.';

  @override
  String get settingsContactByEmail =>
      'Please contact us by email at the address below.';

  @override
  String get settingsUserId => 'User ID';

  @override
  String get settingsCopyUserId => 'Copy user ID';

  @override
  String get commonContactSubject => 'Inquiry about Oiboshi';

  @override
  String commonContactBody(String userId, String version, String os) {
    return '\n\n----\nUser ID: $userId\nApp version: $version\nOS: $os\n';
  }

  @override
  String get commonContactNotSignedIn => '(not signed in)';

  @override
  String settingsLoginLinked(String provider) {
    return 'Linked $provider login';
  }

  @override
  String get settingsAccountAlreadyUsed =>
      'This account is already used by another user';

  @override
  String get settingsLinkFailed => 'Couldn\'t link. Please try again';

  @override
  String settingsUnlinkConfirmTitle(String provider) {
    return 'Unlink $provider login?';
  }

  @override
  String settingsUnlinkConfirmMessage(String provider) {
    return 'You won\'t be able to log in with $provider.';
  }

  @override
  String get settingsUnlink => 'Unlink';

  @override
  String settingsUnlinked(String provider) {
    return 'Unlinked $provider login';
  }

  @override
  String get settingsUnlinkFailed => 'Couldn\'t unlink. Please try again';

  @override
  String get settingsLoginMethodsDescription =>
      'You can log in from other devices with any linked method. Creators should link two or more.';

  @override
  String get settingsLoginMethodsNote =>
      'This is separate from linked social accounts. Unlinking a login method keeps those links.';

  @override
  String get settingsLink => 'Link';

  @override
  String get settingsLoginMethodSet => 'Set';

  @override
  String get settingsLoginFailed => 'Couldn\'t log in. Please try again';

  @override
  String get settingsAdminLogin => 'App operator login';

  @override
  String get settingsAdminLoginLead =>
      'Log in with an account provided by the app operator. New sign-ups aren\'t available.';

  @override
  String get settingsAdminLoginEmail => 'Email';

  @override
  String get settingsAdminLoginPassword => 'Password';

  @override
  String get settingsAdminLoginSubmit => 'Log in';

  @override
  String get settingsAdminLoginInvalid => 'Incorrect email or password';

  @override
  String get settingsAdminLoginTooMany => 'Please wait a while and try again';

  @override
  String get settingsLoginSheetCreatorLead =>
      'You need an account to register as a creator.';

  @override
  String get settingsAccountCreated => 'Account created';

  @override
  String get settingsContinueWithApple => 'Continue with Apple';

  @override
  String get settingsContinueWithGoogle => 'Continue with Google';

  @override
  String get settingsLoginWithApple => 'Sign in with Apple';

  @override
  String get settingsLoginWithGoogle => 'Sign in with Google';

  @override
  String settingsContinueWith(String provider) {
    return 'Continue with $provider';
  }

  @override
  String settingsLoginWith(String provider) {
    return 'Log in with $provider';
  }

  @override
  String get settingsNotificationSettingsTitle => 'Notification settings';

  @override
  String get settingsDeviceNotificationsOff =>
      'Notifications are off on this device. To be notified about streams and schedules, allow notifications in your device settings.';

  @override
  String get settingsOpenDeviceSettings => 'Open device settings';

  @override
  String get settingsNotificationPermissionPrompt =>
      'Allow notifications to know when your favorites go live and before their schedules.';

  @override
  String get settingsAllowNotifications => 'Allow notifications';

  @override
  String get settingsLiveStartNotification => 'Stream & schedule notifications';

  @override
  String get settingsLiveStartNotificationDescription =>
      'Get notified when your favorites go live and before their scheduled streams and events';

  @override
  String get settingsPerCreatorNotificationNote =>
      'You can change notifications for each favorite on their page.';

  @override
  String get settingsReauthLoadFailed => 'Couldn\'t load. Please try again';

  @override
  String get settingsReauthAppleMessage =>
      'To also revoke Sign in with Apple, please log in with Apple again.';

  @override
  String get settingsWrongAccount => 'Please log in with the linked account';

  @override
  String get settingsReauthTitle => 'Verify it\'s you';

  @override
  String get settingsReauthUnavailable =>
      'Your linked login methods aren\'t available on this device. Please use an iPhone.';

  @override
  String get settingsReauthMessage =>
      'Before this important action, please log in again with a linked login method.';

  @override
  String get settingsWithdrawWarning =>
      'Deleting your account removes your followed favorites and your notification and display settings. This can\'t be undone.';

  @override
  String get settingsWithdrawAppleElsewhere =>
      'Sign in with Apple can\'t be revoked on this device. Delete your account on an iPhone, or afterwards remove it under \"Sign in with Apple\" in your iPhone settings.';

  @override
  String get settingsWithdrawAppleOnly =>
      'You log in only with Apple, so we can\'t verify it\'s you on this device. Please delete your account on an iPhone.';

  @override
  String get settingsWithdrawButton => 'Delete account';

  @override
  String get settingsWithdrawFailed => 'Couldn\'t delete your account';

  @override
  String get creatorAdminLinkReclaimable =>
      'This account belongs to a creator whose owner deleted their account. You can reclaim it from the registration screen';

  @override
  String get creatorAdminUnlinkConfirmHeldMessage =>
      'It will disappear from Oiboshi right away. Fetched posts, streams, schedules, and history are kept for 90 days, then deleted. If you link the same account again within 90 days, everything comes back.';

  @override
  String get settingsWithdrawCreatorNote =>
      'Your creator page will disappear from Oiboshi right away and be deleted after 90 days. Within 90 days, you can reclaim it by linking the same social account on the creator registration screen.';

  @override
  String get settingsWithdrawSubscriptionNote =>
      'Deleting your account doesn\'t cancel your store subscription. Cancel it in subscription settings first.';

  @override
  String get settingsWithdrawManageSubscription => 'Open subscription settings';

  @override
  String get creatorAdminProfileTypesLabel => 'Type';

  @override
  String creatorAdminProfileTypesNote(int count) {
    return 'Choose up to $count. Used for recommendations.';
  }

  @override
  String get creatorAdminProfileTypesLoadFailed => 'Couldn\'t load types';

  @override
  String creatorAdminReclaimed(String name) {
    return '$name has been reclaimed';
  }

  @override
  String get creatorAdminReclaimNotReclaimable =>
      'This creator can no longer be reclaimed';

  @override
  String get creatorAdminReclaimDuplicate =>
      'A linked account is used by another creator';

  @override
  String get creatorAdminReclaimFailed => 'Couldn\'t reclaim. Please try again';

  @override
  String get creatorAdminReclaimTitle => 'You can reclaim this creator';

  @override
  String creatorAdminReclaimMessage(
    String name,
    String id,
    String date,
    String plan,
  ) {
    return 'The creator \"$name\" (@$id) for the linked account isn\'t shown on Oiboshi because its owner deleted their account. Reclaim it by $date to get its profile, links, and schedules back as they were. $plan';
  }

  @override
  String get creatorAdminReclaimNeedsPlan =>
      'If you subscribed to the X Integration plan, you can carry it over with \"Restore purchases\" on the Plan screen after reclaiming.';

  @override
  String get creatorAdminReclaimAction => 'Reclaim';

  @override
  String commonPostKindTime(String kind, String time) {
    return '$kind · $time';
  }

  @override
  String commonServiceTime(String service, String time) {
    return '$service · $time';
  }

  @override
  String get creatorAdminProfileIdLabel => 'ID';

  @override
  String get creatorAdminDmTitle => 'Verify Instagram by DM';

  @override
  String creatorAdminDmIntro(String account) {
    return 'Enter your Instagram username to get a code. Send the code by DM from that account to our Instagram (@$account), and we\'ll mark it as verified.';
  }

  @override
  String get creatorAdminDmUsernameLabel => 'Instagram username';

  @override
  String get creatorAdminDmRequest => 'Get a code';

  @override
  String creatorAdminDmTarget(String account) {
    return 'Account to verify: @$account';
  }

  @override
  String get creatorAdminDmCopy => 'Copy';

  @override
  String get creatorAdminDmCopied => 'Code copied';

  @override
  String creatorAdminDmSendTo(String account) {
    return 'Send to: @$account';
  }

  @override
  String get creatorAdminDmOpen => 'Send a DM on Instagram';

  @override
  String creatorAdminDmNote(String date) {
    return 'Verification may take a few days. The code is valid until $date.';
  }

  @override
  String get creatorAdminDmCancel => 'Cancel';

  @override
  String get creatorAdminDmInvalid => 'Please check your Instagram username';

  @override
  String get creatorAdminDmFailed => 'Couldn\'t get a code. Please try again';

  @override
  String get creatorAdminDmCancelFailed => 'Couldn\'t cancel. Please try again';

  @override
  String get creatorAdminDmPending => 'Pending';

  @override
  String get eventRegisterTitle => 'Add an event';

  @override
  String get eventRegisterUrlLabel => 'Ticket URL';

  @override
  String get eventRegisterUrlHint =>
      'We open the ticket page and read the title, dates, and venue. Fill in anything we couldn\'t read.';

  @override
  String get eventRegisterRead => 'Read';

  @override
  String get eventRegisterReadDone => 'Done. Please check the details';

  @override
  String get eventRegisterReadFailed =>
      'Couldn\'t read the page. Please fill it in yourself';

  @override
  String get eventRegisterPerformance => 'Show';

  @override
  String get performancePickerTitle => 'Choose a show';

  @override
  String get performancePickerNote => 'Each event holds one show.';

  @override
  String get eventRegisterSaved => 'Event added';

  @override
  String get eventPageReaderRead => 'Read from this page';

  @override
  String get eventPageReaderNote =>
      'We read the title, dates, and venue from the page you\'re viewing.';

  @override
  String get eventPageReaderRegister => 'Register this event';

  @override
  String eventPageReaderCandidates(int count) {
    return 'Choose from events on this page ($count)';
  }

  @override
  String get eventCandidatesTitle => 'Event candidates';

  @override
  String get eventCandidatesNote =>
      'Tap to open the page. Check it, then tap \"Register this event\".';

  @override
  String get eventCandidatesRegistered => 'Registered';

  @override
  String get eventPageReaderReadTime => 'Read the time from this page';

  @override
  String get eventCandidatesSavedTimeTbd =>
      'Event registered. Add times for TBD shows by editing it';

  @override
  String get eventSearchTitle => 'Search ticket sites';

  @override
  String get eventSearchName => 'Artist name';

  @override
  String get eventSearchNote =>
      'Searches Ticket Pia, eplus, Lawson Ticket, and Rakuten Ticket for artists with this name. Others with the same name may appear, so check before choosing.';

  @override
  String get eventRegisterTimeTbd => 'Time TBD';

  @override
  String get eventRegisterTimeTbdHint =>
      'The start time isn\'t set or known yet';

  @override
  String get eventRegisterReadTime => 'Read the time from the page';

  @override
  String get eventRegisterTimeRead => 'Time read';

  @override
  String get eventRegisterTimeReadFailed => 'Couldn\'t read the time';

  @override
  String get commonTimeTbd => 'Time TBD';

  @override
  String commonScheduleDateTimeTbd(String date) {
    return '$date Time TBD';
  }

  @override
  String get eventSearchButton => 'Search';

  @override
  String get eventSearchNoArtist => 'No artists found';

  @override
  String get eventCandidatesEmpty => 'No events found';

  @override
  String get performanceCandidatesNote =>
      'Tap to open the show\'s page. Check it, then tap \"Register this event\".';

  @override
  String get performanceCandidatesEmpty => 'No shows found';

  @override
  String performanceCandidatesLoading(int done, int total) {
    return 'Gathering shows ($done/$total)';
  }

  @override
  String performanceCandidatesFailedEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages couldn\'t be loaded',
      one: '1 page couldn\'t be loaded',
    );
    return '$_temp0';
  }

  @override
  String get performanceCandidatesTitle => 'Show candidates';

  @override
  String eventSearchShowPerformances(int count) {
    return 'See shows ($count)';
  }

  @override
  String get eventSearchMaintenance =>
      'This site is under maintenance right now';

  @override
  String eventSearchRakutenEvents(String name, int count) {
    return 'Events matching \"$name\" ($count)';
  }

  @override
  String get eventRegisterUpdated => 'Event saved';

  @override
  String get eventRegisterDuplicateLink =>
      'This ticket link is already used by another event';

  @override
  String get eventRegisterDeleteConfirmTitle => 'Delete this event?';

  @override
  String get eventRegisterDeleteConfirmMessage =>
      'Its shows and ticket links will be deleted too.';

  @override
  String get eventEditTitle => 'Edit event';

  @override
  String get eventRegisterLinksLabel => 'Ticket links';

  @override
  String get eventRegisterAddLink => '+ Add a ticket link';

  @override
  String get eventRegisterRemoveLink => 'Remove this ticket link';

  @override
  String get eventRegisterDelete => 'Delete this event';

  @override
  String eventDetailOpenSite(String site) {
    return 'Buy on $site';
  }

  @override
  String get shareLinkAction => 'Share link';

  @override
  String shareLinkMessage(String name, String link) {
    return 'Follow $name\'s streams and schedule on Oiboshi\n$link';
  }

  @override
  String get shareLinkUnavailable =>
      'You can\'t share the link because this creator isn\'t shown to fans (no verified account, or suspended).';

  @override
  String get shareLinkFailed => 'Couldn\'t share the link';

  @override
  String get shareLinkNotFound => 'Couldn\'t find the creator for this link';

  @override
  String get shareLinkTitle => 'Share link';

  @override
  String get shareLinkShareButton => 'Share link';

  @override
  String get shareLinkSaveQr => 'Save or share QR image';

  @override
  String get shareLinkNote =>
      'People without the app go to the App Store, and start out following this creator once they install and open it. People with the app go straight to this page.';

  @override
  String get shareLinkCopied => 'Link copied';

  @override
  String get shareLinkCopy => 'Copy link';

  @override
  String get shareLinkQrLabel => 'QR code for the share link';

  @override
  String get shareLinkUnavailableTitle => 'Can\'t share yet';

  @override
  String get wantTitle => 'Want to follow';

  @override
  String get wantIntro =>
      'Request someone who isn\'t on Oiboshi yet with their social media URL or ID. When they join, we\'ll let you know and follow them for you.';

  @override
  String get wantServiceLabel => 'Platform (choose when entering an ID)';

  @override
  String get wantInputLabel => 'URL or ID';

  @override
  String get wantInputHint => 'https://x.com/… or @ID';

  @override
  String get wantParsed => 'ID to request';

  @override
  String get wantSubmit => 'Want to follow';

  @override
  String get wantPrivacyNote =>
      'Oiboshi only keeps the platform, the ID and the number of requests. We never show who made a request.';

  @override
  String get wantListTitle => 'Your requests';

  @override
  String get wantListEmpty => 'No requests yet';

  @override
  String wantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people want to follow',
      one: '1 person wants to follow',
    );
    return '$_temp0';
  }

  @override
  String get wantUnverified => 'Not verified';

  @override
  String get wantCancel => 'Cancel';

  @override
  String get wantAdded => 'Added to your requests';

  @override
  String get wantAlreadyHere => 'They\'re already on Oiboshi';

  @override
  String get wantLimit => 'You can\'t make any more requests today';

  @override
  String get wantInvalid => 'We can\'t read this URL or ID';

  @override
  String get wantChooseService => 'Choose a platform when entering only an ID';

  @override
  String get wantFailed => 'Couldn\'t send your request';

  @override
  String get wantCancelFailed => 'Couldn\'t cancel';

  @override
  String get oshiFindWantButton => 'Request them';

  @override
  String get announceImageTitle => 'Weekly schedule image';

  @override
  String get announceImageThisWeek => 'This week';

  @override
  String get announceImageNextWeek => 'Next week';

  @override
  String get announceImageShare => 'Share image & links';

  @override
  String get announceImageNote =>
      'You can save it to Photos with \"Save Image\" in the share sheet.';

  @override
  String get announceImageShareFailed => 'Couldn\'t share the image';

  @override
  String get announceImageChangePhoto => 'Change image';

  @override
  String get announceImageResetPhoto => 'Use icon';

  @override
  String get announceImagePhotoNote =>
      'The image is cropped to the center and used in every template.';

  @override
  String get announceImageRenderFailed => 'Couldn\'t create the image';

  @override
  String get announceImageRendering => 'Creating the image';

  @override
  String get announceImagePhotoFailed => 'Couldn\'t change the image';

  @override
  String announceShareHeading(String name, String range) {
    return '$name\'s week ($range)';
  }

  @override
  String get announceShareInvite => '▼Get alerts on Oiboshi';

  @override
  String get announceShareTextLabel => 'Text shared with the image';

  @override
  String get announceShareCopy => 'Copy text';

  @override
  String get announceShareCopied => 'Text copied';

  @override
  String get announceShareInstagramNote =>
      'Instagram doesn\'t add the text to your post. Use \"Copy text\" and paste it into the caption.';

  @override
  String get announceLinkCountsLabel => 'Link clicks';

  @override
  String get announceLinkInvite => 'Oiboshi invite link';

  @override
  String announceLinkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clicks',
      one: '1 click',
    );
    return '$_temp0';
  }

  @override
  String get reachTitle => 'Reach';

  @override
  String reachLast30Days(String from, String to) {
    return 'Last 30 days ($from–$to)';
  }

  @override
  String get reachDelivered => 'Reached by notifications';

  @override
  String get reachOpened => 'Came from notifications';

  @override
  String get reachViewed => 'Viewed schedules';

  @override
  String get reachFollowers => 'Followers';

  @override
  String reachFollowChange(String change, int followed, int unfollowed) {
    return '$change in 30 days ($followed followed, $unfollowed unfollowed)';
  }

  @override
  String get reachBySubject => 'By stream & schedule';

  @override
  String get reachBySubjectEmpty =>
      'Nothing yet. Counts appear here after stream or schedule notifications are sent.';

  @override
  String get reachKindLive => 'Stream';

  @override
  String get reachKindSchedule => 'Schedule';

  @override
  String get reachDeletedSchedule => 'Deleted schedule';

  @override
  String reachCountDelivered(int count) {
    return 'Reached $count';
  }

  @override
  String reachCountOpened(int count) {
    return 'Came $count';
  }

  @override
  String reachCountViewed(int count) {
    return 'Viewed $count';
  }

  @override
  String get reachNote =>
      'Counts are updated shortly after midnight each day through the previous day. People are counted per day, and we never show who they are. Post counts record only the number of times, not who viewed. Views by your own team members are never counted.';

  @override
  String get reachPosts => 'Posts';

  @override
  String get reachPostShown => 'Times posts were shown';

  @override
  String get reachPostOpened => 'Times posts were opened';

  @override
  String get creatorLinksTitle => 'SNS links';

  @override
  String get creatorLinksLead =>
      'These appear as buttons on your creator page and share page.';

  @override
  String get creatorLinksEmpty =>
      'No links yet. Add any link and it will appear on your creator page.';

  @override
  String get creatorLinksAdd => 'Add link';

  @override
  String get creatorLinksEdit => 'Edit link';

  @override
  String creatorLinksClicks(String count) {
    return '$count taps';
  }

  @override
  String get creatorLinksShareButton => 'Share';

  @override
  String get creatorLinksEditButton => 'Edit';

  @override
  String get creatorLinksEditTitle => 'Edit links';

  @override
  String get creatorLinksPreviewOpen => 'Show the whole page';

  @override
  String creatorLinksPageAppLead(String name) {
    return 'With the Oiboshi app, get notified when $name goes live.';
  }

  @override
  String get creatorLinksPageInstall => 'Get it on the App Store';

  @override
  String get creatorLinksPageInstallNote =>
      'Open the app after installing to see this creator.';

  @override
  String get creatorLinksPageOpenApp => 'Already have the app? Open it';

  @override
  String get creatorLinksClicksLabel => 'Taps';

  @override
  String get creatorLinksClicksEmpty => 'No links yet';

  @override
  String get creatorLinksNote =>
      'Taps are the total from the app and the share page. Changing the URL resets it to 0. We never show who tapped.';

  @override
  String creatorLinksLimit(int max) {
    return 'You can add up to $max links';
  }

  @override
  String get creatorLinksTitleLabel => 'Title';

  @override
  String get creatorLinksTitleHint => 'e.g. Fan club';

  @override
  String get creatorLinksUrlLabel => 'URL';

  @override
  String get creatorLinksUrlNote =>
      'Only URLs starting with https work. Short URLs (bit.ly etc.) aren\'t allowed.';

  @override
  String get creatorLinksTitleRequired => 'Enter a title';

  @override
  String creatorLinksTitleTooLong(int max) {
    return 'Up to $max characters';
  }

  @override
  String get creatorLinksUrlInvalid => 'Enter a URL starting with https';

  @override
  String get creatorLinksShortUrl =>
      'Short URLs aren\'t allowed. Enter the destination URL itself';

  @override
  String creatorLinksDeleteTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get creatorLinksDeleteMessage => 'Its tap count will also be deleted.';

  @override
  String get creatorLinksDelete => 'Delete';

  @override
  String get creatorLinkReport => 'Report this link';

  @override
  String get creatorLinksAddShort => 'Add';

  @override
  String get creatorAdminMenuSnsNote => 'Linking & what to show';

  @override
  String get creatorAdminSnsTitle => 'SNS';

  @override
  String creatorAdminMenuReachSummary(String count) {
    return 'Notified $count people in the last 30 days';
  }

  @override
  String get creatorAdminMenuLinks => 'SNS links';

  @override
  String get creatorAdminMenuSectionShare => 'Share';

  @override
  String get shareInviteTitle => 'Invite to Oiboshi';

  @override
  String shareInviteMessage(String link) {
    return 'Follow my streams and schedule on Oiboshi!\n$link';
  }

  @override
  String get shareInviteNote =>
      'People who install Oiboshi from this link start out already following you.';

  @override
  String onboardingInviteFollowed(String name) {
    return 'You\'re now following $name';
  }
}
