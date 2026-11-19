import 'package:app_links/app_links.dart';

/// アプリを開いたリンク（Universal Link・URL スキーム）を受ける（届ける・広める仕様書 4.3.3）。
/// 状態を持たず、受けたリンクをそのまま流す。
class AppLinkService {
  AppLinkService(this._appLinks);

  final AppLinks _appLinks;

  /// アプリを開いたリンク。リンクから起動したときの、起動時のリンクも流れる。
  Stream<Uri> get links => _appLinks.uriLinkStream;
}
