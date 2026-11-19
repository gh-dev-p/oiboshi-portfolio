import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/schedule_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/state_view.dart';
import '../view_models/event_manage_viewmodel.dart';
import 'event_register_screen.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/viewer_aware_header.dart';

/// イベントの管理（画面定義書 2.3.7）。自分のイベントの公演を一覧し、イベントの登録・編集の画面を開く。
class EventManageScreen extends ConsumerStatefulWidget {
  const EventManageScreen({super.key, required this.creatorId});

  final String creatorId;

  @override
  ConsumerState<EventManageScreen> createState() =>
      _EventManageScreenState();
}

class _EventManageScreenState
    extends ConsumerState<EventManageScreen> {
  /// 「過去の予定」を開いているか（はじめは閉じておく）。
  bool _pastOpen = false;

  /// イベントの登録（[item] があれば、そのイベントの編集）の画面を開く（画面定義書 2.3.9）。
  void _open([ScheduleItem? item]) => EventRegisterScreen.open(
    context,
    creatorId: widget.creatorId,
    eventId: item?.eventId,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final state = ref.watch(
      eventManageViewModelProvider(widget.creatorId),
    );
    return HeaderScaffold(
      appBar: ScreenAppBar(
        title: l10n.creatorAdminMenuEventManage,
        actions: [
          AppTextButton(
            label: l10n.creatorAdminEventListAdd,
            fontSize: 15,
            onPressed: _open,
          ),
        ],
      ),
      body: state.when(
        skipLoadingOnRefresh: true,
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLine(),
              SizedBox(height: 16),
              SkeletonLine(),
              SizedBox(height: 16),
              SkeletonLine(),
            ],
          ),
        ),
        error: (_, _) => StateView.error(
          onRetry: ref
              .read(
                eventManageViewModelProvider(widget.creatorId).notifier,
              )
              .retry,
        ),
        data: (s) => s.isEmpty
            ? StateView(
                icon: Icons.confirmation_number_outlined,
                title: l10n.creatorAdminEventListEmpty,
                message: '',
                buttonLabel: l10n.creatorAdminEventListAdd,
                onPressed: _open,
              )
            : ListView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 32,
                ),
                children: [
                  for (final item in s.upcoming)
                    _EventRow(item: item, onTap: () => _open(item)),
                  if (s.past.isNotEmpty) ...[
                    InkWell(
                      onTap: () => setState(() => _pastOpen = !_pastOpen),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.creatorAdminEventListPast,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.textTertiary,
                                ),
                              ),
                            ),
                            Icon(
                              _pastOpen ? Icons.expand_less : Icons.expand_more,
                              size: 22,
                              color: c.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_pastOpen)
                      for (final item in s.past)
                        _EventRow(item: item, onTap: () => _open(item)),
                  ],
                ],
              ),
      ),
    );
  }
}

/// 一覧の1行（日付と時刻、タイトル、イベントのアイコン、会場）。
class _EventRow extends StatelessWidget {
  const _EventRow({required this.item, required this.onTap});

  final ScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final date = longDate(item.startsAt.toLocal(), l10n);
    final end = item.endsAt;
    final when = item.timeTbd
        ? l10n.commonScheduleDateTimeTbd(date)
        : item.allDay
        ? l10n.commonScheduleDateAllDay(date)
        : l10n.commonScheduleDateTime(
            date,
            clockTime(item.startsAt),
            end == null ? '' : clockTime(end),
          );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            PlatformIcon(item.service, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(when, style: context.textStyles.hint),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  if (item.venue != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.place, size: 14, color: c.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: OneLineText(
                            item.venue!,
                            style: context.textStyles.hint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
