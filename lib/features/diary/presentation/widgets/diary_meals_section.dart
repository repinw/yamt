import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';
import 'package:yamt/features/diary/application/diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Collapsible meal cards for the diary page.
@Dependencies([
  InventoryItemsController,
  diaryQuickEatInventory,
  diaryQuickEatInventoryActions,
  inventoryBackedCalorieEntrySaveFlow,
])
class DiaryMealsSection extends ConsumerStatefulWidget {
  /// Creates diary meal cards.
  const DiaryMealsSection({required this.selectedDay, super.key});

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  ConsumerState<DiaryMealsSection> createState() => _DiaryMealsSectionState();
}

class _DiaryMealsSectionState extends ConsumerState<DiaryMealsSection> {
  MealType? _expandedMealType;
  List<DiaryMealSection>? _lastSections;

  @override
  Widget build(BuildContext context) {
    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    final sectionsState = ref.watch(
      diaryMealSectionsProvider(normalizedDay),
    );
    final loadedSections = sectionsState.value;
    if (loadedSections != null) {
      _lastSections = loadedSections;
    }
    final sections = loadedSections ?? _lastSections;
    final l10n = AppLocalizations.of(context)!;
    final showError = sections == null && sectionsState.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.diaryMealsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (showError)
          MetricDetailCardShell(
            child: MetricErrorRetryContent(
              message: l10n.diaryMealsLoadFailed,
              retryLabel: l10n.caloriesRetryAction,
              retryButtonKey: DiaryMealsSectionKeys.retryButton,
              onRetry: () => _retryMeals(normalizedDay),
            ),
          )
        else if (sections == null)
          const DiaryMealCardsSkeleton()
        else
          ...sections.map((section) {
            final isExpanded = _expandedMealType == section.mealType;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: DiaryMealCard(
                key: DiaryMealsSectionKeys.mealCard(section.mealType),
                section: section,
                isExpanded: isExpanded,
                onToggle: () {
                  setState(() {
                    _expandedMealType = isExpanded ? null : section.mealType;
                  });
                },
                onTapEntry: (entry) => unawaited(
                  context.push<void>(
                    AppRoutes.homeCaloriesEntryDetailsPath(entry.id),
                  ),
                ),
                onQuickAdd: (source) => unawaited(
                  DiaryQuickEatFlow.openSource(
                    context: context,
                    ref: ref,
                    source: source,
                    mealType: section.mealType,
                    selectedDay: normalizedDay,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _retryMeals(DateTime normalizedDay) {
    ref
      ..invalidate(diaryEntriesForDayProvider(normalizedDay))
      ..invalidate(diaryMealSectionsProvider(normalizedDay));
  }
}
