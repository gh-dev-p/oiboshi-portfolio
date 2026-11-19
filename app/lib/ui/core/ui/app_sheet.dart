import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// ボトムシートの枠（引き手と、下の余白）。背面は暗くする。
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.child, this.scrollable = false});

  final Widget child;

  /// 中身が長いとき、スクロールできるようにする。
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.handle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        if (scrollable)
          Flexible(child: SingleChildScrollView(child: child))
        else
          child,
        SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
      ],
    );
    return SafeArea(top: false, bottom: false, child: body);
  }
}

/// シートのタイトルの行。
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        trailing == null ? 20 : 12,
        trailing == null ? 12 : 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// シートを開く。アプリの一番上の Navigator に積み、下部ナビの前に重ねる（画面定義書 5.1.1）。
///
/// シートの中で出すスナックバーがシートに隠れないよう、シートごとに ScaffoldMessenger と透明な Scaffold を置く。
/// そのため、シートの枠（色・角の丸み）は [_SheetHost] で描き、シートの外を押したら閉じる。
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  useRootNavigator: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  shape: const RoundedRectangleBorder(),
  builder: (_) => _SheetHost(builder: builder),
);

/// シートの中身を、ScaffoldMessenger と透明な Scaffold で包む。
class _SheetHost extends StatelessWidget {
  const _SheetHost({required this.builder});

  final WidgetBuilder builder;

  /// シートの上に空けておく高さ。背の高いシートでも、スナックバーを1つ出せるようにする。
  static const _snackBarRoom = 96.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).bottomSheetTheme;
    return LayoutBuilder(
      builder: (context, constraints) => ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // キーボードの分は、シートの中身がそれぞれよける。
          resizeToAvoidBottomInset: false,
          // シートの外。押したら閉じる。
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          // シートの中身は、下の欄に置く。スナックバーは、その上（シートの上の端）に出て、シートのボタンを覆わない。
          bottomNavigationBar: GestureDetector(
            // シートの中を押しても閉じないよう、ここで受け止める。
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (constraints.maxHeight - _snackBarRoom).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Material(
                color: theme.backgroundColor,
                surfaceTintColor: theme.surfaceTintColor,
                shape: theme.shape,
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
