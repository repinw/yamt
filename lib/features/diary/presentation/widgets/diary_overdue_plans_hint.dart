import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_overdue_plans_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A line on today that names past days with plans that were never eaten.
/// A tap opens the last of them; the close button hides the line.
class DiaryOverduePlansHint extends ConsumerWidget {
  /// Creates the hint for the diary page of [selectedDay].
  const new({required this.selectedDay, super.key});

  /// Key of the line.
  static const lineKey = Key('diary_overdue_plans_hint');

  /// Key of the close button.
  static const closeKey = Key('diary_overdue_plans_hint_close');

  /// The day the diary shows; the hint shows on today only.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(
      diaryCalendarControllerProvider.select((state) => state.today),
    );
    if (!isSameCalendarDay(selectedDay, today)) {
      return const SizedBox.shrink();
    }
    final provider = diaryOverduePlansControllerProvider(dateOnly(today));
    final days = ref.watch(provider);
    if (days == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final line = Material(
      key: lineKey,
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => ref
            .read(diaryCalendarControllerProvider.notifier)
            .selectDay(days.last),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: AppSizes.iconBadgeIcon,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.diaryOverduePlansHint(
                    days.length,
                    DateFormat.MMMEd(localeName).format(days.last),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              IconButton(
                key: closeKey,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () =>
                    unawaited(ref.read(provider.notifier).dismiss()),
                icon: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: line,
    );
  }
}
