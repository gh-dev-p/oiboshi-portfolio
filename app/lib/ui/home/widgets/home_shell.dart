import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/last_playback.dart';
import '../../../domain/models/live_notification.dart';
import '../../../domain/models/oshi.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/app_bottom_nav.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/viewer_control.dart';
import '../../core/view_models/playback_provider.dart';
import '../../core/view_models/removed_posts_provider.dart';
import '../../creator/view_models/creator_providers.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../creator/widgets/live_player_host.dart';
import '../../notification/view_models/live_notification_viewmodel.dart';
import '../../oshi/widgets/oshi_list_body.dart';
import '../../settings/widgets/settings_screen.dart';
import '../../share/view_models/share_link_viewmodel.dart';
import '../../schedule/view_models/time_schedule_viewmodel.dart';
import '../../schedule/widgets/schedule_detail_sheet.dart';
import '../../schedule/widgets/time_schedule_body.dart';
import '../view_models/home_providers.dart';
import '../view_models/home_shell_sources_viewmodel.dart';
import '../view_models/home_shell_viewmodel.dart';
import '../view_models/home_viewmodel.dart';
import 'home_body.dart';
import 'home_shell_parts.dart';
import 'home_tabs.dart';

/// ホームの枠。下部ナビで、ホーム・スケジュール・推しリスト・設定（発信者は、発信者のタブも）を切り替える（画面定義書 5.1.1）。
/// 横に払ってもタブは移らない（スケジュールの横の操作と取り違えないようにする）。
/// タブごとに画面の積み重ね（Navigator）を持ち、タブの中で開いた画面（発信者ページ、推しを探す、月のカレンダー）
/// でもナビを出したままにする。画面は、どのタブから押しても、受け持ちのタブで開く（画面定義書 5.1.8。[HomeTabs]）。ナビは画面の下に浮かび、どの画面でも、下にスクロールすると縮小し、
/// 上にスクロールすると元の大きさに戻る。
/// 配信の映像は、全部の画面の上の固定ビューアで流す（[LivePlayerHost]）。発信者ページの中では流さない。
/// 下部ナビのスイッチを入れている間は、固定ビューアに、配信中の推しの配信（いなければ推しの動画のランダム再生）を流し続ける（試作）。
/// 配信開始の通知を押したら、推しのタブに発信者ページを開き、アプリを開いているときに届いたら、スナックバーを出す（画面定義書 5.1.6）。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  /// タブの中の画面に、スナックバーを出す場所。固定ビューアから投稿ビューアを開くときに、出ているものを消す。
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final _navigators = {
    for (final t in HomeTab.values) t: GlobalKey<NavigatorState>(),
  };
  late final _routeWatchers = {
    for (final t in HomeTab.values)
      t: HomeRouteWatcher(onChanged: _onRouteChanged),
  };
  late final _pages = PageController(
    initialPage: ref.read(homeShellViewModelProvider).tab.index,
  );

  /// いま選んでいるタブの画面の context（スナックバーを出す場所）。まだ一度も出していないタブなら null。
  BuildContext? get _tabContext =>
      _navigators[ref.read(homeShellViewModelProvider).tab]!.currentContext;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      liveNotificationViewModelProvider,
      (_, event) => _onLiveNotification(event),
      fireImmediately: true,
    );
    ref.listenManual(
      pendingCreatorLinkProvider,
      (_, creatorId) => _onCreatorLink(creatorId),
      fireImmediately: true,
    );
    // 下部ナビ以外から（ホームの「ほか N 件」など）タブを選んだときも、そのタブを出す。
    ref.listenManual(homeShellViewModelProvider.select((s) => s.tab), (_, tab) {
      if (_pages.hasClients && _pages.page?.round() != tab.index) {
        _pages.jumpToPage(tab.index);
      }
      // ホームを開いたら、固定ビューアのスイッチの初めの状態を当てる（推しを0人から足したときなど）。
      if (tab == HomeTab.home) _applyViewerDefault();
    });
    // 推しが0人になったら、固定ビューアのスイッチを切る（0人のときの形に戻す。機能仕様書 4.3.5）。
    ref.listenManual(
      homeViewModelProvider.select((s) => s.value?.oshis.length),
      (previous, count) {
        if (count == 0 && (previous ?? 0) > 0) {
          ref.read(fixedViewerOnProvider.notifier).onOshisEmpty();
        }
      },
    );
    // 発信者でなくなったら（ログアウト・退会など）、発信者のタブを閉じて、ホームへ移る（画面定義書 2.2.2）。
    ref.listenManual(homeShellSourcesViewModelProvider.select((s) => s.owned), (
      _,
      owned,
    ) {
      if (owned.hasValue && owned.value == null) {
        _navigators[HomeTab.creator]!.currentState?.popUntil((r) => r.isFirst);
        if (ref.read(homeShellViewModelProvider).tab == HomeTab.creator) {
          _selectTab(HomeTab.home.index);
        }
      }
    });
    // 固定ビューアのスイッチ。入れたら流すものを選び、切ったら閉じる。
    ref.listenManual(
      fixedViewerOnProvider,
      (_, on) => on ? _fillViewer() : _closeViewer(),
    );
    ref.listenManual(playbackProvider, (_, playback) {
      if (playback != null) {
        _announceMode(playback);
        ref.read(fixedViewerEmptyProvider.notifier).set(false);
        // 固定ビューアのボタン（固定ビューアに入れる）で流し始めたら、スイッチも入れる。
        ref.read(fixedViewerOnProvider.notifier).set(true);
      } else if (ref.read(fixedViewerOnProvider)) {
        // 流していたものが終わった（配信が終わったなど）。スイッチは入れたままなので、次を選ぶ。
        _fillViewer();
      }
    });
    ref.listenManual(
      homeShellSourcesViewModelProvider.select((s) => s.liveEnded),
      (_, ended) {
        if (ended == null) return;
        _endedAt[ended.creatorId] = DateTime.now();
        _liveEndedAt = DateTime.now();
        _lastEnded = ended;
      },
    );
    // 起動したときにホームを出していれば、固定ビューアのスイッチの初めの状態を当てる。
    if (ref.read(homeShellViewModelProvider).tab == HomeTab.home) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyViewerDefault(),
      );
    }
  }

  /// 固定ビューアのスイッチの初めの状態を当てる（機能仕様書 4.3.5）。推しが1人以上で、ユーザーが切っていなければ入れる。
  /// 入れると、スイッチを見ている [_fillViewer] が流すものを選ぶ。
  Future<void> _applyViewerDefault() async {
    try {
      final home = await ref.read(homeViewModelProvider.future);
      if (!mounted) return;
      ref
          .read(fixedViewerOnProvider.notifier)
          .applyDefault(oshiCount: home.oshis.length);
    } catch (_) {
      // 推しを読めなければ、何もしない（次にホームを開いたときに、もう一度当てる）。
    }
  }

  /// 配信が終わったと分かった推しと、その時刻。ホームの推しの情報（1分ごとに読み直す）が古いうちに、
  /// 同じ配信を選び直さないよう、[_endedRecently] の間は選ばない。
  final _endedAt = <String, DateTime>{};
  static const _endedRecently = Duration(minutes: 3);

  /// 流すものを選んでいる途中か。
  bool _filling = false;

  /// スイッチを入れていて、何も流していなければ、流すものを選ぶ（機能仕様書 4.3.5）。
  /// 最後に流していたのが推しの動画なら、その動画を、その位置から流す（ランダム再生の1本目にする）。
  /// 最後に流していた配信がまだ配信中なら、その配信を流す。
  /// そうでなければ、配信中の推しがいれば、その配信を優先する。いなければ、推しの動画をランダムに流す。
  /// それもなければ、推しを探す案内を出す。
  Future<void> _fillViewer() async {
    if (_filling) return;
    _filling = true;
    try {
      await ref.read(homeViewModelProvider.future);
      if (!_needsFill) return;
      final last = ref.read(lastPlaybackProvider);
      if (last is LastVideo) {
        final resumed = await ref
            .read(homeViewModelProvider.notifier)
            .resumeVideo(last.postId, last.position);
        if (!mounted) return;
        if (!ref.read(fixedViewerOnProvider)) {
          // 読んでいる間にスイッチを切ったら、流し始めたものを閉じる。
          _closeViewer();
          return;
        }
        if (resumed || !_needsFill) return;
      }
      if (_playLive(prefer: last is LastLive ? last.creatorId : null)) return;
      final result = await ref
          .read(homeViewModelProvider.notifier)
          .startShuffle();
      if (!mounted) return;
      if (!ref.read(fixedViewerOnProvider)) {
        // 読んでいる間にスイッチを切ったら、流し始めたものを閉じる。
        _closeViewer();
      } else if (result == ShuffleStart.empty) {
        ref.read(fixedViewerEmptyProvider.notifier).set(true);
      } else if (result == ShuffleStart.failed) {
        _showLoadFailed();
      }
    } catch (_) {
      // 読めなかったときは、何も流さずに知らせる（次にスイッチを入れ直したときに、もう一度選ぶ）。
      if (mounted && ref.read(fixedViewerOnProvider)) _showLoadFailed();
    } finally {
      _filling = false;
    }
  }

  /// スイッチを入れていて、何も流していないか。
  bool get _needsFill =>
      mounted &&
      ref.read(fixedViewerOnProvider) &&
      ref.read(playbackProvider) == null;

  /// 流すものを読めなかった。帯のボタン（[_playShuffle]）と同じく「読み込めませんでした」を出す。
  void _showLoadFailed() {
    final tabContext = _tabContext;
    if (tabContext == null || !tabContext.mounted) return;
    showAppSnackBar(
      tabContext,
      AppLocalizations.of(tabContext)!.commonLoadFailedTitle,
    );
  }

  /// 配信中の推しのうち、終わったばかりでない推し（推しレーンの順）。
  List<({String creatorId, Live live, String? avatarUrl})> _playableLives() {
    final now = DateTime.now();
    _endedAt.removeWhere((_, at) => now.difference(at) > _endedRecently);
    return [
      for (final l in _lives())
        if (!_endedAt.containsKey(l.creatorId)) l,
    ];
  }

  /// 配信中の推しの配信を流す。[prefer]（最後に固定ビューアで流していた推し）がまだ配信中なら、その推しを先に。
  /// 次に、ホームの配信ビューアで出していた推し、ほかは推しレーンの順。
  /// 配信中の推しがいなければ、何もせずに偽を返す。
  bool _playLive({String? prefer}) {
    final lives = _playableLives();
    if (lives.isEmpty) return false;
    final shown = ref.read(homeLiveViewerProvider).creatorId;
    final live =
        lives.where((l) => l.creatorId == prefer).firstOrNull ??
        lives.firstWhere(
          (l) => l.creatorId == shown,
          orElse: () => lives.first,
        );
    ref
        .read(playbackProvider.notifier)
        .play(live.creatorId, live.live, avatarUrl: live.avatarUrl);
    return true;
  }

  /// 固定ビューアの帯で、推しの動画のランダム再生に切り替える（配信から、または固定ビューアのボタンで入れた動画が終わったとき）。
  /// 流せる動画がなければ、流しているものはそのままにして、知らせる。
  Future<void> _playShuffle() async {
    final result = await ref
        .read(homeViewModelProvider.notifier)
        .startShuffle();
    if (!mounted || result == ShuffleStart.started) return;
    final tabContext = _tabContext;
    if (tabContext == null || !tabContext.mounted) return;
    final l10n = AppLocalizations.of(tabContext)!;
    showAppSnackBar(
      tabContext,
      result == ShuffleStart.empty
          ? l10n.homeShuffleEmpty
          : l10n.commonLoadFailedTitle,
    );
  }

  /// 下部ナビのコントローラーで選んだ操作（はじく・長押しから選ぶ。機能仕様書 4.3.5）。
  /// 切っているときは、入れてからその操作をする。したことは、今あるスナックバーで知らせる。
  Future<void> _control(
    ViewerControl control,
    LivePlayerHostScope? host,
  ) async {
    final on = ref.read(fixedViewerOnProvider);
    final playback = ref.read(playbackProvider);
    switch (control) {
      case ViewerControl.playPause:
        // 切っているときは、入れて流す。
        if (!on || playback == null) {
          await _turnOn();
          return;
        }
        final paused = host?.togglePause();
        if (paused == null) return;
        _toast(
          (l10n) => paused ? l10n.fixedViewerPaused : l10n.fixedViewerResumed,
        );
      case ViewerControl.shuffle:
        if (playback is PostPlayback && playback.shuffle != null) {
          _resume(host);
        } else if (on) {
          // 知らせは、モードが変わったときの知らせ（[_announceMode]）に任せる。
          await _playShuffle();
        } else {
          // 切っているときは、ランダム再生で流し始める（流し始めると、スイッチも入る）。
          final result = await ref
              .read(homeViewModelProvider.notifier)
              .startShuffle();
          if (!mounted) return;
          // 固定ビューアを出し終えてから知らせる（同じ瞬間に出すと、知らせが消えるため）。
          await WidgetsBinding.instance.endOfFrame;
          _toast(
            (l10n) => switch (result) {
              ShuffleStart.started => l10n.fixedViewerModeShuffle,
              ShuffleStart.empty => l10n.homeShuffleEmpty,
              ShuffleStart.failed => l10n.commonLoadFailedTitle,
            },
          );
        }
      case ViewerControl.live:
        if (playback is LivePlayback) {
          _resume(host);
        } else if (on) {
          if (!_playLive()) _toast((l10n) => l10n.fixedViewerNoLive);
        } else if (_playLive()) {
          await WidgetsBinding.instance.endOfFrame;
          _toast((l10n) => l10n.fixedViewerModeLive);
        } else {
          // 配信中の推しがいなければ、入れて（ランダム再生で流し）、知らせる。
          await _turnOn();
          _toast((l10n) => l10n.fixedViewerNoLive);
        }
      case ViewerControl.next || ViewerControl.previous:
        final current = on && playback != null ? playback : await _turnOn();
        if (current == null || host == null) return;
        final step = control == ViewerControl.next ? 1 : -1;
        if (!host.step(step)) return;
        final live = current is LivePlayback;
        _toast(
          (l10n) => switch ((live, step > 0)) {
            (true, true) => l10n.commonLiveNext,
            (true, false) => l10n.commonLivePrevious,
            (false, true) => l10n.commonVideoNext,
            (false, false) => l10n.commonVideoPrevious,
          },
        );
    }
  }

  /// コントローラーで、いま流しているモードを選んだ。止めていれば、流し直す。
  void _resume(LivePlayerHostScope? host) {
    if (!ref.read(fixedViewerPausedProvider)) return;
    if (host?.togglePause() == false) {
      _toast((l10n) => l10n.fixedViewerResumed);
    }
  }

  /// スイッチを入れて、流し始めるのを待つ。流すものがなく、推しを探す案内を出したら null。
  /// 固定ビューアを出し終えてから返す（すぐに出す知らせが、出したときに消えないように）。
  Future<Playback?> _turnOn() async {
    final current = ref.read(playbackProvider);
    if (current != null) return current;
    if (ref.read(fixedViewerOnProvider) && ref.read(fixedViewerEmptyProvider)) {
      return null;
    }
    final done = Completer<Playback?>();
    void finish(Playback? playback) {
      if (!done.isCompleted) done.complete(playback);
    }

    final subscriptions = [
      ref.listenManual(playbackProvider, (_, playback) {
        if (playback != null) finish(playback);
      }),
      ref.listenManual(fixedViewerEmptyProvider, (_, empty) {
        if (empty) finish(null);
      }),
    ];
    ref.read(fixedViewerOnProvider.notifier).set(true);
    final playback = await done.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => null,
    );
    for (final subscription in subscriptions) {
      subscription.close();
    }
    if (!mounted) return null;
    await WidgetsBinding.instance.endOfFrame;
    return playback;
  }

  /// ホームの上に、ほかの画面（固定ビューアの下に出した投稿ビューアなど）が重なっているか。
  /// 重なっている間は、タブの中にスナックバーを出さない（隠れて見えないうえ、閉じるときの画面の切り替えで、
  /// 残してあるタブの画面のスナックバーと重なってしまうため）。
  bool get _covered => !(ModalRoute.of(context)?.isCurrent ?? true);

  /// タブの中に、スナックバーで知らせる。
  void _toast(String Function(AppLocalizations l10n) message) {
    if (!mounted || _covered) return;
    final tabContext = _tabContext;
    if (tabContext == null || !tabContext.mounted) return;
    showAppSnackBar(tabContext, message(AppLocalizations.of(tabContext)!));
  }

  /// 固定ビューアで最後に流していたモード。変わったら知らせる。スイッチを切ると忘れる。
  _ViewerMode? _lastMode;

  /// 流していた配信が終わったと分かった時刻。続けてランダム再生に移ったら、知らせを1つにまとめる。
  DateTime? _liveEndedAt;

  /// 最後に終わったと分かった配信の知らせ。
  LiveEnded? _lastEnded;

  /// 「配信が終わりました。動画シャッフルモードに切り替えました」で知らせた、配信の終わり。同じ終わりの
  /// 「配信が終わりました」は出さない（次を選ぶほうが、終わりの知らせより先に済むことがあるため）。
  /// 終わりごとに見分けるので、次の配信の終わりは、また知らせる。
  LiveEnded? _combinedFor;

  /// 配信モードとランダム再生（動画シャッフルモード）が切り替わったら、何を流しているか分かるように知らせる。
  /// スイッチを入れて流し始めたときと、投稿ビューアから入れた動画では知らせない。
  void _announceMode(Playback playback) {
    final mode = switch (playback) {
      LivePlayback() => _ViewerMode.live,
      PostPlayback(shuffle: _?) => _ViewerMode.shuffle,
      PostPlayback() => _ViewerMode.post,
    };
    if (mode == _lastMode) return;
    final first = _lastMode == null;
    _lastMode = mode;
    // スイッチを入れて流し始めたときは、モードを覚えるだけにする。
    if (first || mode == _ViewerMode.post) return;
    final endedAt = _liveEndedAt;
    _liveEndedAt = null;
    final justEnded =
        endedAt != null &&
        DateTime.now().difference(endedAt) < const Duration(seconds: 30);
    final tabContext = _tabContext;
    if (tabContext == null || _covered) return;
    final l10n = AppLocalizations.of(tabContext)!;
    if (mode == _ViewerMode.shuffle && justEnded) {
      _combinedFor = _lastEnded;
      // 「配信が終わりました」を同じ瞬間に出していると、隠しきれずに順番待ちになるので、待っているものごと消す。
      ScaffoldMessenger.maybeOf(tabContext)?.clearSnackBars();
    }
    showAppSnackBar(tabContext, switch (mode) {
      _ViewerMode.live => l10n.fixedViewerModeLive,
      _ when justEnded => l10n.fixedViewerLiveEndedShuffle,
      _ => l10n.fixedViewerModeShuffle,
    });
  }

  /// スイッチを切った。流しているものを閉じる。配信なら、ホームの埋め込みビューアに、その推しを出す。
  void _closeViewer() {
    _lastMode = null;
    ref.read(fixedViewerPausedProvider.notifier).set(false);
    ref.read(fixedViewerEmptyProvider.notifier).set(false);
    final playback = ref.read(playbackProvider);
    if (playback is LivePlayback) {
      ref.read(homeLiveViewerProvider.notifier).restore(playback.creatorId);
    } else {
      ref.read(playbackProvider.notifier).close();
    }
  }

  /// プッシュ通知を受けた。押して開いたなら、ホームの上に重ねた画面（シート・ダイアログ・タブの中のメニューも）を閉じて、
  /// 通知の先を開く（[_openNotice]）。アプリを開いているときに届いたなら、スナックバーを出す。
  void _onLiveNotification(LiveNotificationEvent? event) {
    if (event == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(liveNotificationViewModelProvider.notifier).consume();
      final notification = event.notification;
      if (event.opened) {
        _closeOverlays();
        _openNotice(notification);
        return;
      }
      // タブの中の ScaffoldMessenger に出す（下部ナビの上に重なる）。
      final tabContext = _tabContext;
      if (tabContext == null) return;
      final title = notification.title;
      final l10n = AppLocalizations.of(tabContext)!;
      final fallback = notification.scheduleId != null
          ? l10n.homeScheduleNoticeFallback
          : notification.wantArrival
          ? l10n.homeWantArrivalFallback
          : l10n.homeLiveStartedFallback;
      showAppSnackBar(
        tabContext,
        title.isEmpty ? fallback : title,
        actionLabel: l10n.homeLiveStartedOpen,
        onAction: () => _openNotice(notification),
      );
    });
  }

  /// 通知の先を開く。配信開始の通知と追いたいの人の登録の通知（届ける・広める仕様書 4.5.2）なら、発信者ページ。
  /// 予定の事前通知なら、その予定の詳細（4.1.1）。
  /// 予定が消えていれば（読めなければ）、発信者ページを開く。
  Future<void> _openNotice(LiveNotification notification) async {
    final scheduleId = notification.scheduleId;
    final creatorId = notification.creatorId;
    if (scheduleId == null) return _openCreator(creatorId);
    final loaded = await ref
        .read(liveNotificationViewModelProvider.notifier)
        .loadSchedule(creatorId, scheduleId);
    if (!mounted) return;
    final item = loaded?.item;
    final tabContext = _tabContext;
    if (loaded == null ||
        item == null ||
        tabContext == null ||
        !tabContext.mounted) {
      return _openCreator(creatorId);
    }
    await showScheduleDetailSheet(
      tabContext,
      item: item,
      creator: loaded.creator,
    );
  }

  /// 共有のリンクで開いた（届ける・広める仕様書 4.3.3）。通知を押したときと同じく、上に重ねた画面を閉じて、
  /// 推しのタブで発信者ページを開く。発信者がない・ファンに見せない状態なら、ホームで知らせる。
  void _onCreatorLink(String? creatorId) {
    if (creatorId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(pendingCreatorLinkProvider.notifier).consume();
      final ok = await ref
          .read(shareLinkViewModelProvider.notifier)
          .canOpen(creatorId);
      if (!mounted) return;
      if (!ok) {
        _selectTab(HomeTab.home.index);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final tabContext = _tabContext;
          if (tabContext == null || !tabContext.mounted) return;
          showAppSnackBar(
            tabContext,
            AppLocalizations.of(tabContext)!.shareLinkNotFound,
          );
        });
        return;
      }
      _closeOverlays();
      _openCreator(creatorId);
    });
  }

  /// ホームの上に重ねた画面（シート・ダイアログ・タブの中のメニューも）を閉じる。タブの中の画面は残す。
  void _closeOverlays() {
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    for (final navigator in _navigators.values) {
      navigator.currentState?.popUntil((r) => r is! PopupRoute);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _setNavCollapsed(bool collapsed) {
    // 画面の移り変わりの途中（ビルド中）に呼ばれることがあるので、次のフレームで反映する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(homeShellViewModelProvider.notifier)
            .setNavCollapsed(collapsed);
      }
    });
  }

  /// タブの中で画面を開いた・戻ったときは、元の大きさに戻す。いちばん上の画面も変わるので、作り直す。
  void _onRouteChanged() {
    _setNavCollapsed(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// どの画面でも、下にスクロールすると縮小し、上にスクロールするか、いちばん上まで戻ると元の大きさに戻す。
  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    switch (n.direction) {
      case ScrollDirection.reverse:
        _setNavCollapsed(true);
      case ScrollDirection.forward:
        _setNavCollapsed(false);
      case ScrollDirection.idle:
        if (n.metrics.pixels <= n.metrics.minScrollExtent) {
          _setNavCollapsed(false);
        }
    }
    return false;
  }

  void _selectTab(int i) {
    final tab = HomeTab.values[i];
    final same = ref.read(homeShellViewModelProvider.notifier).selectTab(tab);
    // 同じタブをもう一度押したら、そのタブの最初の画面に戻る。
    // ホームの最初の画面にいるときは、いちばん上までスクロールする。
    // スケジュールは、今日に戻して、今の時刻を真ん中へ移す（画面定義書（スケジュール）2.1.1）。
    if (same) {
      final navigator = _navigators[tab]!.currentState;
      if (tab == HomeTab.home && !(navigator?.canPop() ?? false)) {
        ref.read(homeScrollToTopProvider.notifier).request();
      }
      // スケジュールは、上に開いた画面を閉じたうえで、今日の今の時刻を表の真ん中へ移す。
      if (tab == HomeTab.schedule) {
        ref.read(scheduleScrollToNowProvider.notifier).request();
      }
      navigator?.popUntil((r) => r.isFirst);
    } else {
      _pages.jumpToPage(i);
    }
  }

  /// [tab] のタブを最初の画面に戻してから出す（タブの中で開いた画面を閉じる）。
  void _showTabRoot(HomeTab tab) {
    _navigators[tab]!.currentState?.popUntil((r) => r.isFirst);
    ref.read(homeShellViewModelProvider.notifier).selectTab(tab);
  }

  /// 推しのタブに、その発信者のページを開く。
  /// 固定ビューアを押したとき、配信開始の通知を受けたときに使う。
  Future<void> _openCreator(String creatorId) =>
      _open(null, HomeTab.oshi, CreatorScreen.route(creatorId));

  /// [tab] のタブで [route] を開く（画面定義書 5.1.8）。[from] がそのタブの Navigator なら、いまの画面の上に重ねる。
  /// ほかのタブ（タブの外）からなら、そのタブへ移り、最初の画面まで戻してから開く。
  /// いちばん上に同じ画面（名前が同じ）が出ていれば、タブを移るだけにする。
  Future<void> _open(NavigatorState? from, HomeTab tab, Route<void> route) {
    final navigator = _navigators[tab]!.currentState;
    if (navigator != null && navigator == from) return navigator.push(route);
    ref.read(homeShellViewModelProvider.notifier).selectTab(tab);
    if (navigator == null) {
      // まだ一度も出していないタブは、移ってから作られるので、次のフレームで開く。
      final opened = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final created = _navigators[tab]!.currentState;
        if (created == null) {
          opened.complete();
        } else {
          created.push(route).whenComplete(opened.complete);
        }
      });
      return opened.future;
    }
    final name = route.settings.name;
    if (name != null && _routeWatchers[tab]!.top?.settings.name == name) {
      return Future.value();
    }
    // 途中の画面を、閉じる動きを見せずに先に外し、最初の画面の上に、開く画面だけを横から出す。
    // （pushAndRemoveUntil では、開き終わるまで、外した画面が後ろに見える。）
    final watcher = _routeWatchers[tab]!;
    for (
      var top = watcher.top;
      top != null && !top.isFirst;
      top = watcher.top
    ) {
      navigator.removeRoute(top);
    }
    return navigator.push(route);
  }

  /// 固定ビューアで流していた配信が終わって、固定ビューアを閉じた（画面定義書 2.4.3）。いま見ているタブに、スナックバーを出す。
  void _showLiveEnded(LiveEnded ended) {
    if (identical(_combinedFor, ended)) return;
    final tabContext = _tabContext;
    if (tabContext == null) return;
    showAppSnackBar(
      tabContext,
      AppLocalizations.of(tabContext)!.fixedViewerLiveEnded,
    );
  }

  /// 配信中の推しの配信（ホームの推しレーンと同じ順）。
  List<({String creatorId, Live live, String? avatarUrl})> _lives() {
    final now = DateTime.now();
    return [
      for (final oshi
          in ref.read(homeViewModelProvider).value?.oshis ?? const <Oshi>[])
        if (oshi.creator.liveAt(now) case final live?)
          (creatorId: oshi.id, live: live, avatarUrl: oshi.creator.avatarUrl),
    ];
  }

  /// その発信者の前後の、配信中の推しの配信（ホームの推しレーンと同じ順。終わったばかりの配信は除く）。固定ビューアの帯を払って切り替えるのに使う。
  /// 端の次は、反対の端に戻る（周回する）。配信中の推しが1人だけなら null。
  ({String creatorId, Live live, String? avatarUrl})? _liveBeside(
    String creatorId,
    int step,
  ) {
    final lives = _playableLives();
    final i = lives.indexWhere((l) => l.creatorId == creatorId);
    if (i < 0 || lives.length < 2) return null;
    return lives[(i + step) % lives.length];
  }

  /// その発信者が、配信中の推しの何人目か（[_liveBeside] と同じ順）。固定ビューアの帯の点に使う。
  /// 配信中の推しにいなければ null。
  ({int index, int count})? _livePosition(String creatorId) {
    final lives = _playableLives();
    final i = lives.indexWhere((l) => l.creatorId == creatorId);
    return i < 0 ? null : (index: i, count: lives.length);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeShellViewModelProvider);
    final removed = ref.watch(removedPostsProvider);
    final owned = ref
        .watch(homeShellSourcesViewModelProvider.select((s) => s.owned))
        .value;
    // キーボードを出している間は、ナビをキーボードの後ろに残し（Instagram と同じ）、ナビのぶんの余白も取らない。
    // キーボードを避けるのは、タブの中の画面の Scaffold だけにする（ここでも避けると、2回縮む）。
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final reserved = keyboardOpen
        ? 0.0
        : AppBottomNav.reservedHeightOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: HomeTabs(
        current: state.tab,
        onOpen: _open,
        onShowRoot: _showTabRoot,
        child: LivePlayerHost(
          onOpen: _openCreator,
          onLiveEnded: _showLiveEnded,
          liveBeside: _liveBeside,
          livePosition: _livePosition,
          hasLive: () => _playableLives().isNotEmpty,
          onPlayLive: () => _playLive(),
          onPlayShuffle: _playShuffle,
          onOpenPostViewer: () =>
              _messenger.currentState?.removeCurrentSnackBar(),
          child: Stack(
            children: [
              // タブの中の画面は、ナビのぶんだけ下に余白を取る。中身はナビの後ろまで流れる。
              // 縮小しても余白は変えない（中身がずれないように）。
              Positioned.fill(
                child: ScaffoldMessenger(
                  key: _messenger,
                  // 固定ビューアが、上の余白を変える（LivePlayerHost）ので、その内側の値を使う。
                  child: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        padding: MediaQuery.paddingOf(
                          context,
                        ).copyWith(bottom: reserved),
                        viewPadding: MediaQuery.viewPaddingOf(
                          context,
                        ).copyWith(bottom: reserved),
                      ),
                      child: NotificationListener<UserScrollNotification>(
                        onNotification: _onScroll,
                        // Android の戻るは、いま見ているタブの画面を1つ戻す。
                        child: NavigatorPopHandler(
                          onPopWithResult: (_) =>
                              _navigators[state.tab]!.currentState?.maybePop(),
                          child: PageView(
                            controller: _pages,
                            // 隣のタブも先に作っておき、移ったときに読み込みを待たせない。
                            allowImplicitScrolling: true,
                            // 横に払ってもタブは移らない。下部ナビで移る。
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (final tab in HomeTab.values)
                                HomeKeepAlive(
                                  child: HomeTabScope(
                                    tab: tab,
                                    child: Navigator(
                                      key: _navigators[tab],
                                      observers: [_routeWatchers[tab]!],
                                      onGenerateRoute: (_) => MaterialPageRoute(
                                        builder: (_) => switch (tab) {
                                          HomeTab.home => const HomeBody(),
                                          HomeTab.schedule =>
                                            const TimeScheduleBody(),
                                          HomeTab.oshi => const OshiListBody(),
                                          HomeTab.settings =>
                                            const SettingsScreen(),
                                          HomeTab.creator => HomeCreatorTab(
                                            onOpenSettings: () => _selectTab(
                                              HomeTab.settings.index,
                                            ),
                                          ),
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: AppBottomNav.bottomGapOf(context),
                child: Center(
                  // コントローラーの前後の切り替え・停止は、固定ビューア（[LivePlayerHost]）に頼む。
                  child: Builder(
                    builder: (navContext) => AppBottomNav(
                      currentIndex: state.tab.index,
                      collapsed: state.navCollapsed,
                      onTap: _selectTab,
                      viewer: (
                        on: ref.watch(fixedViewerOnProvider),
                        paused: ref.watch(fixedViewerPausedProvider),
                        // 推しの誰かが配信中なら、コントローラーに赤い点を出す（ホームの「LIVE」と同じ情報）。
                        live: ref.watch(
                          homeViewModelProvider.select(
                            (s) => anyOshiLive(s.value?.oshis, DateTime.now()),
                          ),
                        ),
                        // 推しに新しい動画があれば、動画シャッフルに点を出す（ホームの「NEW」と同じ決め方）。
                        newVideo: ref.watch(
                          homeViewModelProvider.select(
                            (s) => anyNewShuffleVideo(
                              s.value?.oshis,
                              s.value?.posts,
                              removed,
                              DateTime.now(),
                            ),
                          ),
                        ),
                        onTap: () {
                          final viewer = ref.read(
                            fixedViewerOnProvider.notifier,
                          );
                          viewer.set(!ref.read(fixedViewerOnProvider));
                        },
                        onControl: (control) => _control(
                          control,
                          LivePlayerHostScope.of(navContext),
                        ),
                        // 動画シャッフルのとき、左右に引っ張ったまま止めると、早送り・巻き戻し（機能仕様書 4.3.5）。
                        seek: (
                          start: (direction) =>
                              LivePlayerHostScope.of(
                                navContext,
                              )?.seekStart(direction) ??
                              false,
                          direction: (direction) => LivePlayerHostScope.of(
                            navContext,
                          )?.seekDirection(direction),
                          end: () =>
                              LivePlayerHostScope.of(navContext)?.seekEnd(),
                        ),
                      ),
                      creator: owned == null
                          ? null
                          : (
                              avatarUrl: owned.avatarUrl,
                              selected: state.tab == HomeTab.creator,
                              onTap: () => _selectTab(HomeTab.creator.index),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 推しの誰かが、[now] に配信中か（ホームの「LIVE」と同じ判定）。
bool anyOshiLive(List<Oshi>? oshis, DateTime now) =>
    oshis?.any((o) => o.creator.liveAt(now) != null) ?? false;

/// 推しに、新しい動画があるか（機能仕様書 4.3.5）。動画シャッフルに入る動画（YouTube の動画。生配信の枠と、
/// 追星から消した投稿を除く）のうち、ホームの「NEW」と同じ決め方（[Follow.isNew]。最後に見てから、
/// 3日以内に投稿された）で新しいものがあれば真。見るのは、ホームの全体タイムラインに読んだ投稿。
bool anyNewShuffleVideo(
  List<Oshi>? oshis,
  List<Post>? posts,
  Set<String> removed,
  DateTime now,
) {
  if (oshis == null || posts == null) return false;
  final follows = {for (final o in oshis) o.id: o.follow};
  return posts.any((p) {
    final follow = follows[p.creatorId];
    return follow != null &&
        p.source == SnsService.youtube &&
        p.kind == PostKind.video &&
        !p.isLiveContent &&
        !removed.contains(p.id) &&
        !p.postedAt.isAfter(now) &&
        follow.isNew(p.postedAt, now: now);
  });
}

/// 固定ビューアで流しているもの。配信モード、ランダム再生（動画シャッフルモード）、投稿ビューアから入れた動画。
enum _ViewerMode { live, shuffle, post }
