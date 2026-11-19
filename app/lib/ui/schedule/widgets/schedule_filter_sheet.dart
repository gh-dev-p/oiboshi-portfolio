import 'package:flutter/material.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/schedule_filter.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/platform_chip.dart';
import '../../core/ui/one_line_text.dart';

/// 絞り込み（シート）（画面定義書 2.1.4）。表示する推し・プラットフォーム・内容を選ぶ。
/// 予定のない推しを隠すかは、ヘッダーのアイコンで切り替えるので、ここでは変えない。
/// 推しは、シートの中で横に送った一覧で選ぶ（2.1.4.1）。タイムスケジュールとみんなのカレンダーで使う。
Future<ScheduleFilter?> showScheduleFilterSheet(
  BuildContext context, {
  required List<Creator> creators,
  required ScheduleFilter current,
}) => showAppSheet<ScheduleFilter>(
  context,
  builder: (_) => _FilterSheet(creators: creators, current: current),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.creators, required this.current});

  final List<Creator> creators;
  final ScheduleFilter current;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  /// 選んだ推し。いまフォロー中の推しのうち、外していない推し（フォローを外した推しは数えない）。
  late Set<String> _creators = widget.current.shownCreatorIds(_oshiIds);
  late Set<SnsService> _services =
      widget.current.services ?? SnsService.values.toSet();
  late bool _live = widget.current.showLive;
  late bool _posts = widget.current.showPosts;
  late bool _platformless = widget.current.showPlatformless;

  /// 推しの選択（2.1.4.1）を出しているか。
  bool _choosingCreators = false;

  late final _oshiIds = [for (final c in widget.creators) c.id];

  void _reset() => setState(() {
    _creators = _oshiIds.toSet();
    _services = SnsService.values.toSet();
    _platformless = _live = _posts = true;
  });

  ScheduleFilter get _result => ScheduleFilter(
    hiddenCreatorIds: {
      for (final id in _oshiIds)
        if (!_creators.contains(id)) id,
    },
    services: _services.length == SnsService.values.length ? null : _services,
    showPlatformless: _platformless,
    showLive: _live,
    showPosts: _posts,
    hideEmpty: widget.current.hideEmpty,
  );

  bool get _allCreators => _creators.length == widget.creators.length;

  void _toggleCreator(String id) => setState(() {
    _creators = _creators.contains(id)
        ? ({..._creators}..remove(id))
        : {..._creators, id};
  });

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      scrollable: true,
      child: ClipRect(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            // 推しの選択は右から入り、戻ると右へ抜ける。
            transitionBuilder: (child, animation) {
              final isCreators = child.key == const ValueKey('creators');
              return SlideTransition(
                position:
                    Tween(
                      begin: Offset(isCreators ? 1 : -1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              );
            },
            child: _choosingCreators
                ? KeyedSubtree(
                    key: const ValueKey('creators'),
                    child: _buildCreators(context),
                  )
                : KeyedSubtree(
                    key: const ValueKey('filter'),
                    child: _buildFilter(context),
                  ),
          ),
        ),
      ),
    );
  }

  /// 推しの選択（2.1.4.1）。
  Widget _buildCreators(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 28, color: c.textPrimary),
                tooltip: l10n.commonBack,
                onPressed: () => setState(() => _choosingCreators = false),
              ),
              Expanded(
                child: Text(
                  l10n.scheduleFilterCreatorsTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              AppTextButton(
                label: _allCreators
                    ? l10n.scheduleFilterDeselectAll
                    : l10n.scheduleFilterSelectAll,
                onPressed: () => setState(() {
                  _creators = _allCreators ? <String>{} : _oshiIds.toSet();
                }),
              ),
            ],
          ),
        ),
        for (final creator in widget.creators)
          _CreatorRow(
            creator: creator,
            selected: _creators.contains(creator.id),
            onTap: () => _toggleCreator(creator.id),
          ),
      ],
    );
  }

  Widget _buildFilter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(
          l10n.scheduleFilterTitle,
          trailing: AppTextButton(
            label: l10n.scheduleFilterReset,
            onPressed: _reset,
          ),
        ),
        SettingsRow(
          icon: Icons.people_outline,
          label: l10n.scheduleFilterCreatorsTitle,
          value: _allCreators
              ? l10n.scheduleFilterAllCreators
              : l10n.scheduleFilterCreatorCount(_creators.length),
          onTap: () => setState(() => _choosingCreators = true),
        ),
        SectionLabel(
          l10n.scheduleFilterPlatforms,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in SnsService.values)
                PlatformChip(
                  service: s,
                  selected: _services.contains(s),
                  onTap: () => setState(() {
                    if (_services.contains(s)) {
                      _services = {..._services}..remove(s);
                    } else {
                      _services = {..._services, s};
                    }
                  }),
                ),
              // プラットフォームのない予定（イベントの公演）。SNS のあと、最後に置く（画面定義書 5.1.7）。
              PlatformChip(
                service: null,
                selected: _platformless,
                onTap: () => setState(() => _platformless = !_platformless),
              ),
            ],
          ),
        ),
        SectionLabel(
          l10n.scheduleFilterContent,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        ),
        _SwitchRow(
          label: l10n.commonLive,
          value: _live,
          onChanged: (v) => setState(() => _live = v),
        ),
        _SwitchRow(
          label: l10n.commonPost,
          value: _posts,
          onChanged: (v) => setState(() => _posts = v),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: PrimaryButton(
            // 「イベント」は SNS に数えない。
            label: l10n.scheduleFilterApply(_creators.length, _services.length),
            // 推しを1人も、または SNS も「イベント」も1つも選んでいないときは、押せない（機能仕様書 4.5.5）。
            onPressed:
                _creators.isEmpty || (_services.isEmpty && !_platformless)
                ? null
                : () => Navigator.of(context).pop(_result),
          ),
        ),
      ],
    );
  }
}

/// 推しの選択の行（アイコン、名前、チェック）。
class _CreatorRow extends StatelessWidget {
  const _CreatorRow({
    required this.creator,
    required this.selected,
    required this.onTap,
  });

  final Creator creator;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Opacity(
              opacity: selected ? 1 : 0.45,
              child: OshiAvatar(avatarUrl: creator.avatarUrl, size: 44),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: OneLineText(
                creator.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? c.textPrimary : c.textTertiary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? c.primary : null,
                border: selected
                    ? null
                    : Border.all(color: c.disabled, width: 1.5),
              ),
              child: selected
                  ? Icon(Icons.check, size: 16, color: c.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: context.colors.textPrimary),
            ),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
