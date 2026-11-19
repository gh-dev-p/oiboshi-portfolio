import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../utils/open_url.dart';
import '../themes/app_colors.dart';

/// 本文の中の URL を、リンクの色で出し、押すと外部で開く文（機能仕様書 4.4.3）。
/// 長い URL は、`https://` を省き、途中で切って出す。
/// `https://` のない URL（`youtu.be/…` の形）もリンクにする。途中で切れた URL（`…` で終わる）は、
/// 元の URL が分からないので、押すと [fallbackUrl]（投稿そのもの）を開く。
class LinkText extends StatefulWidget {
  const LinkText(
    this.text, {
    super.key,
    this.style,
    this.linkColor,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fallbackUrl,
    this.xEntities = false,
  });

  final String text;
  final TextStyle? style;

  /// リンクの色。指定がなければ、テーマの primary。
  final Color? linkColor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// 途中で切れた URL を押したときに開く URL。null なら、切れた URL はリンクにしない。
  final Uri? fallbackUrl;

  /// X の投稿なら真。@ユーザー名を X のプロフィールに、#ハッシュタグを X の検索に結ぶ（X の表示の決まり）。
  final bool xEntities;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
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
    final linkStyle = TextStyle(color: widget.linkColor ?? context.colors.link);
    final spans = <InlineSpan>[];
    final parts = splitLinks(widget.text);
    for (final part in widget.xEntities ? splitXEntities(parts) : parts) {
      final url = part.truncated ? widget.fallbackUrl : part.url;
      if (url == null) {
        spans.add(TextSpan(text: part.text));
        continue;
      }
      final recognizer = TapGestureRecognizer()..onTap = () => openUrl(url);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: part.truncated || part.entity
              ? part.text
              : shortenUrl(part.text),
          style: linkStyle,
          recognizer: recognizer,
        ),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// 文の一部。URL なら [url] を持つ。
/// [truncated] は、途中で `…` で切れた URL（X が見せる形のまま保存された古い投稿）。[url] は当てにならない。
/// [entity] は、X の @ユーザー名・#ハッシュタグ（文のまま出す）。
typedef TextPart = ({String text, Uri? url, bool truncated, bool entity});

/// `https://` のある URL か、ない URL（ドメインのあとに `/` が続くもの、`youtu.be/x`・`example.com/a`）。
/// メールアドレスや、URL の途中から拾わないように、直前が英数字・`@`・`.`・`/` のときは拾わない。
final _urlPattern = RegExp(
  r'https?://[^\s<>"「」『』（）、。]+'
  r'|(?<![\w@./-])(?:[a-z0-9-]+\.)+[a-z]{2,}/[^\s<>"「」『』（）、。]*',
  caseSensitive: false,
);

/// 末尾につきやすい記号（文の句読点や閉じかっこ）は、URL に含めない。
final _trailing = RegExp(r'[.,!?:;)\]}…]+$');

/// 文を、URL とそれ以外に分ける。
List<TextPart> splitLinks(String text) {
  final parts = <TextPart>[];
  var start = 0;
  for (final match in _urlPattern.allMatches(text)) {
    final matched = match.group(0)!;
    final hasScheme = matched.toLowerCase().startsWith(RegExp('https?://'));
    // `https://` のない形で `…` で終わるものは、X が見せる形のまま切れた URL。`…` まで含めて1つにする。
    final truncated = !hasScheme && matched.endsWith('…');
    final raw = truncated ? matched : matched.replaceFirst(_trailing, '');
    final url = Uri.tryParse(hasScheme ? raw : 'https://$raw');
    if (url == null || url.host.isEmpty) continue;
    if (match.start > start) {
      parts.add((
        text: text.substring(start, match.start),
        url: null,
        truncated: false,
        entity: false,
      ));
    }
    parts.add((text: raw, url: url, truncated: truncated, entity: false));
    start = match.start + raw.length;
  }
  if (start < text.length) {
    parts.add((
      text: text.substring(start),
      url: null,
      truncated: false,
      entity: false,
    ));
  }
  return parts;
}

/// X の @ユーザー名（英数字・`_` の1〜15文字）と、#ハッシュタグ。直前が英数字などのときは拾わない（メールアドレスや URL の中）。
final _xEntityPattern = RegExp(
  r'(?<![\w@#&/])@(\w{1,15})(?!\w)|(?<![\w#&/])[#＃]([\p{L}\p{N}_]+)',
  unicode: true,
);

/// URL 以外の部分から、X の @ユーザー名と #ハッシュタグを分け出す。
/// @ユーザー名は X のプロフィールへ、#ハッシュタグは X の検索へ結ぶ（X の表示の決まり。tech-risks.md 2.21）。
List<TextPart> splitXEntities(List<TextPart> parts) {
  final result = <TextPart>[];
  for (final part in parts) {
    if (part.url != null || part.truncated) {
      result.add(part);
      continue;
    }
    final text = part.text;
    var start = 0;
    for (final match in _xEntityPattern.allMatches(text)) {
      if (match.start > start) {
        result.add((
          text: text.substring(start, match.start),
          url: null,
          truncated: false,
          entity: false,
        ));
      }
      final user = match.group(1);
      final url = user != null
          ? Uri.https('x.com', '/$user')
          : Uri.https('x.com', '/search', {'q': '#${match.group(2)}'});
      result.add((
        text: match.group(0)!,
        url: url,
        truncated: false,
        entity: true,
      ));
      start = match.end;
    }
    if (start < text.length) {
      result.add((
        text: text.substring(start),
        url: null,
        truncated: false,
        entity: false,
      ));
    }
  }
  return result;
}

/// 見せる形の URL。`https://`・`www.` を省き、長ければ途中で切る。
String shortenUrl(String url, {int max = 30}) {
  final shown = url.replaceFirst(RegExp(r'^https?://(www\.)?'), '');
  return shown.length <= max ? shown : '${shown.substring(0, max - 1)}…';
}
