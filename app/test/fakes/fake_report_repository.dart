import 'dart:async';

import 'package:oiboshi/data/repositories/report/report_repository.dart';
import 'package:oiboshi/domain/models/report.dart';

import 'fake_data.dart';

class FakeReportRepository implements ReportRepository {
  FakeReportRepository(this.data);

  final FakeData data;

  @override
  Future<ReportResult> submit(
    ReportTarget target,
    ReportReason reason,
    String detail,
  ) async {
    if (data.reportResult == ReportResult.submitted) {
      data.reports.add((target, reason, detail.trim()));
    }
    return data.reportResult;
  }
}
