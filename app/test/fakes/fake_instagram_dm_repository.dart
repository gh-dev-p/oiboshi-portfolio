import 'dart:async';

import 'package:oiboshi/data/repositories/creator_admin/instagram_dm_repository.dart';
import 'package:oiboshi/domain/models/instagram_dm.dart';

import 'fake_data.dart';

/// 【仮】Instagram の DM での確認。Meta の審査が通ったら外す。
class FakeInstagramDmRepository implements InstagramDmRepository {
  FakeInstagramDmRepository(this.data);

  final FakeData data;

  @override
  Future<InstagramDmState> fetchState(String? creatorId) async {
    data.check();
    if (data.instagramDmFails) throw Exception('instagram dm');
    final account = data.instagramDmAccount;
    if (account == null) return const InstagramDmState();
    return InstagramDmState(
      dmAccount: account,
      request: data.instagramDmRequests[creatorId],
    );
  }

  @override
  Future<InstagramDmRequestResult> request(
    String? creatorId,
    String account,
  ) async {
    if (data.instagramDmResult == InstagramDmRequestResult.requested) {
      data.instagramDmRequests[creatorId] = InstagramDmRequest(
        id: 'req-${creatorId ?? 'pending'}',
        account: account.replaceFirst('@', '').toLowerCase(),
        code: '3F9A21C7',
        createdAt: DateTime(2026, 10, 26, 12),
      );
    }
    return data.instagramDmResult;
  }

  @override
  Future<void> cancel(String requestId) async =>
      data.instagramDmRequests.removeWhere((_, r) => r.id == requestId);
}
