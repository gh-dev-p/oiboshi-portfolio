import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../themes/app_colors.dart';
import 'glass_surface.dart';
import 'oshi_avatar.dart';
import 'viewer_control.dart';

/// 下部ナビ（画面定義書 5.1.1）。iOS の「写真」の下部メニューに合わせる。文字は出さず、アイコンだけ。
/// 左から、切り離した丸を2つと、3つのタブをまとめた楕円を置く（2026-11-17 本人）。
/// 発信者でなければ「ホーム・コントローラー（固定ビューアのスイッチ。[viewer]）・楕円（スケジュール・推しリスト・設定）」。
/// 発信者は「自分のアイコン（[creator]）・コントローラー・楕円（ホーム・スケジュール・推しリスト）」で、
/// 設定は発信者メニューから開く。
/// 選択中は主色の塗りのアイコンに、薄い灰色の楕円を敷く。ほかは線のアイコン。
/// 楕円と丸は、透明度の高いすりガラス。下にスクロールすると縮小する（[collapsed]）。
/// 縮小しても、楕円は3つのタブのまま小さくし、丸と楕円をまとめて中央に並べる。
///
/// 大きさと位置は、iPhone 18 Pro のシミュレーターの「写真」を、ピクセル単位で測った値（1pt = 3px）。
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.collapsed = false,
    this.creator,
    this.viewer,
  });

  /// 選んでいる、4つのタブ（ホーム・スケジュール・推しリスト・設定）の番号。
  /// 発信者のタブを選んでいるときは、4つのどれでもない番号。
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 発信者のタブ。発信者でなければ null（丸を出さない）。
  final ({String? avatarUrl, bool selected, VoidCallback onTap})? creator;

  /// 固定ビューアのスイッチ（コントローラー）。入れているか（[on]）、止めているか（[paused]）、
  /// 推しの誰かが配信中か（[live]。コントローラーのアイコンの左上と、触れて出るヒントの上左の配信のアイコンの右上に赤い点を出す）、
  /// 推しに新しい動画があるか（[newVideo]。コントローラーのアイコンの右上と、上右の動画シャッフルのアイコンの右上に、NEW の色の点を出す）、
  /// 押したとき（[onTap]。出し消し）と、はじいて操作を選んだとき（[onControl]。機能仕様書 4.3.5）、
  /// 左右に引っ張ったまま止めたとき（[seek]。動画シャッフルの早送り・巻き戻し。null なら、しない）。
  /// null なら、丸を出さない。
  final ({
    bool on,
    bool paused,
    bool live,
    bool newVideo,
    VoidCallback onTap,
    ValueChanged<ViewerControl> onControl,
    ViewerSeekControl? seek,
  })?
  viewer;

  /// 縮小しているか。
  final bool collapsed;

  /// 下にスクロールしたときに、縮小ではなく、完全に隠すか。隠さないと決めた（決定事項 5）。
  static const hideOnScrollDown = false;

  /// 楕円と丸の高さ（元の大きさ：190px、縮小したとき：146px）。
  static const height = 63.0;
  static const _collapsedHeight = 48.67;

  /// 元の大きさで、画面の左右の端からの距離（61px）。
  static const _sideGutter = 20.33;

  /// 縮小したとき、元の大きさより、下端から離す距離（下端から 61px → 84px）。丸の中心の高さは、ほぼ変わらない。
  static const _collapsedLift = 7.67;

  /// 楕円の中の、1つのタブの幅（「写真」の2つのタブの楕円 582px から割った値）。
  static const _tabWidth = 92.33;

  /// 楕円の内側の余白（選んだタブの灰色の楕円まで。14px）。
  static const _pillInset = 4.67;

  /// 丸と楕円のすき間（「写真」の 40px）。
  static const _gap = 13.33;

  /// 端末の下の余白がない端末で、画面の下端から楕円までの距離。
  static const _minBottomGap = 12.0;

  /// 画面の下端から、楕円の下端までの距離（「写真」の 61px）。
  static double bottomGapOf(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return inset > 0 ? _sideGutter : _minBottomGap;
  }

  /// タブの中の画面が、下に取る余白（楕円と、その上のすき間）。縮小しても変えない（中身がずれないように）。
  static double reservedHeightOf(BuildContext context) =>
      bottomGapOf(context) + height + 8;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  /// 4つのタブ（ホーム・スケジュール・推しリスト・設定）のアイコン。番号は、タブの番号。
  static const _tabs = [
    (icon: Icons.home_outlined, selected: Icons.home),
    (icon: Icons.schedule_outlined, selected: Icons.schedule),
    (icon: Icons.star_outline, selected: Icons.star),
    (icon: Icons.settings_outlined, selected: Icons.settings),
  ];

  /// 楕円に入れるタブの数。
  static const _pillCount = 3;

  /// コントローラーに指が触れているか。している間は、ほかのメニューを隠す。
  bool _holding = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    // 読み上げの名前（[_tabs] と同じ順）。
    final labels = [
      l10n.commonTabHome,
      l10n.commonTabSchedule,
      l10n.commonTabOshiList,
      l10n.commonTabSettings,
    ];
    final collapsed = widget.collapsed;
    final hidden = collapsed && AppBottomNav.hideOnScrollDown;
    final creator = widget.creator;
    final viewer = widget.viewer;
    // 発信者は、楕円にホーム・スケジュール・推しリスト（設定は発信者メニューから開く）。
    // 発信者でなければ、ホームを左端の丸にし、楕円にスケジュール・推しリスト・設定。
    final pillTabs = creator == null ? const [1, 2, 3] : const [0, 1, 2];
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: hidden ? const Offset(0, 2) : Offset.zero,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: collapsed && !hidden ? 1 : 0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          // 縮小するときは、楕円も丸も、同じ割合で小さくする。
          final scale = lerpDouble(
            1,
            AppBottomNav._collapsedHeight / AppBottomNav.height,
            t,
          )!;
          final h = AppBottomNav.height * scale;
          final screenWidth = MediaQuery.sizeOf(context).width;
          const side = AppBottomNav._sideGutter;
          const gap = AppBottomNav._gap;
          // 楕円の左に置く丸（発信者のアイコンかホーム、コントローラーの順）。
          final circles = 1 + (viewer == null ? 0 : 1);
          // 楕円は、元の大きさでは3つのタブの幅。丸と楕円が画面の幅に収まらなければ、楕円を縮める。
          final room =
              screenWidth - side * 2 - (AppBottomNav.height + gap) * circles;
          final fullWidth =
              (AppBottomNav._tabWidth * _pillCount +
                      AppBottomNav._pillInset * 2)
                  .clamp(0.0, room);
          final pillWidth = fullWidth * scale;
          // 元の大きさでは、丸を画面の左の端から並べる。縮小すると、丸と楕円をまとめて中央に並べる。
          final groupWidth = (h + gap) * circles + pillWidth;
          final groupLeft = (screenWidth - groupWidth) / 2;
          // [i] 番目の丸の位置。
          double leftOf(int i) => lerpDouble(
            side + (AppBottomNav.height + gap) * i,
            groupLeft + (h + gap) * i,
            t,
          )!;
          Widget tabIcon(int tab, double size) {
            final selected = tab == widget.currentIndex;
            return Icon(
              selected ? _tabs[tab].selected : _tabs[tab].icon,
              size: size,
              color: selected ? c.primary : c.textPrimary,
            );
          }

          final pill = GlassSurface(
            width: pillWidth,
            height: h,
            child: Padding(
              padding: EdgeInsets.all(AppBottomNav._pillInset * scale),
              child: Row(
                // 選んだタブの灰色の楕円を、上下いっぱいに広げる。
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final tab in pillTabs)
                    Expanded(
                      child: _PillTab(
                        selected: tab == widget.currentIndex,
                        label: labels[tab],
                        onTap: () => widget.onTap(tab),
                        child: tabIcon(tab, _PillTab.fullIconSize * scale),
                      ),
                    ),
                ],
              ),
            ),
          );
          // 触れている間は、コントローラー以外を隠す。
          Widget hideWhileHolding(Widget child) => IgnorePointer(
            ignoring: _holding,
            child: ExcludeSemantics(
              excluding: _holding,
              child: AnimatedOpacity(
                opacity: _holding ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: child,
              ),
            ),
          );
          return Padding(
            padding: EdgeInsets.only(bottom: AppBottomNav._collapsedLift * t),
            child: SizedBox(
              width: screenWidth,
              height: h,
              child: Stack(
                // 触れている間のヒントは、下部ナビの上にはみ出して出す。
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: leftOf(0),
                    top: 0,
                    child: hideWhileHolding(
                      creator != null
                          ? _GlassCircle(
                              size: h,
                              selected: creator.selected,
                              label: l10n.commonCreatorMenu,
                              onTap: creator.onTap,
                              // 選択中は、アイコンを主色の輪で囲む。
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: creator.selected
                                        ? c.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: AvatarImage(
                                  url: creator.avatarUrl,
                                  size: h - 16 * scale,
                                ),
                              ),
                            )
                          : _GlassCircle(
                              size: h,
                              selected: widget.currentIndex == 0,
                              label: labels[0],
                              onTap: () => widget.onTap(0),
                              child: tabIcon(0, 26 * scale),
                            ),
                    ),
                  ),
                  if (viewer != null)
                    Positioned(
                      left: leftOf(1),
                      top: 0,
                      child: _ViewerController(
                        size: h,
                        scale: scale,
                        viewer: viewer,
                        onHoldChanged: (holding) =>
                            setState(() => _holding = holding),
                      ),
                    ),
                  Positioned(
                    left: leftOf(circles),
                    top: 0,
                    child: hideWhileHolding(pill),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 下部ナビのコントローラー（固定ビューアのスイッチ。機能仕様書 4.3.5）。
/// 押すと、固定ビューアの出し消し。はじくと、向き（[ViewerControlDirection]）の操作をする。
/// はじいている間は、アイコンが指について動き、操作が決まる所まで来ると振動する。離すと元に戻る。
/// 指が触れたらすぐ、触れている間だけ、アイコンの周りに5つの向きのヒントを出す（ほかのメニューは隠す）。
/// 動画シャッフルのときは、右・左に引っ張ったまま止めると、早送り・巻き戻し（[ViewerSeek]）。離すと、そこから再生する。
class _ViewerController extends StatefulWidget {
  const _ViewerController({
    required this.size,
    required this.scale,
    required this.viewer,
    required this.onHoldChanged,
  });

  final double size;
  final double scale;
  final ({
    bool on,
    bool paused,
    bool live,
    bool newVideo,
    VoidCallback onTap,
    ValueChanged<ViewerControl> onControl,
    ViewerSeekControl? seek,
  })
  viewer;
  final ValueChanged<bool> onHoldChanged;

  /// アイコンが指について動ける距離。操作が決まる距離より少し先まで。
  static const _maxTravel = ViewerControlDirection.threshold + 10;

  /// ヒントの丸の大きさと、コントローラーの真ん中からの距離。
  static const _hintSize = 44.0;
  static const _hintDistance = 72.0;

  /// 配信中の赤い点・新しい動画の点の大きさ（コントローラーのアイコンと、触れて出るヒントのアイコン）。
  static const _liveDotSize = 8.0;

  @override
  State<_ViewerController> createState() => _ViewerControllerState();
}

class _ViewerControllerState extends State<_ViewerController>
    with SingleTickerProviderStateMixin {
  /// 押した所からの指の動き。
  Offset _drag = Offset.zero;

  /// アイコンを動かしている量（離したら、元に戻す）。
  Offset _icon = Offset.zero;
  Offset _iconFrom = Offset.zero;

  /// いま決まっている操作。
  ViewerControl? _selected;

  /// 触れている指（ヒントを出している間）。最初の1本だけを見る。
  int? _pointer;

  /// 右・左に決まってから、引っ張ったまま止めたかを待つタイマー（[ViewerSeek.holdDelay]）。
  Timer? _holdTimer;

  /// 早送り・巻き戻しをしているか。している間は、離しても次・前にしない。
  bool _seeking = false;

  late final AnimationController _back =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
      )..addListener(
        () => setState(
          () => _icon =
              _iconFrom * (1 - Curves.easeOutCubic.transform(_back.value)),
        ),
      );

  @override
  void dispose() {
    _holdTimer?.cancel();
    if (_seeking) widget.viewer.seek?.end();
    _back.dispose();
    super.dispose();
  }

  void _start() {
    _back.stop();
    _holdTimer?.cancel();
    _seeking = false;
    _drag = Offset.zero;
    _selected = null;
  }

  /// 右は早送り（1）、左は巻き戻し（-1）、ほかは 0。
  static int _seekDirectionOf(ViewerControl? control) => switch (control) {
    ViewerControl.next => 1,
    ViewerControl.previous => -1,
    _ => 0,
  };

  /// 右・左に決まったまま [ViewerSeek.holdDelay] たった。始められれば、早送り・巻き戻しにする。
  void _hold() {
    final direction = _seekDirectionOf(_selected);
    final seek = widget.viewer.seek;
    if (direction == 0 || seek == null || !seek.start(direction)) return;
    _seeking = true;
    HapticFeedback.mediumImpact();
  }

  void _move(Offset drag) {
    final selected = ViewerControlDirection.of(drag);
    // 操作が決まる所まで来た（向きが変わった）ら、振動する。
    if (selected != null && selected != _selected) {
      HapticFeedback.selectionClick();
    }
    if (_seeking) {
      widget.viewer.seek?.direction(_seekDirectionOf(selected));
    } else if (selected != _selected) {
      // 右・左に決まったら、引っ張ったまま止めるかを待つ。ほかの向きに変わったら、待つのをやめる。
      _holdTimer?.cancel();
      if (_seekDirectionOf(selected) != 0 && widget.viewer.seek != null) {
        _holdTimer = Timer(ViewerSeek.holdDelay, _hold);
      }
    }
    final travel = drag.distance > _ViewerController._maxTravel
        ? drag / drag.distance * _ViewerController._maxTravel
        : drag;
    setState(() {
      _drag = drag;
      _icon = travel;
      _selected = selected;
    });
  }

  void _end({required bool perform}) {
    final selected = _selected;
    final seeking = _seeking;
    _holdTimer?.cancel();
    _seeking = false;
    _selected = null;
    _drag = Offset.zero;
    _iconFrom = _icon;
    _back.forward(from: 0);
    // 早送り・巻き戻しをしていたら、そこから再生する（次・前にはしない）。
    if (seeking) {
      widget.viewer.seek?.end();
      return;
    }
    if (perform && selected != null) widget.viewer.onControl(selected);
  }

  void _touch(PointerDownEvent event) {
    if (_pointer != null) return;
    setState(() => _pointer = event.pointer);
    widget.onHoldChanged(true);
  }

  void _release(PointerEvent event) {
    if (event.pointer != _pointer) return;
    setState(() => _pointer = null);
    widget.onHoldChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final viewer = widget.viewer;
    final size = widget.size;
    // アイコンは、丸の外まで指について動けるよう、すりガラスの丸（はみ出しを切る）の上に重ねる。
    final circle = _GlassCircle(
      size: size,
      selected: viewer.on,
      label: l10n.commonFixedViewer,
      onTap: viewer.onTap,
      child: const SizedBox.expand(),
    );
    final icon = Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Transform.translate(
            offset: _icon,
            // 配信中の推しがいれば左上（配信のヒントの向き）に赤い点、
            // 新しい動画があれば右上（動画シャッフルのヒントの向き）に NEW の色の点を付ける。
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  viewer.on
                      ? Icons.smart_display
                      : Icons.smart_display_outlined,
                  size: 26 * widget.scale,
                  color: viewer.on || _selected != null
                      ? c.primary
                      : c.textPrimary,
                ),
                if (viewer.live)
                  Positioned(
                    key: const ValueKey('controller-live-dot'),
                    top: -1,
                    left: -2,
                    child: _dot(c.live),
                  ),
                if (viewer.newVideo)
                  Positioned(
                    key: const ValueKey('controller-new-dot'),
                    top: -1,
                    right: -2,
                    child: _dot(c.accentNavy),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    // 触れたことは、押す・はじくの判定とは別に受け取る（判定を待たずに、すぐヒントを出すため）。
    return Listener(
      onPointerDown: _touch,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: GestureDetector(
        // 動いた距離は、指を置いた所から数える（動き出したと分かるまでの量も含める）。
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (_) => _start(),
        onPanUpdate: (d) => _move(_drag + d.delta),
        onPanEnd: (_) => _end(perform: true),
        onPanCancel: () => _end(perform: false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            circle,
            icon,
            if (_pointer != null)
              for (final control in ViewerControl.values)
                _hint(
                  control,
                  size,
                  playing: viewer.on && !viewer.paused,
                  live: viewer.live,
                  newVideo: viewer.newVideo,
                ),
          ],
        ),
      ),
    );
  }

  /// 配信中の赤い点・新しい動画の点（コントローラーのアイコンと、触れて出るヒントのアイコンに付ける）。
  Widget _dot(Color color) => Container(
    width: _ViewerController._liveDotSize,
    height: _ViewerController._liveDotSize,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  /// 触れている間の、1つの向きのヒント。いま決まっている向きは、主色にする。
  /// 推しの誰かが配信中なら（[live]）、配信のヒントのアイコンの右上に赤い点を付ける。
  /// 推しに新しい動画があれば（[newVideo]）、動画シャッフルのヒントのアイコンの右上に、NEW の色の点を付ける。
  Widget _hint(
    ViewerControl control,
    double size, {
    required bool playing,
    required bool live,
    required bool newVideo,
  }) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final radians = ViewerControlDirection.angleOf(control) * math.pi / 180;
    const hint = _ViewerController._hintSize;
    const distance = _ViewerController._hintDistance;
    final center = Offset(
      size / 2 + math.sin(radians) * distance,
      size / 2 - math.cos(radians) * distance,
    );
    final (icon, label) = switch (control) {
      ViewerControl.playPause =>
        playing
            ? (Icons.pause, l10n.fixedViewerControlPause)
            : (Icons.play_arrow, l10n.fixedViewerControlPlay),
      ViewerControl.shuffle => (
        Icons.video_library,
        l10n.fixedViewerShufflePlay,
      ),
      ViewerControl.live => (Icons.sensors, l10n.commonFixedViewerPlayLive),
      ViewerControl.next => (Icons.chevron_right, l10n.fixedViewerControlNext),
      ViewerControl.previous => (
        Icons.chevron_left,
        l10n.fixedViewerControlPrevious,
      ),
    };
    final selected = control == _selected;
    final (dotKey, dotColor) = switch (control) {
      ViewerControl.live when live => ('viewer-live-dot', c.live),
      ViewerControl.shuffle when newVideo => ('viewer-new-dot', c.accentNavy),
      _ => (null, null),
    };
    return Positioned(
      left: center.dx - hint / 2,
      top: center.dy - hint / 2,
      child: IgnorePointer(
        child: Semantics(
          label: label,
          child: GlassSurface(
            width: hint,
            height: hint,
            // 丸いっぱいに広げず、アイコンの大きさにして真ん中に置く（点をアイコンの右上に付けるため）。
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: selected ? c.primary : c.textPrimary,
                  ),
                  // 配信中の推しがいれば配信のアイコンに赤い点（ライブの色）、
                  // 新しい動画があれば動画シャッフルのアイコンに、ホームの「NEW」の色の点を出す。
                  if (dotKey != null)
                    Positioned(
                      key: ValueKey(dotKey),
                      top: -1,
                      right: -2,
                      child: _dot(dotColor!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 楕円の中の、1つのタブ。選んだタブは、後ろに薄い灰色の楕円を敷く（「写真」と同じ。白の上で 253 → 233 の濃さ）。
class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  /// 元の大きさのアイコン。「写真」のタブのアイコン（85px）と同じ大きさに見えるように。
  static const fullIconSize = 30.0;

  final bool selected;
  final String label;
  final VoidCallback onTap;

  /// タブのアイコン。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: selected
                ? c.textPrimary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 楕円から切り離した、すりガラスの丸（発信者のタブ・設定）。
class _GlassCircle extends StatelessWidget {
  const _GlassCircle({
    required this.size,
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final double size;
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      width: size,
      height: size,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );
  }
}
