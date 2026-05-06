import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/provider/diary_entries_provider.dart';
import 'package:yamt/features/diary/provider/diary_meal_sections_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'diary_meal_media.dart';
part 'diary_meal_card.dart';

/// Stable keys for diary meal section tests.
abstract final class DiaryMealsSectionKeys {
  /// Card key for a meal section.
  static Key mealCard(MealType mealType) {
    return ValueKey<String>('diary-meal-card-${mealType.jsonValue}');
  }

  /// Collapsed empty-state key for a meal section.
  static Key collapsedEmpty(MealType mealType) {
    return ValueKey<String>(
      'diary-meal-collapsed-empty-${mealType.jsonValue}',
    );
  }

  /// Expanded empty-state key for a meal section.
  static Key expandedEmpty(MealType mealType) {
    return ValueKey<String>(
      'diary-meal-expanded-empty-${mealType.jsonValue}',
    );
  }

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-meals-retry-button');
}

/// Collapsible meal cards for the diary page.
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
  List<CalorieMealSection>? _lastSections;

  @override
  Widget build(BuildContext context) {
    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    final sectionsState = ref.watch(
      diaryMealSectionsProvider(normalizedDay),
    );
    final loadedSections = sectionsState.asData?.value;
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
          DiaryDetailCardShell(
            child: DiaryErrorRetryContent(
              message: l10n.diaryMealsLoadFailed,
              retryLabel: l10n.caloriesRetryAction,
              retryButtonKey: DiaryMealsSectionKeys.retryButton,
              onRetry: () => _retryMeals(normalizedDay),
            ),
          )
        else if (sections == null)
          const _MealCardsSkeleton()
        else
          ...sections.map((section) {
            final isExpanded = _expandedMealType == section.mealType;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _DiaryMealCard(
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
