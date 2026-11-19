import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/announce_template.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../core/ui/viewer_aware_header.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/announce_image_viewmodel.dart';

/// 週間の告知画像（画面定義書（設定・発信者）2.3.15、届ける・広める仕様書 4.4.1）。発信者メニューから開く。
/// 画像はサーバー（Edge Functions の `announce-image`）がテンプレに流し込んで作り、この画面は取ってきて出すだけ。
/// 今週・来週・テンプレ・画像（アイコンか、選んだ画像）を選び、画像と文を共有シートに渡す。
class AnnounceImageScreen extends ConsumerStatefulWidget {
  const AnnounceImageScreen({super.key, required this.creatorId});

  final String creatorId;

  @override
  ConsumerState<AnnounceImageScreen> createState() =>
      _AnnounceImageScreenState();
}

class _AnnounceImageScreenState extends ConsumerState<AnnounceImageScreen> {
  var _week = AnnounceWeek.thisWeek;

  /// 最後に出せた画像。作り直している間、薄くして下に敷く（画面定義書（設定・発信者）2.3.15）。
  Uint8List? _lastPng;

  /// 押して選んだテンプレ。押していなければ、覚えたテンプレ（[AnnounceImageViewModel.savedTemplateId]）。
  String? _picked;

  AnnounceImageViewModel get _vm =>
      ref.read(announceImageViewModelProvider.notifier);

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnackBar(context, AppLocalizations.of(context)!.announceShareCopied);
  }

  Future<void> _share(
    BuildContext buttonContext,
    Uint8List png,
    DateTime weekStart,
    String text,
  ) async {
    final box = buttonContext.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final ok = await _vm.share(
      png,
      creatorId: widget.creatorId,
      weekStart: weekStart,
      text: text,
      origin: origin,
    );
    if (!ok && mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.announceImageShareFailed,
      );
    }
  }

  Future<void> _changePhoto() async {
    final result = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => _vm.changePhoto(widget.creatorId));
    if (result == AnnouncePhotoResult.failed && mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.announceImagePhotoFailed,
      );
    }
  }

  Future<void> _resetPhoto() async {
    final ok = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => _vm.resetPhoto(widget.creatorId));
    if (!ok && mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.announceImagePhotoFailed,
      );
    }
  }

  void _pickTemplate(String id) {
    setState(() => _picked = id);
    _vm.saveTemplate(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final lang = Localizations.localeOf(context).languageCode == 'ja'
        ? 'ja'
        : 'en';
    final key = (creatorId: widget.creatorId, week: _week);
    final state = ref.watch(announceDataProvider(key));
    final templates = ref.watch(announceTemplatesProvider(lang));
    final photo = ref.watch(announcePhotoProvider(widget.creatorId));
    final templateList = templates.value ?? const <AnnounceTemplate>[];
    final templateId = announceTemplateIdFor(
      _picked ?? _vm.savedTemplateId,
      templateList,
    );
    // テンプレの一覧と選んだ画像が分かってから作る（作り直しを減らすため）。一覧が取れなくても、既定で作る。
    final imageKey = templates.isLoading || photo.isLoading
        ? null
        : (
            creatorId: widget.creatorId,
            week: _week,
            templateId: templateId,
            lang: lang,
            photoUrl: photo.value,
          );
    final image = imageKey == null
        ? const AsyncValue<Uint8List>.loading()
        : ref.watch(announceImageProvider(imageKey));
    final done = image.isLoading ? null : image.value;
    if (done != null) _lastPng = done;
    final note = TextStyle(
      fontSize: 12,
      height: 18 / 12,
      color: c.textTertiary,
    );
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.announceImageTitle),
      body: ListView(
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final week in AnnounceWeek.values) ...[
                  SmallPillButton(
                    label: switch (week) {
                      AnnounceWeek.thisWeek => l10n.announceImageThisWeek,
                      AnnounceWeek.nextWeek => l10n.announceImageNextWeek,
                    },
                    tonal: week != _week,
                    onPressed: () => setState(() => _week = week),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Preview(
              image: image,
              previous: _lastPng,
              onRetry: imageKey == null
                  ? null
                  : () => ref.invalidate(announceImageProvider(imageKey)),
            ),
          ),
          if (templateList.isNotEmpty)
            _TemplateStrip(
              templates: templateList,
              selectedId: templateId,
              onPick: _pickTemplate,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                SmallPillButton(
                  label: l10n.announceImageChangePhoto,
                  tonal: true,
                  onPressed: photo.isLoading ? null : _changePhoto,
                ),
                const Spacer(),
                if (photo.value != null)
                  AppTextButton(
                    label: l10n.announceImageResetPhoto,
                    fontSize: 13,
                    onPressed: _resetPhoto,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
            child: Text(l10n.announceImagePhotoNote, style: note),
          ),
          ...state.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: SkeletonBox(height: 48, radius: 24),
              ),
            ],
            error: (_, _) => [
              SizedBox(
                height: 240,
                child: StateView.error(
                  onRetry: () => ref.invalidate(announceDataProvider(key)),
                ),
              ),
            ],
            data: (data) {
              final text = announceShareText(data, l10n);
              final png = image.value;
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Builder(
                    builder: (context) => PrimaryButton(
                      label: l10n.announceImageShare,
                      onPressed: png == null || image.isLoading
                          ? null
                          : () => _share(context, png, data.weekStart, text),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Text(
                    l10n.announceImageNote,
                    textAlign: TextAlign.center,
                    style: note,
                  ),
                ),
                // 画像と一緒に渡す文（届ける・広める仕様書 4.4.1）。Instagram 向けに、写せるようにする。
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.announceShareTextLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      SmallPillButton(
                        label: l10n.announceShareCopy,
                        tonal: true,
                        onPressed: () => _copy(text),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        height: 18 / 12,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(l10n.announceShareInstagramNote, style: note),
                ),
                // 文のリンクが押された数（チームメンバーだけが見る。届ける・広める仕様書 4.4.2）。読めなければ出さない。
                ..._linkCounts(context, data, note),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// 「リンクが押された数」の区画。行が無ければ何も出さない。
List<Widget> _linkCounts(
  BuildContext context,
  AnnounceData data,
  TextStyle note,
) {
  final l10n = AppLocalizations.of(context)!;
  final c = context.colors;
  final rows = announceLinkRows(data, l10n);
  if (rows.isEmpty) return const [];
  return [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        l10n.announceLinkCountsLabel,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
      ),
    ),
    for (final row in rows)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: OneLineText(
                row.label,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.announceLinkCount(row.count),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
  ];
}

/// 画像の見本（サーバーが作った画像を、画面の幅に縮めて出す）。
/// 作っている間は、枠の真ん中にくるくる回る印と「画像を作っています」。作り直すときは、前の画像（[previous]）を薄くして下に敷く。
/// 作れなければ「画像を作れませんでした」と「再試行」。
class _Preview extends StatelessWidget {
  const _Preview({
    required this.image,
    required this.previous,
    required this.onRetry,
  });

  final AsyncValue<Uint8List> image;
  final Uint8List? previous;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final png = image.isLoading ? null : image.value;
    final failed = image.hasError && !image.isLoading;
    final shown = png ?? (failed ? null : previous);
    final radius = BorderRadius.circular(12);
    return AspectRatio(
      aspectRatio: announceImageAspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: radius,
          border: Border.all(color: c.border),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (shown != null)
                Opacity(
                  opacity: png != null ? 1 : 0.35,
                  child: Image.memory(
                    shown,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              if (failed)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.announceImageRenderFailed,
                        style: TextStyle(fontSize: 14, color: c.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      SmallPillButton(
                        label: l10n.commonRetry,
                        tonal: true,
                        onPressed: onRetry,
                      ),
                    ],
                  ),
                )
              else if (png == null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.announceImageRendering,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// テンプレのサムネイルを横に並べる。選んでいるものに主色の枠。1つでも出す（2026-11-19 本人）。
class _TemplateStrip extends StatelessWidget {
  const _TemplateStrip({
    required this.templates,
    required this.selectedId,
    required this.onPick,
  });

  final List<AnnounceTemplate> templates;
  final String selectedId;
  final ValueChanged<String> onPick;

  static const _width = 112.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: _width / announceImageAspectRatio + 12 + 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: templates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = templates[i];
          final selected = t.id == selectedId;
          return Semantics(
            button: true,
            selected: selected,
            label: t.name,
            child: GestureDetector(
              onTap: () => onPick(t.id),
              child: SizedBox(
                width: _width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: _width,
                      height: _width / announceImageAspectRatio,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? c.primary : c.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          t.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: c.surface),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    OneLineText(
                      t.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected ? c.textPrimary : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
