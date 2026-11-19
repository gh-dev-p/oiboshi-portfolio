import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator_link.dart';
import '../../../domain/models/share_link.dart';
import '../../core/view_models/auth_session_provider.dart';

/// 発信者ページに出す、リンク集のリンク（並び順。届ける・広める仕様書 4.6.2）。
/// 読めなければ、リンクの欄だけを出さない。
/// 追星に誘うリンク（4.6.6）は、ファンがもう追星を入れているので出さない（公開のページだけに出す）。
final creatorLinksProvider = FutureProvider.autoDispose
    .family<List<CreatorLink>, String>(
      (ref, creatorId) => withSession(ref, (_) async {
        final links = await ref
            .watch(creatorLinkRepositoryProvider)
            .fetchPublic(creatorId);
        return [
          for (final link in links)
            if (!ShareLink.isInviteLinkFor(creatorId, link.url)) link,
        ];
      }),
    );
