/// ビルドの Flavor（環境構成 1・10）。dev は dev 用のアプリ（`com.example.oiboshi.dev`）で、
/// dev の Supabase につなぐ。prod は App Store に出すアプリ（`com.example.oiboshi`）で、本番につなぐ。
enum AppFlavor {
  dev,
  prod;

  /// 今のアプリの Flavor。エントリポイント（`main_dev.dart`・`main_prod.dart`）が起動のはじめに決める。
  /// テストでは prod のまま。
  static AppFlavor current = AppFlavor.prod;
}

/// 本番の Supabase の URL。Flavor と接続先の取り違え（dev のアプリから本番へ、本番のアプリから dev へ）を、
/// 起動時に止めるために使う（[flavorMismatch]）。
const prodSupabaseUrl = 'https://{本番の参照ID}.supabase.co';

/// [flavor] のアプリが [supabaseUrl] につないでよいか。だめなら理由を返す。
String? flavorMismatch(AppFlavor flavor, String supabaseUrl) {
  final isProdUrl = supabaseUrl == prodSupabaseUrl;
  return switch (flavor) {
    AppFlavor.prod when !isProdUrl =>
      'prod のアプリが本番以外（$supabaseUrl）につなごうとしています。'
          'dart_defines.prod.json を確かめてください。',
    AppFlavor.dev when isProdUrl =>
      'dev のアプリが本番の Supabase につなごうとしています。'
          'dart_defines.dev.json を確かめてください。',
    _ => null,
  };
}
