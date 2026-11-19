import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// 画面の下に一時的に出す通知（画面定義書 5.1.3）。下部ナビの上に重ねる。
/// 横幅いっぱいにはせず、文字の長さに合った幅で、画面の中央に出す。
/// 長い文は、画面の端から少し内側（[_screenInset]）までで折り返す。
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        width: snackBarWidth(context, message, actionLabel: actionLabel),
        // 幅を文字に合わせるので、操作（「再試行」など）は、いつも文の右に並べる。
        actionOverflowThreshold: 1,
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

/// 画面の左右の端から、通知の端までの、いちばん狭いすき間。
const double _screenInset = 15;

/// 通知の左右の余白（SnackBar の floating のもの）。
const double _horizontalPadding = 16;

/// 文字の長さに合った、通知の幅。画面の幅から左右の [_screenInset] を引いた幅を超えない。
double snackBarWidth(
  BuildContext context,
  String message, {
  String? actionLabel,
}) {
  final theme = Theme.of(context);
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  double measure(String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  final textWidth = measure(message, theme.snackBarTheme.contentTextStyle);
  // 操作は、SnackBar の中で、左右に 8 のすき間と、左右に 16 の余白のボタン（幅は 64 以上）になる。
  final actionWidth = actionLabel == null
      ? _horizontalPadding
      : _horizontalPadding +
            math.max(
              64.0,
              measure(actionLabel, theme.textTheme.labelLarge) +
                  _horizontalPadding * 2,
            );
  final maxWidth = MediaQuery.sizeOf(context).width - _screenInset * 2;
  // 割り切れない幅で折り返さないよう、少しだけ足す。
  return math.min(maxWidth, _horizontalPadding + textWidth + actionWidth + 1);
}

/// 「更新できませんでした」と「再試行」。表示済みの内容があるときの更新の失敗に使う。
void showRefreshFailedSnackBar(BuildContext context, VoidCallback onRetry) =>
    showAppSnackBar(
      context,
      AppLocalizations.of(context)!.commonRefreshFailed,
      actionLabel: AppLocalizations.of(context)!.commonRetry,
      onAction: onRetry,
    );
