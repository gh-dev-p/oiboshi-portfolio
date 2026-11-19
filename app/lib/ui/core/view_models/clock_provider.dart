import 'package:flutter_riverpod/flutter_riverpod.dart';

/// いまの時刻。テストで差し替える。
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
