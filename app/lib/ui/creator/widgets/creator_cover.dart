import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/post_cards.dart';
import '../../core/ui/settings_row.dart';
import '../view_models/creator_viewmodel.dart';

/// 発信者ページのカバー画像（画面定義書 2.4.1）。
/// 自分の写真があれば、表（発信者のカバー）と裏（自分の写真）を持ち、押すと縦の軸で裏返る。
class CreatorCover extends StatefulWidget {
  const CreatorCover({
    super.key,
    required this.frontUrl,
    required this.backUrl,
    required this.showBack,
    required this.onFlip,
    required this.indicatorTop,
  });

  /// 表（発信者のカバー）。
  final String? frontUrl;

  /// 裏（自分の写真）。null なら裏返せない。
  final String? backUrl;

  /// 裏を出しているか。
  final bool showBack;

  /// 押したとき。裏返せないときは呼ばない。
  final VoidCallback onFlip;

  /// 裏返せることを示す印の、上端の位置（ステータスバーの下）。
  final double indicatorTop;

  @override
  State<CreatorCover> createState() => _CreatorCoverState();
}

class _CreatorCoverState extends State<CreatorCover>
    with SingleTickerProviderStateMixin {
  /// 0 が表、1 が裏。
  late final _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: _showsBack ? 1 : 0,
  );

  bool get _showsBack => widget.backUrl != null && widget.showBack;

  @override
  void didUpdateWidget(CreatorCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasBack = oldWidget.backUrl != null && oldWidget.showBack;
    if (_showsBack == wasBack) return;
    // 写真を選んだ・戻したときは、動かさずに切り替える。押して裏返したときだけ、動かす。
    if (widget.backUrl != oldWidget.backUrl) {
      _flip.value = _showsBack ? 1 : 0;
    } else if (_showsBack) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Widget _image(String? url) => PostThumbnail(
    url: url,
    aspectRatio: creatorCoverAspectRatio,
    iconSize: 40,
  );

  @override
  Widget build(BuildContext context) {
    final back = widget.backUrl;
    if (back == null) return _image(widget.frontUrl);
    final c = context.colors;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.creatorFlipCover,
      onTap: widget.onFlip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onFlip,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _flip,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_flip.value);
                final angle = t * math.pi;
                final backSide = angle > math.pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle),
                  // 両面とも組み立てておき、裏返す前から画像を読み込む。
                  child: IndexedStack(
                    index: backSide ? 1 : 0,
                    sizing: StackFit.expand,
                    children: [
                      _image(widget.frontUrl),
                      // 裏は、左右が反転しないように、もう半回転させて出す。
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: _image(back),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              left: 12,
              top: widget.indicatorTop,
              child: ExcludeSemantics(
                child: Container(
                  key: const ValueKey('creator-cover-flip-indicator'),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.background.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flip,
                    size: 14,
                    color: c.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// カメラのアイコンのメニュー（画面定義書 2.4.1）。「写真を選ぶ」と、自分の写真があるときは
/// 「推しが設定したカバーに戻す」を出す。選ばずに閉じたら null。
Future<CoverMenuAction?> showCoverMenu(
  BuildContext context, {
  required bool hasOwnCover,
}) => showAppSheet<CoverMenuAction>(
  context,
  builder: (context) {
    final l10n = AppLocalizations.of(context)!;
    return AppSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsRow(
            icon: Icons.photo_library_outlined,
            label: l10n.creatorCoverPickPhoto,
            showChevron: false,
            onTap: () => Navigator.of(context).pop(CoverMenuAction.pick),
          ),
          if (hasOwnCover)
            SettingsRow(
              icon: Icons.restore,
              label: l10n.creatorCoverReset,
              showChevron: false,
              onTap: () => Navigator.of(context).pop(CoverMenuAction.reset),
            ),
        ],
      ),
    );
  },
);
