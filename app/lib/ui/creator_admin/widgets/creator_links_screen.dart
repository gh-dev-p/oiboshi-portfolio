import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator_link.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../core/ui/labeled_field.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/state_view.dart';
import '../../core/ui/viewer_aware_header.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../../share/view_models/share_link_viewmodel.dart';
import '../view_models/creator_links_viewmodel.dart';
import 'links_page_view.dart';

/// リンク集の着地の画面（画面定義書（設定・発信者）2.3.17、届ける・広める仕様書 4.6.1・4.6.3）。発信者メニューから開く。
/// 出すのは、リンク集のページの見本・「編集」「共有」・リンクごとの押された数（読むだけ）の3つだけ（本人の指示、2026-11-19）。
/// 足す・直す・並べ替え・消すは、「編集」で開くリンク集の編集（2.3.19）で行う。
class CreatorLinksScreen extends ConsumerWidget {
  const CreatorLinksScreen({super.key, required this.creatorId});

  final String creatorId;

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final box = context.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final outcome = await ref
        .read(shareLinkViewModelProvider.notifier)
        .share(
          creatorId,
          // 「追星に誘う」と同じ文と、誘う用のリンク（2026-11-19 本人）。
          message: (link) => l10n.shareInviteMessage(link.toString()),
          origin: origin,
        );
    if (!context.mounted) return;
    switch (outcome) {
      case ShareLinkOutcome.opened:
        break;
      case ShareLinkOutcome.unavailable:
        showAppSnackBar(context, l10n.shareLinkUnavailable);
      case ShareLinkOutcome.failed:
        showAppSnackBar(context, l10n.shareLinkFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = creatorLinksViewModelProvider(creatorId);
    final state = ref.watch(provider);
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.creatorLinksTitle),
      body: RefreshIndicator(
        onRefresh: () => ref.read(provider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _PagePreview(creatorId: creatorId),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TonalButton(
                      key: const ValueKey('creator-links-edit'),
                      label: l10n.creatorLinksEditButton,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CreatorLinksEditScreen(creatorId: creatorId),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) => PrimaryButton(
                        key: const ValueKey('creator-links-share'),
                        label: l10n.creatorLinksShareButton,
                        onPressed: () => _share(context, ref),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SectionLabel(
              l10n.creatorLinksClicksLabel,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
            ),
            switch (state) {
              // 並びは編集の画面と同じ、リンク集に登録した順（2026-11-19 本人）。アイコンは見本のボタンと同じもの。
              AsyncData(:final value) => _ClicksPanel(links: value),
              AsyncError() => StateView.error(
                onRetry: () => ref.read(provider.notifier).refresh(),
              ),
              _ => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SkeletonBox(height: 120, radius: 20),
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// リンクごとの押された数（アイコン・題名・数。読むだけ）。1件もなければ空の一言。
/// 並びは編集の画面と同じ、リンク集に登録した順。アイコンは見本のボタンと同じもの。
class _ClicksPanel extends StatelessWidget {
  const _ClicksPanel({required this.links});

  final List<CreatorLink> links;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    if (links.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          l10n.creatorLinksClicksEmpty,
          style: TextStyle(fontSize: 14, color: c.textSecondary),
        ),
      );
    }
    return SurfacePanel(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < links.length; i++)
            Container(
              key: ValueKey('creator-link-clicks-${links[i].id}'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border: i == links.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: c.divider)),
              ),
              child: Row(
                children: [
                  LinkServiceIcon(
                    url: links[i].url,
                    size: 20,
                    color: c.textPrimary,
                    web: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OneLineText(
                      links[i].title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.creatorLinksClicks(
                      withCommas(links[i].clickCount ?? 0),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// リンク集の編集（画面定義書（設定・発信者）2.3.19）。着地の画面の「編集」から開く。
/// リンクを並べ替え・消す。足す・直すは、シート（2.3.18）で行う。押された数の見方の注記は、ここの下に置く。
/// 見た目は、Figma を飛ばし、今の画面（届いた数・投稿の管理）の部品にそろえた仮の決め（2026-11-18）。
class CreatorLinksEditScreen extends ConsumerWidget {
  const CreatorLinksEditScreen({super.key, required this.creatorId});

  final String creatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = creatorLinksViewModelProvider(creatorId);
    final state = ref.watch(provider);
    final links = state.value;
    final full = links != null && links.length >= CreatorLinkRules.maxLinks;
    return HeaderScaffold(
      appBar: ScreenAppBar(
        title: l10n.creatorLinksEditTitle,
        actions: [
          AppTextButton(
            key: const ValueKey('creator-links-add'),
            label: l10n.creatorLinksAddShort,
            fontSize: 15,
            onPressed: links == null || full
                ? null
                : () => showCreatorLinkSheet(context, creatorId),
          ),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.read(provider.notifier).refresh(),
          child: _LinksBody(creatorId: creatorId, links: value),
        ),
        AsyncError() => StateView.error(
          onRetry: () => ref.read(provider.notifier).refresh(),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonBox(height: 200, radius: 20),
        ),
      },
    );
  }
}

class _LinksBody extends ConsumerWidget {
  const _LinksBody({required this.creatorId, required this.links});

  final String creatorId;
  final List<CreatorLink> links;

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    // onReorderItem は、動かす行を抜いたあとの位置を渡す。
    final ok = await ref
        .read(creatorLinksViewModelProvider(creatorId).notifier)
        .move(oldIndex, newIndex);
    if (!ok && context.mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.commonSaveFailed);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CreatorLink link,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.creatorLinksDeleteTitle(link.title),
      message: l10n.creatorLinksDeleteMessage,
      confirmLabel: l10n.creatorLinksDelete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await ref
        .read(loadingOverlayProvider.notifier)
        .run(
          () => ref
              .read(creatorLinksViewModelProvider(creatorId).notifier)
              .delete(link.id),
        );
    if (!ok && context.mounted) {
      showAppSnackBar(context, l10n.commonSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final note = Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Text(
        l10n.creatorLinksNote,
        style: TextStyle(fontSize: 12, height: 18 / 12, color: c.textTertiary),
      ),
    );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            l10n.creatorLinksLead,
            style: context.textStyles.bodySecondary,
          ),
        ),
        if (links.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.creatorLinksEmpty,
                  style: TextStyle(fontSize: 14, color: c.textSecondary),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: l10n.creatorLinksAdd,
                  onPressed: () => showCreatorLinkSheet(context, creatorId),
                ),
              ],
            ),
          )
        else
          SurfacePanel(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: links.length,
              onReorderItem: (from, to) => _move(context, ref, from, to),
              itemBuilder: (context, i) {
                final link = links[i];
                return Dismissible(
                  key: ValueKey('creator-link-${link.id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _delete(context, ref, link);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: c.live,
                    child: Text(
                      l10n.creatorLinksDelete,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  child: _LinkRow(
                    index: i,
                    link: link,
                    last: i == links.length - 1,
                    onTap: () =>
                        showCreatorLinkSheet(context, creatorId, link: link),
                  ),
                );
              },
            ),
          ),
        if (links.length >= CreatorLinkRules.maxLinks)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Text(
              l10n.creatorLinksLimit(CreatorLinkRules.maxLinks),
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ),
        note,
      ],
    );
  }
}

/// リンク集のページ（公開のページ `oiboshi.perrii.app/c/{ID}`）の見本（画面定義書（設定・発信者）2.3.17、届ける・広める仕様書 4.6.1）。
/// ページの中身（[LinksPageView]）を、スマホの幅（[LinksPageView.pageWidth]）で組み、カードに縮めて出す。下は薄くぼかして切る。
/// 押すと、ページの全体を画面いっぱいで見る画面（[LinksPageScreen]）を開く（2026-11-19 本人：「せめてタップしたら全体表示されてほしい」）。
/// カードに入りきらないリンク（いちばん下に足したものなど）は、全体の画面で見る。中のボタンは押せない。
class _PagePreview extends ConsumerWidget {
  const _PagePreview({required this.creatorId});

  final String creatorId;

  /// カードの幅（画面の幅に対する割合と、上限）。
  static const widthFactor = 0.62;
  static const maxWidth = 240.0;

  /// カードの高さ（幅に対する割合）。
  static const heightFactor = 1.35;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final page = ref.watch(linksPageDataProvider(creatorId));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * widthFactor).clamp(0.0, maxWidth);
        final height = width * heightFactor;
        if (page == null) {
          return Center(
            child: SkeletonBox(width: width, height: height, radius: 16),
          );
        }
        return Semantics(
          button: true,
          label: l10n.creatorLinksPreviewOpen,
          child: GestureDetector(
            key: const ValueKey('creator-links-preview'),
            onTap: () => LinksPageScreen.open(context, creatorId),
            child: Container(
              width: width,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: LinksPageView.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.divider),
              ),
              child: IgnorePointer(
                child: Stack(
                  children: [
                    OverflowBox(
                      alignment: Alignment.topCenter,
                      minWidth: LinksPageView.pageWidth,
                      maxWidth: LinksPageView.pageWidth,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: Transform.scale(
                        scale: width / LinksPageView.pageWidth,
                        alignment: Alignment.topCenter,
                        child: LinksPageView(data: page),
                      ),
                    ),
                    // 下を薄くぼかして切る。
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: height * 0.22,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              LinksPageView.bg.withValues(alpha: 0),
                              LinksPageView.bg,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// リンクの1行（左に並べ替えのつまみ、題名とドメイン、右に押された数）。
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.index,
    required this.link,
    required this.last,
    required this.onTap,
  });

  final int index;
  final CreatorLink link;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: c.divider)),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.drag_indicator, color: c.textTertiary),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OneLineText(
                      link.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    OneLineText(
                      link.host,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.creatorLinksClicks(withCommas(link.clickCount ?? 0)),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// リンクの追加・編集（シート）（画面定義書（設定・発信者）2.3.18）を出す。[link] があれば編集。
Future<void> showCreatorLinkSheet(
  BuildContext context,
  String creatorId, {
  CreatorLink? link,
}) => showAppSheet<void>(
  context,
  builder: (_) => CreatorLinkSheet(creatorId: creatorId, link: link),
);

class CreatorLinkSheet extends ConsumerStatefulWidget {
  const CreatorLinkSheet({super.key, required this.creatorId, this.link});

  final String creatorId;
  final CreatorLink? link;

  @override
  ConsumerState<CreatorLinkSheet> createState() => _CreatorLinkSheetState();
}

class _CreatorLinkSheetState extends ConsumerState<CreatorLinkSheet> {
  late final _title = TextEditingController(text: widget.link?.title);
  late final _url = TextEditingController(text: widget.link?.url ?? 'https://');

  /// URL の欄の下に出す、サーバーが断った理由（短縮 URL）。
  String? _urlServerError;

  /// 一度「保存」を押そうとしたか。押すまでは、形の違いを出さない。
  bool _touched = false;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  bool get _titleValid => CreatorLinkRules.isValidTitle(_title.text);
  bool get _urlValid => CreatorLinkRules.isValidUrl(_url.text);

  Future<void> _save() async {
    setState(() => _touched = true);
    if (!_titleValid || !_urlValid) return;
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(loadingOverlayProvider.notifier)
        .run(
          () => ref
              .read(creatorLinksViewModelProvider(widget.creatorId).notifier)
              .save(id: widget.link?.id, title: _title.text, url: _url.text),
        );
    if (!mounted) return;
    switch (result) {
      case CreatorLinkSaveResult.saved:
        Navigator.of(context).pop();
      case CreatorLinkSaveResult.shortUrl:
        setState(() => _urlServerError = l10n.creatorLinksShortUrl);
      case CreatorLinkSaveResult.limit:
        showAppSnackBar(
          context,
          l10n.creatorLinksLimit(CreatorLinkRules.maxLinks),
        );
      case CreatorLinkSaveResult.failed:
        showAppSnackBar(context, l10n.commonSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final title = _title.text.trim();
    final String? titleError = !_touched || _titleValid
        ? null
        : title.isEmpty
        ? l10n.creatorLinksTitleRequired
        : l10n.creatorLinksTitleTooLong(CreatorLinkRules.maxTitleLength);
    final urlError =
        _urlServerError ??
        (!_touched || _urlValid ? null : l10n.creatorLinksUrlInvalid);
    Widget error(String? text) => text == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(text, style: TextStyle(fontSize: 13, color: c.live)),
          );
    return Padding(
      // キーボードが出ても、入力欄と「保存」が隠れないようにする。
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheet(
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetTitle(
              widget.link == null
                  ? l10n.creatorLinksAdd
                  : l10n.creatorLinksEdit,
            ),
            LabeledField(
              label: l10n.creatorLinksTitleLabel,
              required: true,
              error: titleError != null,
              child: TextField(
                key: const ValueKey('creator-link-title'),
                controller: _title,
                maxLength: CreatorLinkRules.maxTitleLength,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: l10n.creatorLinksTitleHint,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            error(titleError),
            LabeledField(
              label: l10n.creatorLinksUrlLabel,
              required: true,
              error: urlError != null,
              note: l10n.creatorLinksUrlNote,
              child: TextField(
                key: const ValueKey('creator-link-url'),
                controller: _url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _urlServerError = null),
                onSubmitted: (_) => _save(),
              ),
            ),
            error(urlError),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: PrimaryButton(
                key: const ValueKey('creator-link-save'),
                label: l10n.commonSave,
                onPressed: _touched && (!_titleValid || !_urlValid)
                    ? null
                    : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
