import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_carryover_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_today_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the daily budget details modal bottom sheet.
Future<void> showDiaryDailyBudgetDetailsSheet({
  required BuildContext context,
  required DiaryDailyBudgetDetailsData data,
  required NumberFormat numberFormat,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => DiaryDailyBudgetDetailsSheet(
      data: data,
      numberFormat: numberFormat,
    ),
  );
}

/// Modal bottom sheet showing a transparent breakdown of today's calorie budget
/// and the carryover accumulated from previous days.
class DiaryDailyBudgetDetailsSheet extends StatelessWidget {
  /// Creates the daily budget details sheet.
  const DiaryDailyBudgetDetailsSheet({
    required this.data,
    required this.numberFormat,
    super.key,
  });

  /// The budget details data to render.
  final DiaryDailyBudgetDetailsData data;

  /// Number formatter matching the active locale.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final primary = MetricAccentColors.of(context).today;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md + viewInsets.bottom,
        ),
        child: Material(
          key: DiaryBalanceCardKeys.dailyBudgetDetailsSheet,
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 20, color: primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.diaryBudgetDetailsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DiaryDailyBudgetTodayCard(
                    data: data,
                    numberFormat: numberFormat,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DiaryDailyBudgetCarryoverSection(
                    data: data,
                    numberFormat: numberFormat,
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
