import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../domain/models/post.dart';
import '../view_models/post_view_tracker.dart';

/// 投稿のカード（行）が画面に出たことを、投稿が見られた数（届ける・広める仕様書 4.2.3）に数える。
/// カードの面積の [minFraction] 以上が、続けて [dwell] 以上出たときだけ数える（速いスクロールで流れたものは数えない）。
class PostImpression extends ConsumerStatefulWidget {
  const PostImpression({super.key, required this.post, required this.child});

  final Post post;
  final Widget child;

  static const minFraction = 0.5;
  static const dwell = Duration(seconds: 1);

  @override
  ConsumerState<PostImpression> createState() => _PostImpressionState();
}

class _PostImpressionState extends ConsumerState<PostImpression> {
  final _key = UniqueKey();
  Timer? _dwell;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final tracker = ref.read(postViewTrackerProvider);
    if (info.visibleFraction >= PostImpression.minFraction &&
        !tracker.hasShown(widget.post.id)) {
      _dwell ??= Timer(PostImpression.dwell, () {
        _dwell = null;
        if (mounted) tracker.shown(widget.post);
      });
    } else {
      _dwell?.cancel();
      _dwell = null;
    }
  }

  @override
  void didUpdateWidget(PostImpression oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _dwell?.cancel();
      _dwell = null;
    }
  }

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: _key,
    onVisibilityChanged: _onVisibilityChanged,
    child: widget.child,
  );
}
