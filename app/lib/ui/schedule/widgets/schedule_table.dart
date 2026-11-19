import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/post.dart';
import '../../../domain/models/schedule_filter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/time_schedule_viewmodel.dart';
import 'schedule_detail_panel.dart';
import 'time_grid.dart';
import 'time_grid_labels.dart';
import 'schedule_table_parts.dart';

/// 列ヘッダー（推しのアイコン）の高さ。アイコン30に、上12（週ストリップとの間）、下4。
const _columnHeaderHeight = 46.0;

/// 「終日」の帯の高さ。
const _allDayHeight = 30.0;

/// 時間軸の上端と下端の帯の高さ。これ以上スクロールできないことを、見て分かるようにする。
const _edgeHeight = ScheduleEdgeBand.height;

/// 1時間の高さの上限。
const _maxHourHeight = 160.0;

/// ダブルタップで拡大したときの、1時間の高さ。
const _zoomedHourHeight = 74.286;

/// 1画面に並べる推しの数（横の、いちばん縮小したときと、いちばん拡大したとき）。
const _widePerScreen = 5.0;
const _narrowPerScreen = 3.0;

/// 列ヘッダー・「終日」の帯・時間軸。
/// 縦（1時間の高さ）も横（1画面の人数）も、ピンチで途切れなく変える（画面定義書 2.1.1）。
class ScheduleTable extends StatefulWidget {
  const ScheduleTable({
    super.key,
    required this.data,
    required this.filter,
    required this.now,
    required this.scrollToNow,
    this.centerNow,
    this.floating,
    this.fitToScreenBottom = false,
  });

  final TimeScheduleData data;
  final ScheduleFilter filter;
  final DateTime now;

  /// 変わるたびに、現在時刻の位置へ移る。
  final Listenable scrollToNow;

  /// 変わるたびに、現在時刻を表の見えている部分の真ん中へ移す（下部ナビのスケジュールをもう一度押したとき）。
  final Listenable? centerNow;

  /// 表の右下に浮かせるもの（固定ビューアを出している間の、年月の帯のボタン）。
  /// 下部ナビのぶんより上に置く。詳細のパネルを開いているときは、パネルの後ろに隠す。
  final Widget? floating;

  /// 24時間を1画面に収める高さ（初めの高さ）を、24:00 の線が画面のいちばん下の端（下部ナビの後ろ）に来る高さにするか。
  /// 固定ビューアを出している間（表が狭いので、ナビと重なってもよいから大きく出す。2026-11-19 本人）。
  /// false なら、24:00 の線と下の端の帯が、下部ナビより上に収まる高さ。
  final bool fitToScreenBottom;

  @override
  State<ScheduleTable> createState() => _ScheduleTableState();
}

/// 浮かせるものの、表の右と下からの間。
const _floatingMargin = 12.0;

/// ピンチで、どちらの向きを変えているか。
enum _PinchAxis { undecided, vertical, horizontal }

class _ScheduleTableState extends State<ScheduleTable> with _PinchZoom {
  @override
  final _gridHorizontal = ScrollController();
  final _headerHorizontal = ScrollController();
  @override
  final _vertical = ScrollController();

  /// 直前のビルドの、表の時間軸の見えている高さ（選んだ要素へ移るときに使う）。
  double _lastGridViewportHeight = 1;

  /// 詳細のパネルで選んでいる要素（画面定義書 2.1.3）。null なら、パネルを閉じている。
  ScheduleFocus? _focus;

  /// 詳細のパネルの高さ（下部ナビのぶんの余白を含む）。表の高さから決める。
  double _panelHeight = 0;

  /// 直前のビルドの、下部ナビのぶんの高さ。
  double _reserve = 0;

  /// 直前のビルドの、表の列（詳細のパネルを左右に送るのに使う）。
  List<ScheduleTableEntry> _lastEntries = const [];

