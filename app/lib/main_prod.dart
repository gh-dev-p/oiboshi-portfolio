import 'bootstrap.dart';
import 'config/app_flavor.dart';

/// prod（App Store に出すアプリ）のエントリポイント。
/// `flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=dart_defines.prod.json`
void main() => bootstrap(AppFlavor.prod);
