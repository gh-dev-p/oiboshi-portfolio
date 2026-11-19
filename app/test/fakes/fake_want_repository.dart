import 'dart:async';

import 'package:oiboshi/data/repositories/want/want_repository.dart';
import 'package:oiboshi/domain/models/sns_account_input.dart';
import 'package:oiboshi/domain/models/want.dart';

import 'fake_data.dart';

class FakeWantRepository implements WantRepository {
  FakeWantRepository(this.data);

  final FakeData data;

  @override
  Future<WantResult> want(SnsAccountInput input) async {
    final result = data.wantResult;
    if (result != null) return result;
    final registered =
        data.wantRegistered['${input.service.name}:${input.account}'];
    if (registered != null) return WantRegistered(registered);
    final i = data.wants.indexWhere(
      (w) => w.service == input.service && w.account == input.account,
    );
    if (i >= 0) return WantAdded(data.wants[i].wantCount);
    data.wants.insert(
      0,
      Want(
        wantedAccountId: 'w${data.wants.length + 1}',
        service: input.service,
        account: input.account,
        wantCount: 1,
        wantedAt: DateTime.now(),
      ),
    );
    return const WantAdded(1);
  }

  @override
  Future<List<Want>> fetchMine() async => List.of(data.wants);

  @override
  Future<void> cancel(String wantedAccountId) async {
    if (data.wantCancelFails) throw StateError('取り消せない');
    data.wants.removeWhere((w) => w.wantedAccountId == wantedAccountId);
  }
}
