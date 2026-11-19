import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../domain/models/creator_type.dart';
import '../../../domain/models/sns_profile.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/post_cards.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/profile_edit_viewmodel.dart';
import '../../core/ui/labeled_field.dart';
import '../../core/ui/platform_chip.dart';
import '../../core/ui/viewer_aware_header.dart';

/// プロフィールの編集（画面定義書 2.3.1）。名前・アイコン・カバー・プロフィール文・タイプを編集する。
/// 確認済みの SNS（登録の手順からは、登録待ちの連携）から、名前・アイコン・プロフィール文を下書きとして取り込める（4.6.4）。
class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key, this.creatorId});

  /// 登録の手順から開いたときは null（入力を登録の状態に持つ）。
  final String? creatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(profileEditViewModelProvider(creatorId));
    final vm = ref.read(profileEditViewModelProvider(creatorId).notifier);
    return state.when(
      skipLoadingOnRefresh: true,
      loading: () => HeaderScaffold(
        appBar: ScreenAppBar(title: l10n.creatorAdminProfileEditTitle),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonBox(height: 140, radius: 0),
        ),
      ),
      error: (_, _) => HeaderScaffold(
        appBar: ScreenAppBar(title: l10n.creatorAdminProfileEditTitle),
        body: StateView.error(onRetry: vm.retry),
      ),
      data: (s) => _ProfileForm(
        state: s,
        onPick: vm.pickImage,
        onRetryTypes: vm.retryTypes,
        onImport: (service) => ref
            .read(loadingOverlayProvider.notifier)
            .run(() => vm.importProfile(service)),
        // 登録の手順では下書きに入れるだけなので、読み込み中の表示は出さない。
        onSave: (name, bio, types, avatar, cover, id) {
          Future<ProfileSaveError?> save() => vm.save(
            name: name,
            bio: bio,
            types: types,
            avatar: avatar,
            cover: cover,
            id: id,
          );
          return creatorId == null
              ? save()
              : ref.read(loadingOverlayProvider.notifier).run(save);
        },
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({
    required this.state,
    required this.onPick,
    required this.onRetryTypes,
    required this.onImport,
    required this.onSave,
  });

  /// 発信者と、入力欄の初期値、取り込み元、タイプの一覧。
  final ProfileEditState state;

  /// 端末の写真から1枚を選ぶ。選ばなければ null。
  final Future<Uint8List?> Function({required double maxSide}) onPick;

  /// タイプの一覧を読み直す。
  final VoidCallback onRetryTypes;

  /// その SNS から、下書きを取る。失敗したら null。
  final Future<({SnsProfileDraft? draft, bool limited})> Function(
    SnsService service,
  )
  onImport;

  /// 保存する。保存できたら null、できなければ理由。[id] は、登録の手順のときだけ渡す。
  final Future<ProfileSaveError?> Function(
    String name,
    String bio,
    List<String> types,
    Uint8List? avatar,
    Uint8List? cover,
    String? id,
  )
  onSave;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final _name = TextEditingController(text: widget.state.initialName);
  late final _bio = TextEditingController(text: widget.state.initialBio);
  late final _id = TextEditingController(text: widget.state.initialId ?? '');
  late Uint8List? _avatar = widget.state.initialAvatar;
  late final _types = [...widget.state.initialTypes];
  late Uint8List? _cover = widget.state.initialCover;
  SnsService? _importSource;

  /// 取り込んだ下書きの、取り込み元（項目ごと）。
  SnsService? _nameFrom;
  SnsService? _bioFrom;

  Future<void> _import(SnsService service) async {
    setState(() => _importSource = service);
    final (:draft, :limited) = await widget.onImport(service);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final serviceName = l10n.sns(service);
    if (limited) {
      showAppSnackBar(context, l10n.creatorAdminImportLimited(serviceName));
      return;
    }
    if (draft == null) {
      showAppSnackBar(context, l10n.creatorAdminImportFailed(serviceName));
      return;
    }
    final name = draft.name;
    final bio = draft.bio;
    final avatar = draft.avatar;
    if (name == null && bio == null && avatar == null) {
      showAppSnackBar(context, l10n.creatorAdminImportEmpty(serviceName));
      return;
    }
    setState(() {
      if (name != null) {
        _name.text = ProfileEditViewModel.clampName(name);
        _nameFrom = service;
      }
      if (bio != null) {
        _bio.text = bio;
        _bioFrom = service;
      }
      if (avatar != null) _avatar = avatar;
    });
    showAppSnackBar(context, l10n.creatorAdminImported(serviceName));
  }

  Widget? _draftBadge(AppLocalizations l10n, SnsService? from) => from == null
      ? null
      : StatusChip(l10n.creatorAdminDraftBadge(l10n.sns(from)));

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _id.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final editingId = widget.state.creator == null;
    final error = await widget.onSave(
      _name.text,
      _bio.text,
      [..._types],
      _avatar,
      _cover,
      editingId ? _id.text : null,
    );
    if (!mounted) return;
    switch (error) {
      case null:
        Navigator.of(context).pop();
      case ProfileSaveError.nameInvalid:
        showAppSnackBar(context, l10n.creatorAdminNameInvalid);
      case ProfileSaveError.idInvalid:
        showAppSnackBar(context, l10n.creatorAdminIdInvalid);
      case ProfileSaveError.failed:
        showAppSnackBar(context, l10n.commonSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final creator = widget.state.creator;
    // カバーは、発信者ページと同じ横3：縦1。
    final coverHeight =
        MediaQuery.sizeOf(context).width / creatorCoverAspectRatio;
    return HeaderScaffold(
      appBar: ScreenAppBar(
        title: l10n.creatorAdminProfileEditTitle,
        actions: [
          AppTextButton(label: l10n.commonSave, fontSize: 15, onPressed: _save),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: [
          SizedBox(
            height: coverHeight + 44,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: coverHeight,
                  child: _cover != null
                      ? Image.memory(_cover!, fit: BoxFit.cover)
                      : PostThumbnail(
                          url: creator?.coverUrl,
                          aspectRatio: creatorCoverAspectRatio,
                          iconSize: 32,
                        ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: CircleIconButton(
                    icon: Icons.photo_camera,
                    size: 36,
                    iconSize: 18,
                    background: Colors.black.withValues(alpha: 0.45),
                    foreground: Colors.white,
                    tooltip: l10n.creatorAdminChangeCover,
                    onPressed: () async {
                      final bytes = await widget.onPick(maxSide: 1600);
                      if (bytes != null && mounted) {
                        setState(() => _cover = bytes);
                      }
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: coverHeight - 46,
                  child: Center(
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: Stack(
                        children: [
                          _avatar != null
                              ? Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c.background,
                                      width: 4,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.memory(
                                      _avatar!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : OshiAvatar(
                                  avatarUrl: creator?.avatarUrl,
                                  size: 92,
                                  borderColor: c.background,
                                  borderWidth: 4,
                                ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: c.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: c.background,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                tooltip: l10n.creatorAdminChangeAvatar,
                                icon: Icon(
                                  Icons.photo_camera,
                                  color: c.onPrimary,
                                ),
                                onPressed: () async {
                                  final bytes = await widget.onPick(
                                    maxSide: 600,
                                  );
                                  if (bytes != null && mounted) {
                                    setState(() => _avatar = bytes);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SurfacePanel(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download, size: 18, color: c.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.creatorAdminImportTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.creatorAdminImportDescription,
                    style: context.textStyles.caption,
                  ),
                  if (widget.state.importSources.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in widget.state.importSources)
                          PlatformChip(
                            service: s,
                            selected: _importSource == s,
                            onTap: () => _import(s),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          LabeledField(
            label: l10n.creatorAdminFieldName,
            badge: _draftBadge(l10n, _nameFrom),
            child: TextField(
              controller: _name,
              maxLength: ProfileEditViewModel.maxNameLength,
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
          LabeledField(
            label: l10n.creatorAdminFieldBio,
            badge: _draftBadge(l10n, _bioFrom),
            child: TextField(
              controller: _bio,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
            ),
          ),
          LabeledField(
            label: AppLocalizations.of(context)!.creatorAdminProfileIdLabel,
            note: l10n.creatorAdminIdNote,
            // 登録の手順では入力する。登録のあとは、変えられないので薄く出す。
            child: creator == null
                ? TextField(
                    controller: _id,
                    maxLength: 40,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      counterText: '',
                      prefixText: '@',
                      hintText: l10n.creatorAdminIdHint,
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: c.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      creator.handle,
                      style: TextStyle(fontSize: 15, color: c.textTertiary),
                    ),
                  ),
          ),
          LabeledField(
            label: AppLocalizations.of(context)!.creatorAdminProfileTypesLabel,
            note: AppLocalizations.of(
              context,
            )!.creatorAdminProfileTypesNote(CreatorType.maxPerCreator),
            child: _TypePicker(
              types: widget.state.types,
              selected: _types,
              onRetry: widget.onRetryTypes,
              onToggle: (id) => setState(
                () => _types.contains(id) ? _types.remove(id) : _types.add(id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// タイプのチップ（機能仕様書 4.6.4）。3つまで選べ、3つ選ぶと、ほかは押せない。
class _TypePicker extends StatelessWidget {
  const _TypePicker({
    required this.types,
    required this.selected,
    required this.onRetry,
    required this.onToggle,
  });

  final AsyncValue<List<CreatorType>> types;
  final List<String> selected;
  final VoidCallback onRetry;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return types.when(
      loading: () => const SkeletonBox(height: 34),
      error: (_, _) => Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.creatorAdminProfileTypesLoadFailed,
              style: context.textStyles.note,
            ),
          ),
          AppTextButton(
            label: AppLocalizations.of(context)!.commonRetry,
            fontSize: 13,
            onPressed: onRetry,
          ),
        ],
      ),
      data: (types) {
        final full = selected.length >= CreatorType.maxPerCreator;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in types)
              _TypeChip(
                label: t.name,
                selected: selected.contains(t.id),
                enabled: selected.contains(t.id) || !full,
                onTap: () => onToggle(t.id),
              ),
          ],
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? c.primary : (dark ? c.surface : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: selected ? null : Border.all(color: c.disabled),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? c.onPrimary : c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
