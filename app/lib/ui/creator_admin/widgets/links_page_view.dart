import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_link.dart';
import '../../../domain/models/share_link.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/sns_style.dart';
import '../../share/view_models/share_link_viewmodel.dart';
import '../view_models/creator_links_viewmodel.dart';

/// リンク集のページ（公開のページ）に出す中身。発信者と、ボタンにするリンク（登録した順）。
typedef LinksPageData = ({Creator creator, List<CreatorLink> links});

/// リンク集のページの見本と全体の画面が読む中身（届ける・広める仕様書 4.6.1・4.6.7）。発信者を読めるまでは null。
/// リンクは、編集の画面と同じ [creatorLinksViewModelProvider] から読むので、足す・消す・並べ替え・直すと、すぐ変わる。
/// 並びは公開のページと同じ決まり（[CreatorLinkRules.pageLinks]）で決める。
final linksPageDataProvider = Provider.autoDispose
    .family<LinksPageData?, String>((ref, creatorId) {
      final creator = ref.watch(shareTargetProvider(creatorId)).value?.creator;
      final links = ref.watch(creatorLinksViewModelProvider(creatorId)).value;
      if (creator == null || links == null) return null;
      return (creator: creator, links: CreatorLinkRules.pageLinks(links));
    });

/// リンク集のページの中身（公開のページ `oiboshi.perrii.app/c/{ID}` と同じ見た目）。見本と全体の画面で使う。
/// 公開のページは読み込まず、アプリが持っているデータから組み立てる（dev の発信者でも出せ、リンクを直したらすぐ変わる）。
/// 色・角の丸み・字の大きさは、公開のページの CSS（公開サイトのリポジトリ（別管理）の `oiboshi/src/style.css` の `.share`）に合わせる。
/// 公開のページはダークモードを持たないので、色は固定。中のボタンは押せない（見本）。
class LinksPageView extends StatelessWidget {
  const LinksPageView({super.key, required this.data, this.width = pageWidth});

  final LinksPageData data;

  /// 組み立てる幅。見本は [pageWidth] で組んで縮め、全体の画面は画面の幅で組む（公開のページを開いたときと同じ）。
  final double width;

  /// 見本を組み立てるときのページの幅（スマホの幅）。
  static const pageWidth = 390.0;

  /// 公開のページの中身の幅の上限（CSS の `.share` の max-width）。
  static const maxWidth = 560.0;

  // 公開のページの CSS の値。
  static const bg = Color(0xFFF2F2F0);
  static const _bg2 = Color(0xFFDCD9D4);
  static const _text = Color(0xFF141414);
  static const _line = Color(0xFF141414);
  static const _lineSoft = Color(0xFFB9B6B0);
  static const _muted = Color(0xFF7A7A76);
  static const _accent = Color(0xFF525CA5);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final creator = data.creator;
    final links = data.links;
    final avatar = creator.avatarUrl;
    // 読み込みに失敗したときは、公開のページの CSS の背景（--bg-2）と同じ色。
    final placeholder = Container(color: _bg2);
    // 追星に誘うリンク（4.6.6）があれば、下の入口は「アプリをお持ちの方はこちら」だけ（公開のページと同じ）。
    final hasInvite = links.any(
      (l) => ShareLink.isInviteLinkFor(creator.id, l.url),
    );
    return Container(
      width: width,
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipOval(
              child: SizedBox.square(
                dimension: 96,
                // アイコンが無い（https でない）ときは、公開のページと同じ追星のアイコン（公開サイトのリポジトリ（別管理） の `oiboshi/src/assets/icon.png` と同じ画像）。
                child: avatar == null || !avatar.startsWith('https://')
                    ? Image.asset(
                        'assets/logo/share_page_icon.png',
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => placeholder,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            creator.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          if (creator.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              creator.bio.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15.2, height: 1.6, color: _text),
            ),
          ],
          const SizedBox(height: 28),
          for (var i = 0; i < links.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Container(
              key: ValueKey('creator-links-preview-link-${links[i].id}'),
              // 公開のページの .share-link（左右 52px の中で題名を真ん中に。アイコンは左から 16px）。
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line, width: 1.5),
              ),
              child: Row(
                children: [
                  LinkServiceIcon(
                    url: links[i].url,
                    size: 24,
                    color: _muted,
                    web: true,
                    onDark: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      links[i].title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ],
          // 追星への入口（公開のページの下の .share-app.quiet と同じ）。
          Container(
            margin: EdgeInsets.only(top: links.isEmpty ? 40 : 56),
            padding: const EdgeInsets.only(top: 24),
            decoration: links.isEmpty
                ? null
                : const BoxDecoration(
                    border: Border(top: BorderSide(color: _lineSoft)),
                  ),
            child: Column(
              children: [
                if (!hasInvite) ...[
                  Text(
                    l10n.creatorLinksPageAppLead(creator.name),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.6,
                      height: 1.8,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.creatorLinksPageInstall,
                      style: const TextStyle(
                        fontSize: 14.4,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.creatorLinksPageInstallNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.8, color: _muted),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  l10n.creatorLinksPageOpenApp,
                  style: const TextStyle(fontSize: 13.6, color: _accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// リンク集のページの全体を、画面いっぱいで見る画面（画面定義書（設定・発信者）2.3.17。2026-11-19 本人）。
/// 見本を押すと開く。スクロールでき、右上の閉じるボタンで戻る。中のボタンは押せない。
class LinksPageScreen extends ConsumerWidget {
  const LinksPageScreen({super.key, required this.creatorId});

  final String creatorId;

  static Future<void> open(BuildContext context, String creatorId) =>
      // 画面いっぱいで見るので、下部ナビの上に重ねる（いちばん外の Navigator）。
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => LinksPageScreen(creatorId: creatorId),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(linksPageDataProvider(creatorId));
    return Scaffold(
      key: const ValueKey('creator-links-page-screen'),
      backgroundColor: LinksPageView.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (data != null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                    // 画面の幅で組む（公開のページを開いたときと同じく、字は伸び縮みさせず、ボタンを横幅いっぱいにする）。
                    // 広い画面では、公開のページと同じく中身を 560 までにして真ん中に置く。
                    child: Center(
                      child: IgnorePointer(
                        child: LinksPageView(
                          data: data,
                          width: constraints.maxWidth < LinksPageView.maxWidth
                              ? constraints.maxWidth
                              : LinksPageView.maxWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 8,
              child: IconButton(
                key: const ValueKey('creator-links-page-close'),
                tooltip: l10n.commonClose,
                icon: const Icon(Icons.close, color: Color(0xFF141414)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
