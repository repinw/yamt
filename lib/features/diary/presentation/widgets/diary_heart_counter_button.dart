import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_burn_week_run_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Diary heart counter shown in the home shell app bar.
class DiaryHeartCounterButton extends ConsumerWidget {
  /// Creates heart counter button.
  const DiaryHeartCounterButton({required this.runState, super.key});

  /// Current Burn Week run state.
  final BurnWeekRunState runState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final selectedDay = dateOnly(
      ref.watch(diaryCalendarControllerProvider).selectedDay,
    );
    final dayLabel = formatCalendarHeaderDate(selectedDay, localeName);
    final isHeartDay = runState.isHeartDay(selectedDay);
    final hasHearts = runState.heartCount > 0;
    final canUseHeart = runState.canUseHeartForDay(selectedDay);
    final tooltip = _tooltip(
      l10n: l10n,
      dayLabel: dayLabel,
      isHeartDay: isHeartDay,
      hasHearts: hasHearts,
      canUseHeart: canUseHeart,
    );

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: canUseHeart,
        label: tooltip,
        child: _DiaryHeartCounterPill(
          count: runState.heartCount,
          isHeartDay: isHeartDay,
          onPressed: canUseHeart
              ? () => _confirmAndUseHeart(
                  context: context,
                  ref: ref,
                  selectedDay: selectedDay,
                  dayLabel: dayLabel,
                )
              : null,
        ),
      ),
    );
  }

  String _tooltip({
    required AppLocalizations l10n,
    required String dayLabel,
    required bool isHeartDay,
    required bool hasHearts,
    required bool canUseHeart,
  }) {
    if (isHeartDay) {
      return l10n.homeHeartCounterActiveTooltip(dayLabel);
    }
    if (!hasHearts) {
      return l10n.homeHeartCounterEmptyTooltip;
    }
    if (!canUseHeart) {
      return l10n.homeHeartCounterUnavailableTooltip;
    }
    return l10n.homeHeartCounterUseTooltip(dayLabel);
  }

  Future<void> _confirmAndUseHeart({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime selectedDay,
    required String dayLabel,
  }) async {
    final actions = ref.read(diaryBurnWeekRunActionsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(dialogL10n.homeHeartUseTitle),
          content: Text(dialogL10n.homeHeartUseMessage(dayLabel)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogL10n.homeHeartUseConfirmAction),
            ),
          ],
        );
      },
    );
    if (!context.mounted || confirmed != true) {
      return;
    }
    await actions.useHeartForDay(selectedDay);
    if (!context.mounted) {
      return;
    }
    ProviderScope.containerOf(context, listen: false).invalidate(
      diaryDayDashboardControllerProvider(normalizeDiaryDay(selectedDay)),
    );
  }
}

class _DiaryHeartCounterPill extends StatelessWidget {
  const _DiaryHeartCounterPill({
    required this.count,
    required this.isHeartDay,
    required this.onPressed,
  });

  final int count;
  final bool isHeartDay;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final backgroundColor = isHeartDay
        ? colors.tertiaryContainer
        : enabled
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final foregroundColor = isHeartDay
        ? colors.onTertiaryContainer
        : enabled
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return SizedBox(
      width: 72,
      height: 36,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AppInkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isHeartDay
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: foregroundColor,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    AppLocalizations.of(context)!.diaryCounterLabel(count),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
