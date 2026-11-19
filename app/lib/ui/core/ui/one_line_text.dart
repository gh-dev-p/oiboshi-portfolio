import 'package:flutter/material.dart';

/// 1行の文字。行の高さを、文字の大きさと `height` で決めた高さに固定する。
/// 名前やタイトルには絵文字が入る。絵文字の書体は上下に大きいので、そのままでは行が高くなり、
/// 高さを決めた枠からはみ出す（推しレーンの名前で起きた）。1行の文字は、`Text` ではなく、これを使う。
class OneLineText extends StatelessWidget {
  const OneLineText(
    String this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap,
  }) : textSpan = null;

  const OneLineText.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final strut = StrutStyle.fromTextStyle(effective, forceStrutHeight: true);
    final textSpan = this.textSpan;
    if (textSpan != null) {
      return Text.rich(
        textSpan,
        maxLines: 1,
        overflow: overflow,
        softWrap: softWrap,
        textAlign: textAlign,
        style: style,
        strutStyle: strut,
      );
    }
    return Text(
      data!,
      maxLines: 1,
      overflow: overflow,
      softWrap: softWrap,
      textAlign: textAlign,
      style: style,
      strutStyle: strut,
    );
  }
}
