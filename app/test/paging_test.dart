import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/data/services/common/paging.dart';

void main() {
  /// [total] 行あるテーブルを、範囲で読む。読んだ範囲を [calls] に残す。
  Future<List<int>> Function(int, int) table(
    int total,
    List<(int, int)> calls,
  ) => (from, to) async {
    calls.add((from, to));
    return [for (var i = from; i <= to && i < total; i++) i];
  };

  test('上限に満たなければ、1回で終わる', () async {
    final calls = <(int, int)>[];
    final rows = await fetchAllPages(table(999, calls));
    expect(rows, hasLength(999));
    expect(calls, [(0, 999)]);
  });

  test('ちょうど上限なら、続きを確かめて終わる', () async {
    final calls = <(int, int)>[];
    final rows = await fetchAllPages(table(1000, calls));
    expect(rows, hasLength(1000));
    expect(calls, [(0, 999), (1000, 1999)]);
  });

  test('上限を超えたら、続きを読んで全部つなぐ', () async {
    final calls = <(int, int)>[];
    final rows = await fetchAllPages(table(2501, calls));
    expect(rows, [for (var i = 0; i < 2501; i++) i]);
    expect(calls, [(0, 999), (1000, 1999), (2000, 2999)]);
  });
}
