import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import 'external_link_dialog.dart';

/// 文の一部を、押すと規約などの公開ページを開くリンクにした文（画面定義書 2.1.1・2.2.1）。
/// [parts] は、文と URL の組の並び。URL が null の部分は、ふつうの文。開けなければ、スナックバーで知らせる。
class LegalLinkText extends StatefulWidget {
  const LegalLinkText(this.parts, {super.key, this.style, this.textAlign});

  final List<(String, String?)> parts;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<LegalLinkText> createState() => _LegalLinkTextState();
}

class _LegalLinkTextState extends State<LegalLinkText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final linkStyle = TextStyle(color: context.colors.link);
    final spans = <InlineSpan>[];
    for (final (text, url) in widget.parts) {
      if (url == null) {
        spans.add(TextSpan(text: text));
        continue;
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => openPageOrNotify(context, url);
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: text, style: linkStyle, recognizer: recognizer));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
