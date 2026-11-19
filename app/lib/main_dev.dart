import 'bootstrap.dart';
import 'config/app_flavor.dart';

/// dev（dev 用のアプリ。dev の Supabase につなぐ）のエントリポイント。
/// `flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_defines.dev.json`
void main() => bootstrap(AppFlavor.dev);
