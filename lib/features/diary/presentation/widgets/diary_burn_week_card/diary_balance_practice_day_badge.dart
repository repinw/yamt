import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Marks the daily balance card of a day before the goal starts counting.
class DiaryBalancePracticeDayBadge extends StatelessWidget {
  /// Creates a practice-day badge.
  const new({required this.startDate, super.key});

  /// First official counting day.
  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat.MMMEd(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Align(
      key: DiaryBalanceCardKeys.practiceDay,
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: AppSizes.compactMetricIcon,
                color: colors.onTertiaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  l10n.burnWeekPracticeDayBadge(dateFormat.format(startDate)),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
