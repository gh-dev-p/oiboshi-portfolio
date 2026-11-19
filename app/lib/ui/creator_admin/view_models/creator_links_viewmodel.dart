import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator_link.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/guard.dart';
import '../../creator/view_models/creator_links_provider.dart';

/// リンクの保存の結果（届ける・広める仕様書 4.6.1）。
enum CreatorLinkSaveResult { saved, shortUrl, limit, failed }

/// オーナーが見る、押された回数つきのリンク（並び順）。
final ownedCreatorLinksProvider = FutureProvider.autoDispose
    .family<List<CreatorLink>, String>(
      (ref, creatorId) => withSession(
        ref,
        (_) => ref.watch(creatorLinkRepositoryProvider).fetchOwned(creatorId),
      ),
    );

/// リンク集（画面定義書（設定・発信者）2.3.17・2.3.18・2.3.19）。足す・直す・消す・並べ替える。
/// 状態は、押された回数つきのリンク。並べ替えは、先に画面の並びを変えてから保存する。
class CreatorLinksViewModel extends Notifier<AsyncValue<List<CreatorLink>>> {
  CreatorLinksViewModel(this.creatorId);

  final String creatorId;

  @override
  AsyncValue<List<CreatorLink>> build() =>
      ref.watch(ownedCreatorLinksProvider(creatorId));

  /// 足す（[id] が null）か、直す。
  Future<CreatorLinkSaveResult> save({
    String? id,
    required String title,
    required String url,
  }) async {
    final repo = ref.read(creatorLinkRepositoryProvider);
    try {
      if (id == null) {
        await repo.add(creatorId, title, url);
      } else {
        await repo.edit(id, title, url);
      }
    } on CreatorLinkException catch (e) {
      return switch (e.error) {
        CreatorLinkError.shortUrl => CreatorLinkSaveResult.shortUrl,
        CreatorLinkError.limit => CreatorLinkSaveResult.limit,
        CreatorLinkError.stale => CreatorLinkSaveResult.failed,
      };
    } catch (_) {
      return CreatorLinkSaveResult.failed;
    }
    _reload();
    return CreatorLinkSaveResult.saved;
  }

  /// 消す。消せたら true。消せなければ、保存されている内容を読み直す。
  Future<bool> delete(String id) async {
    final ok = await succeeded(
      () => ref.read(creatorLinkRepositoryProvider).delete(id),
    );
    _reload();
    return ok;
  }

  /// [oldIndex] の行を [newIndex]（動かしたあとの位置）へ動かして、保存する。
  /// 保存できなければ false を返し、保存されている内容を読み直す。
  Future<bool> move(int oldIndex, int newIndex) async {
    final links = state.value;
    if (links == null || oldIndex == newIndex) return true;
    final next = [...links];
    next.insert(newIndex, next.removeAt(oldIndex));
    state = AsyncData(next);
    final ok = await succeeded(
      () => ref.read(creatorLinkRepositoryProvider).reorder(creatorId, [
        for (final l in next) l.id,
      ]),
    );
    if (!ok) _reload();
    // 発信者ページの並びも変わるので、読み直す。
    if (ok) ref.invalidate(creatorLinksProvider(creatorId));
    return ok;
  }

  /// 読み直す（引き下げ・失敗のあと）。
  Future<void> refresh() =>
      ref.refresh(ownedCreatorLinksProvider(creatorId).future);

  void _reload() {
    ref.invalidate(ownedCreatorLinksProvider(creatorId));
    ref.invalidate(creatorLinksProvider(creatorId));
  }
}

final creatorLinksViewModelProvider = NotifierProvider.autoDispose
    .family<CreatorLinksViewModel, AsyncValue<List<CreatorLink>>, String>(
      CreatorLinksViewModel.new,
    );
