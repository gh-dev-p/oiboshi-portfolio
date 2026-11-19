/// ユーザーごとの通知の設定。`user_settings` テーブルの1行。
class UserSettings {
  const UserSettings({this.notificationsEnabled = true});

  factory UserSettings.fromRow(Map<String, dynamic> row) => UserSettings(
    notificationsEnabled: (row['notifications_enabled'] as bool?) ?? true,
  );

  /// 配信開始の通知の、全体のスイッチ。
  final bool notificationsEnabled;
}

/// 画面モード。端末の設定に従うか、ライト・ダークのどちらか。
enum DisplayMode { system, light, dark }

/// 表示言語（機能仕様書 4.7.2）。端末の設定に従うか、日本語・英語のどちらか。
enum AppLanguage { system, ja, en }
