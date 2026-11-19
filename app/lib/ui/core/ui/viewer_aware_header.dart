import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/playback_provider.dart';

/// 画面のヘッダーと中身を並べる（画面定義書 5.1.2）。
///
/// ふだんはヘッダーを上に固定し、中身だけをスクロールする。固定ビューアを出している間は、縦が狭いので
/// ヘッダーを固定せず、中身と一緒にスクロールして上に隠す（いちばん上まで戻すと、また見える）。
/// 固定したままにするのは、タイムスケジュールだけ（そこではこの部品を使わない）。
///
/// 中身のスクロール（[ListView] など）は、コントローラーを渡さない（primary の）ものにする。
/// 固定ビューアを出している間は、そのスクロールにヘッダーを連動させる。
class ViewerAwareHeader extends ConsumerStatefulWidget {
  const ViewerAwareHeader({
    super.key,
    required this.header,
    required this.body,
  });

  final Widget header;
  final Widget body;

  @override
  ConsumerState<ViewerAwareHeader> createState() => _ViewerAwareHeaderState();
}

class _ViewerAwareHeaderState extends ConsumerState<ViewerAwareHeader> {
  final _outer = ScrollController();
  final _nested = GlobalKey<NestedScrollViewState>();

  @override
  void dispose() {
    _outer.dispose();
    super.dispose();
  }

  /// 中身を下までスクロールしているときに固定ビューアを出したら、ヘッダーは隠れたところから始める
  /// （いちばん上に戻さない）。
  void _hideHeaderIfScrolled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inner = _nested.currentState?.innerController;
      if (inner == null || !inner.hasClients) return;
      // 中のスクロールの位置で jumpTo すると、外側（ヘッダー）をいちばん下まで送り、中の位置はそのまま残る
      // （外側の jumpTo では、中が0に戻る）。
      for (final p in inner.positions) {
        if (p.pixels > 0) {
          p.jumpTo(p.pixels);
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fixedViewerShownProvider, (previous, shown) {
      if (shown && previous != true) _hideHeaderIfScrolled();
    });
    final pinned = !ref.watch(fixedViewerShownProvider);
    // 中身は、どちらのときも同じ NestedScrollView の中に置く（キーで残す）。固定ビューアを出し入れしても、
    // 中身の状態（入力中の文字・スクロールの位置）を失わない。
    return Column(
      children: [
        if (pinned) widget.header,
        Expanded(
          key: const ValueKey('body'),
          child: NestedScrollView(
            key: _nested,
            controller: _outer,
            headerSliverBuilder: (context, _) => [
              if (!pinned) SliverToBoxAdapter(child: widget.header),
            ],
            body: widget.body,
          ),
        ),
      ],
    );
  }
}

/// 押して入る画面の [Scaffold]。ヘッダー（[ScreenAppBar] など）を [ViewerAwareHeader] で並べ、
/// 固定ビューアを出している間は、中身と一緒にスクロールして上に隠す。
/// [subheader] は、ヘッダーのすぐ下に置き、ヘッダーと一緒に扱うもの（検索フィールドなど）。
class HeaderScaffold extends StatelessWidget {
  const HeaderScaffold({
    super.key,
    required this.appBar,
    this.subheader,
    required this.body,
  });

  final PreferredSizeWidget appBar;
  final Widget? subheader;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    // [Scaffold] の appBar と同じ高さにする（上の余白は、SafeArea が受け持つ）。
    final bar = SizedBox(height: appBar.preferredSize.height, child: appBar);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ViewerAwareHeader(
          header: subheader == null
              ? bar
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [bar, ?subheader],
                ),
          body: body,
        ),
      ),
    );
  }
}