  /// 詳細のパネルを送った向き（1：次へ、-1：前へ、0：要素を押して開いた）。中身の替わり方に使う。
  int _swipeDirection = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollToNow.addListener(_scrollToNowPosition);
    widget.centerNow?.addListener(_centerNowPosition);
    // 列ヘッダーと「終日」の帯は、表の横のスクロールについていく。
    _gridHorizontal.addListener(() {
      if (_headerHorizontal.hasClients &&
          _headerHorizontal.offset != _gridHorizontal.offset) {
        _headerHorizontal.jumpTo(_gridHorizontal.offset);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 日を切り替えたら、詳細のパネルを閉じる。
    if (!isSameDay(oldWidget.data.day, widget.data.day)) _focus = null;
    if (oldWidget.scrollToNow != widget.scrollToNow) {
      oldWidget.scrollToNow.removeListener(_scrollToNowPosition);
      widget.scrollToNow.addListener(_scrollToNowPosition);
    }
    if (oldWidget.centerNow != widget.centerNow) {
      oldWidget.centerNow?.removeListener(_centerNowPosition);
      widget.centerNow?.addListener(_centerNowPosition);
    }
  }

  @override
  void dispose() {
    widget.scrollToNow.removeListener(_scrollToNowPosition);
    widget.centerNow?.removeListener(_centerNowPosition);
    _gridHorizontal.dispose();
    _headerHorizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  /// 現在時刻の位置へ移る（表の見えている部分の、上から3分の1あたり）。
  void _scrollToNowPosition() => _moveToNow(1 / 3);

  /// 現在時刻を、表の見えている部分の真ん中へ移す。はみ出すとき（0時・24時ごろ）は、端で止める。
  void _centerNowPosition() => _moveToNow(1 / 2);

  /// 現在時刻を、表の見えている部分（下部ナビより上）の、上から [fraction] の位置へ移す。
  /// 24時間を1画面に収めているときは、縦を拡大してから移る。
  void _moveToNow(double fraction) {
    final now = DateTime.now();
    if (!isSameDay(widget.data.day, now)) return;
    final fit = _lastHourHeight <= _fitHourHeight + 0.5;
    if (fit) setState(() => _hourHeight = _zoomedHourHeight);
    final hourHeight = fit ? _zoomedHourHeight : _lastHourHeight;
    final hours = now.hour + now.minute / 60;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_vertical.hasClients) return;
      final p = _vertical.position;
      // 選んだ要素の詳細のパネルを開いていれば、パネルより上を見えている部分とする。
      final visible = _focus == null
          ? _lastGridViewportHeight
          : _lastGridViewportHeight - math.max(0, _panelHeight - _reserve);
      final target = hours * hourHeight + _edgeHeight - visible * fraction;
      _vertical.animateTo(
        target.clamp(p.minScrollExtent, p.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// 詳細のパネルに、表の要素を出す。パネルの高さは決まっているので、次のフレームで要素の時刻をパネルに隠れない位置へ移す。
  void _select(ScheduleFocus focus) {
    setState(() {
      _focus = focus;
      _swipeDirection = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
  }

  /// 詳細のパネルを、表の上の次（[delta] が 1）か前（-1）の要素へ送る（画面定義書（スケジュール）2.1.3）。
  /// 同じ推しの中を時刻の順に移り、端まで来たら隣の推しへ。全体の端では送らない。
  void _step(int delta) {
    final current = _focus;
    if (current == null) return;
    final order = scheduleFocusOrder(_lastEntries);
    final index = order.indexWhere((o) => o.focus.key == current.key);
    final next = index + delta;
    if (index < 0 || next < 0 || next >= order.length) return;
    setState(() {
      _focus = order[next].focus;
      _swipeDirection = delta;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFocus();
      _scrollToColumn(order[next].column);
    });
  }

  /// [column] 番目の列が、横に見えていなければ、見える位置まで横にスクロールする。
  void _scrollToColumn(int column) {
    if (!mounted || !_gridHorizontal.hasClients) return;
    final p = _gridHorizontal.position;
    final left = column * _lastColumnWidth;
    final right = left + _lastColumnWidth;
    final double target;
    if (left < p.pixels) {
      target = left;
    } else if (right > p.pixels + p.viewportDimension) {
      target = right - p.viewportDimension;
    } else {
      return;
    }
    _gridHorizontal.animateTo(
      target.clamp(p.minScrollExtent, p.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _closeFocus() => setState(() => _focus = null);

  /// 選んだ要素の時刻を、表の見えている部分（パネルより上）の、上から3割あたりに移す。
  void _scrollToFocus() {
    final time = _focus?.time;
    if (!mounted || time == null || !_vertical.hasClients) return;
    final visible =
        _lastGridViewportHeight - math.max(0, _panelHeight - _reserve);
    final y =
        _edgeHeight + TimeGrid.offsetOf(time, widget.data.day, _lastHourHeight);
    final p = _vertical.position;
    _vertical.animateTo(
      (y - visible * 0.3).clamp(p.minScrollExtent, p.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  /// 選んでいる要素を、読み直したデータから探し直す。なくなっていれば、パネルを閉じる。
  ScheduleFocus? _resolveFocus(List<ScheduleTableEntry> entries) {
    final current = _focus;
    if (current == null) return null;
    for (final e in entries) {
      final creator = e.oshi.creator;
      for (final b in e.column.blocks) {
        if (b.key == current.key) return BlockFocus(b, creator);
      }
      for (final cl in e.column.clusters) {
        if (cl.key == current.key) return ClusterFocus(cl, creator);
      }
      for (final item in e.allDay) {
        final focus = AllDayFocus(item, creator);
        if (focus.key == current.key) return focus;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focus == current) _closeFocus();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    // 選んだ日ではなく、データの日で並べる。日を切り替えて読み込むあいだ、前の日の予定が 0:00 に寄らないようにする。
    final day = data.day;
    final now = widget.now;
    final isToday = isSameDay(day, now);
    final allDay = data.schedules.where((s) => s.allDay).toList();
    final (:entries, :isEmpty) = scheduleTableEntries(
      data,
      allDay: allDay,
      filter: widget.filter,
      now: now,
    );
    final focus = _resolveFocus(entries);
    _lastEntries = entries;
    final reserve = MediaQuery.paddingOf(context).bottom;
    _reserve = reserve;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 表と詳細のパネルは、ほかの画面と同じく、画面のいちばん下（下部ナビの後ろ）まで伸ばす。
        // 24時間を収める高さや、見えている部分は、下部ナビのぶんを除いた高さで決める。
        final tableHeight = constraints.maxHeight - reserve;
        // パネルの高さは、表の高さだけで決め、中身では変えない（ちらつかないように）。
        _panelHeight = tableHeight * 0.45 + reserve;
        // 表の下の端の余白。下部ナビ（パネルを開いていれば、パネル）のぶんを足して、
        // 24:00 の線と最後の予定が、ナビやパネルより上に来るまでスクロールできるようにする。
        final bottomInset = focus == null ? reserve : _panelHeight;
        final gridWidthAvailable = constraints.maxWidth - TimeGrid.labelWidth;
        final perScreen = entries.isEmpty
            ? 1.0
            : math.min(entries.length.toDouble(), _perScreen);
        final columnWidth = gridWidthAvailable / perScreen;
        final gridWidth = columnWidth * entries.length;
        final headerHeight =
            _columnHeaderHeight + (allDay.isEmpty ? 0 : _allDayHeight);
        final gridViewportHeight = tableHeight - headerHeight;
        _lastGridViewportHeight = gridViewportHeight;
        // 固定ビューアを出している間は、0:00 の線を表の上の端の帯のすぐ下に、24:00 の線を画面の下の端に置く。
        final fitSpan = widget.fitToScreenBottom
            ? gridViewportHeight + reserve - _edgeHeight
            : gridViewportHeight - _edgeHeight * 2;
        _fitHourHeight = (fitSpan / 24).clamp(1.0, _maxHourHeight);
        final hourHeight = (_hourHeight ?? _fitHourHeight).clamp(
          _fitHourHeight,
          _maxHourHeight,
        );
        _lastHourHeight = hourHeight;
        _lastColumnWidth = columnWidth;
        _lastPerScreen = perScreen;
        _lastGridWidthAvailable = gridWidthAvailable;
        _lastEntryCount = entries.length;
        _lastHeaderHeight = headerHeight;
        final expanded =
            hourHeight >= TimeGrid.compactHourHeight && columnWidth >= 90;
        final table = Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerEnd,
          onPointerCancel: _onPointerEnd,
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onDoubleTap: _toggleZoom,
            // 表の何もないところを押すと、詳細のパネルを閉じる。
            onTap: focus == null ? null : _closeFocus,
            child: Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: TimeGrid.labelWidth,
                        child: Column(
                          children: [
                            const SizedBox(height: _columnHeaderHeight),
                            if (allDay.isNotEmpty)
                              SizedBox(
                                height: _allDayHeight,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      l10n.commonAllDay,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: c.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _headerHorizontal,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            width: gridWidth,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: _columnHeaderHeight,
                                  child: Row(
                                    children: [
                                      for (final e in entries)
                                        SizedBox(
                                          width: columnWidth,
                                          child: ScheduleColumnHeader(
                                            oshi: e.oshi,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (allDay.isNotEmpty)
                                  SizedBox(
                                    height: _allDayHeight,
                                    child: Row(
                                      children: [
                                        for (final e in entries)
                                          SizedBox(
                                            width: columnWidth,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                    vertical: 4,
                                                  ),
                                              child: ScheduleAllDayPills(
                                                items: e.allDay,
                                                expanded: expanded,
                                                selectedKey: focus?.key,
                                                onTap: (s) => _select(
                                                  AllDayFocus(
                                                    s,
                                                    e.oshi.creator,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _vertical,
                    // 端まで来たら跳ね返して、これ以上スクロールできないことを伝える。
                    physics: _pinching
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: _edgeHeight,
                          ),
                          child: TimeGridLabels(
                            hourHeight: hourHeight,
                            now: isToday ? now : null,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _gridHorizontal,
                            scrollDirection: Axis.horizontal,
                            physics: _pinching
                                ? const NeverScrollableScrollPhysics()
                                : const ClampingScrollPhysics(),
                            child: SizedBox(
                              width: gridWidth,
                              child: Column(
                                children: [
                                  const ScheduleEdgeBand(top: true),
                                  TimeGrid(
                                    hourHeight: hourHeight,
                                    columnWidth: columnWidth,
                                    expanded: expanded,
                                    day: day,
                                    now: now,
                                    columns: [
                                      for (final e in entries) e.column,
                                    ],
                                    onBlockTap: (block, creator) =>
                                        _select(BlockFocus(block, creator)),
                                    onClusterTap: (cluster, creator) =>
                                        _select(ClusterFocus(cluster, creator)),
                                    selectedKey: focus?.key,
                                    // 配信中の配信は予定になくてもブロックで出すので、ブロックも投稿も終日の予定もないときだけ出す。
                                    emptyHint: isEmpty,
                                  ),
                                  const ScheduleEdgeBand(top: false),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return Stack(
          children: [
            table,
            // 浮かせるものは、詳細のパネルの後ろに置き、パネルを開いている間は隠す
            // （パネルが低いと、後ろに置くだけでは上がはみ出して見えるため、出さない）。
            if (widget.floating case final floating? when focus == null)
              Positioned(
                right: _floatingMargin,
                bottom: reserve + _floatingMargin,
                child: floating,
              ),
            if (focus != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ScheduleDetailPanel(
                  focus: focus,
                  postsOf: (creator) => sortNewestFirst(
                    widget.data.posts.where((p) => p.creatorId == creator.id),
                  ),
                  height: _panelHeight,
                  bottomPadding: reserve,
                  swipeDirection: _swipeDirection,
                  onStep: _step,
                  onClose: _closeFocus,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 表の拡大・縮小。縦（1時間の高さ）と横（1画面の人数）のピンチと、ダブルタップの切り替え。
mixin _PinchZoom on State<ScheduleTable> {
  ScrollController get _gridHorizontal;
  ScrollController get _vertical;

  /// 1時間の高さ。null なら、24時間を1画面に収める。
  double? _hourHeight;

  /// 1画面に並べる推しの数。小数も取る（列の幅を途切れなく変える）。
  double _perScreen = _widePerScreen;

  // ピンチの途中の値。
  /// 画面に触れている指の位置。2本以上のあいだは、スクロールを止めてピンチに渡す。
  final _pointers = <int, Offset>{};
  var _pinchAxis = _PinchAxis.undecided;
  double _pinchStartHour = 0;
  double _pinchStartOffset = 0;
  double _pinchFocalY = 0;
  double _pinchStartPerScreen = _widePerScreen;
  double _pinchStartColumnWidth = 1;
  double _pinchStartHorizontalOffset = 0;
  double _pinchFocalX = 0;

  // 直前のビルドの寸法（ピンチの計算に使う）。
  double _fitHourHeight = 1;
  double _lastHourHeight = 1;
  double _lastColumnWidth = 1;
  double _lastPerScreen = _widePerScreen;
  double _lastGridWidthAvailable = 1;
  int _lastEntryCount = 0;
  double _lastHeaderHeight = _columnHeaderHeight;

  bool get _pinching => _pointers.length >= 2;

  void _onPointerDown(PointerDownEvent e) {
    final was = _pinching;
    _pointers[e.pointer] = e.localPosition;
    if (was != _pinching) setState(() {});
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_pointers.containsKey(e.pointer)) {
      _pointers[e.pointer] = e.localPosition;
    }
  }

  void _onPointerEnd(PointerEvent e) {
    final was = _pinching;
    _pointers.remove(e.pointer);
    if (was != _pinching) setState(() {});
  }

  bool get _zoomed =>
      _perScreen < _widePerScreen - 0.01 ||
      (_hourHeight != null && _hourHeight! > _fitHourHeight + 0.5);

  void _onScaleStart(ScaleStartDetails d) {
    _pinchAxis = _PinchAxis.undecided;
    _pinchStartHour = _lastHourHeight;
    _pinchStartOffset = _vertical.hasClients ? _vertical.offset : 0;
    _pinchFocalY = d.localFocalPoint.dy - _lastHeaderHeight;
    _pinchStartPerScreen = _lastPerScreen;
    _pinchStartColumnWidth = _lastColumnWidth;
    _pinchStartHorizontalOffset = _gridHorizontal.hasClients
        ? _gridHorizontal.offset
        : 0;
    _pinchFocalX = d.localFocalPoint.dx - TimeGrid.labelWidth;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount < 2) return;
    if (_pinchAxis == _PinchAxis.undecided) {
      // 2本の指の並びで決める（横に並べたら横、縦に並べたら縦）。ピンチを離すまで変えない。
      // 指の動きの大きさで決めると、斜めのピンチが縦に取られやすく、横を変えにくい。
      if (_pointers.length < 2) return;
      final fingers = _pointers.values.take(2).toList();
      final span = fingers[0] - fingers[1];
      _pinchAxis = span.dx.abs() >= span.dy.abs()
          ? _PinchAxis.horizontal
          : _PinchAxis.vertical;
    }
    if (_pinchAxis == _PinchAxis.horizontal) {
      _updatePerScreen(d.horizontalScale);
      return;
    }
    final next = (_pinchStartHour * d.verticalScale).clamp(
      _fitHourHeight,
      _maxHourHeight,
    );
    if (next == _lastHourHeight) return;
    // 指の間の時刻を、画面の同じ位置に保つ。
    final content = _pinchStartOffset + _pinchFocalY - _edgeHeight;
    final target =
        content / _pinchStartHour * next + _edgeHeight - _pinchFocalY;
    setState(() => _hourHeight = next);
    _jumpVerticalAfterLayout(target);
  }

  /// 横のピンチ。指を開くほど、1画面の人数を減らして列を広げる。
  void _updatePerScreen(double scale) {
    final count = _lastEntryCount.toDouble();
    if (count <= 1) return;
    final next = (_pinchStartPerScreen / scale)
        .clamp(
          math.min(_narrowPerScreen, count),
          math.min(_widePerScreen, count),
        )
        .toDouble();
    if ((next - _lastPerScreen).abs() < 0.001) return;
    // 指の間の列を、画面の同じ位置に保つ。
    final width = _lastGridWidthAvailable / next;
    final content = _pinchStartHorizontalOffset + _pinchFocalX;
    final target = content / _pinchStartColumnWidth * width - _pinchFocalX;
    setState(() => _perScreen = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gridHorizontal.hasClients) return;
      final p = _gridHorizontal.position;
      _gridHorizontal.jumpTo(target.clamp(0.0, p.maxScrollExtent));
    });
  }

  /// ダブルタップで、最初の表示と、拡大した表示を切り替える。
  void _toggleZoom() {
    if (_zoomed) {
      setState(() {
        _hourHeight = null;
        _perScreen = _widePerScreen;
      });
      _jumpVerticalAfterLayout(0);
      return;
    }
    setState(() {
      _hourHeight = _zoomedHourHeight;
      _perScreen = _narrowPerScreen;
    });
    // 今日は、今の3時間前から。ほかの日は、配信の多い夕方から。
    final now = widget.now;
    final hour = isSameDay(widget.data.day, now) ? now.hour - 3 : 17;
    _jumpVerticalAfterLayout(hour * _zoomedHourHeight + _edgeHeight);
  }

  void _jumpVerticalAfterLayout(double target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_vertical.hasClients) return;
      final p = _vertical.position;
      _vertical.jumpTo(target.clamp(p.minScrollExtent, p.maxScrollExtent));
    });
  }
}
