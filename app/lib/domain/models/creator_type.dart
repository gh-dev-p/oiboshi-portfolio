/// 発信者のタイプ（機能仕様書 4.6.4）。`creator_types` テーブルの1行。
/// 一覧は、運営が SQL で直す（アプリを出し直さずに変えられる）。
class CreatorType {
  const CreatorType({required this.id, required this.name, this.nameEn = ''});

  factory CreatorType.fromRow(Map<String, dynamic> row) => CreatorType(
    id: row['id'] as String,
    name: row['name'] as String,
    nameEn: (row['name_en'] as String?) ?? '',
  );

  final String id;
  final String name;

  /// 英語の名前（多言語化で使う）。
  final String nameEn;

  /// 発信者が選べる、タイプの数の上限。
  static const maxPerCreator = 3;
}
