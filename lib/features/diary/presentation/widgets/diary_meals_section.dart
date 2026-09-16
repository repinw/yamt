import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_group.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_meal_group/diary_meals_skeleton.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Quick-eat buttons and the meals logged on the selected diary day.
class DiaryMealsSection extends ConsumerWidget {
  /// Creates the diary meals section.
  const DiaryMealsSection({required this.selectedDay, super.key});

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedDay = normalizeLocalDay(selectedDay);
    final dashboardState = ref.watch(
      diaryDayDashboardControllerProvider(normalizedDay),
    );
    final sections = dashboardState.data?.mealSections;
    final l10n = AppLocalizations.of(context)!;

    if (sections == null) {
      if (!dashboardState.showError) {
        return const DiaryMealsSkeleton();
      }
      return MetricDetailCardShell(
        child: MetricErrorRetryContent(
          message: l10n.diaryMealsLoadFailed,
          retryLabel: l10n.caloriesRetryAction,
          retryButtonKey: DiaryMealsSectionKeys.retryButton,
          onRetry: () => unawaited(
            ref
                .read(
                  diaryDayDashboardControllerProvider(normalizedDay).notifier,
                )
                .retry(),
          ),
        ),
      );
    }

    final loggedSections = sections.where(
      (section) => section.entries.isNotEmpty,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiaryQuickEatBar(
          expanded: loggedSections.isEmpty,
          onSelected: (source) => unawaited(
            DiaryQuickEatFlow.openSource(
              context: context,
              source: source,
              selectedDay: normalizedDay,
            ),
          ),
        ),
        for (final section in loggedSections) ...[
          const SizedBox(height: AppSpacing.xxl),
          DiaryMealGroup(
            section: section,
            onTapEntry: (entry) => unawaited(
              context.push<void>(
                AppRoutes.homeCaloriesEntryDetailsPath(entry.id),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
