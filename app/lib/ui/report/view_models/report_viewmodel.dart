import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/report.dart';

/// 通報（シート）の入力。
class ReportFormState {
  const ReportFormState({this.reason, this.detail = ''});

  /// 選んだ理由。選ぶまで null。
  final ReportReason? reason;

  /// 詳しい内容（任意）。
  final String detail;

  /// 「送信」を押せるか。理由を選ぶまで押せない。
  bool get canSubmit => reason != null;

  ReportFormState copyWith({ReportReason? reason, String? detail}) =>
      ReportFormState(
        reason: reason ?? this.reason,
        detail: detail ?? this.detail,
      );
}

/// 通報（シート）（画面定義書（ファン向け）2.6.1）。理由と詳しい内容を持ち、通報を送る。
class ReportViewModel extends Notifier<ReportFormState> {
  /// 詳しい内容の上限（見た目の1文字で数える。機能仕様書 4.2.7）。
  static const maxDetailLength = 500;

  @override
  ReportFormState build() => const ReportFormState();

  void selectReason(ReportReason reason) =>
      state = state.copyWith(reason: reason);

  void setDetail(String detail) => state = state.copyWith(detail: detail);

  /// [target] を通報する。理由を選んでいなければ、送らずに [ReportResult.failed]。
  Future<ReportResult> submit(ReportTarget target) async {
    final reason = state.reason;
    if (reason == null) return ReportResult.failed;
    return ref
        .read(reportRepositoryProvider)
        .submit(target, reason, state.detail);
  }
}

final reportViewModelProvider =
    NotifierProvider.autoDispose<ReportViewModel, ReportFormState>(
      ReportViewModel.new,
    );
