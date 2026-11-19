import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:oiboshi/data/services/share/app_link_service.dart';
import 'package:oiboshi/data/services/share/clipboard_service.dart';
import 'package:oiboshi/data/services/share/share_sheet_service.dart';

/// アプリを開いたリンクの代わり。[open] で、リンクから開いたことにする。
class FakeAppLinkService implements AppLinkService {
  final _links = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => _links.stream;

  void open(String url) => _links.add(Uri.parse(url));
}

/// 共有シートの代わり。渡した文を [shared] に残す。
class FakeShareSheetService implements ShareSheetService {
  final shared = <String>[];
  var fail = false;

  @override
  Future<void> shareText(String text, {required Rect? origin}) async {
    if (fail) throw StateError('共有シートを開けない');
    shared.add(text);
  }

  /// 共有した画像のファイル名。
  final sharedImages = <String>[];

  /// 画像と一緒に渡した文。
  final sharedImageTexts = <String?>[];

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    required Rect? origin,
    String? text,
  }) async {
    if (fail) throw StateError('共有シートを開けない');
    sharedImages.add(fileName);
    sharedImageTexts.add(text);
  }
}

/// クリップボードの代わり。[text] に入れた文字を返す。[allowPaste] が偽なら、iOS の確認で「許可しない」を選んだことにする。
class FakeClipboardService implements ClipboardService {
  FakeClipboardService({this.text, this.looksLikeUrl, this.allowPaste = true});

  String? text;

  /// URL らしいか（null なら、[text] が http で始まるかで決める）。
  bool? looksLikeUrl;
  bool allowPaste;

  /// 中身を読んだ回数（iOS の確認が出る回数）。
  var reads = 0;

  @override
  Future<bool> hasProbableUrl() async =>
      looksLikeUrl ?? (text?.trim().startsWith('http') ?? false);

  @override
  Future<String?> readText() async {
    reads++;
    return allowPaste ? text : null;
  }
}
