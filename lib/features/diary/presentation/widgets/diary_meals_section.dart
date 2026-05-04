import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'diary_meal_card.dart';
part 'diary_meal_media.dart';

/// Provides real meal sections for one diary day.
final FutureProviderFamily<List<CalorieMealSection>, DateTime>
diaryMealSectionsProvider =
    FutureProvider.family<List<CalorieMealSection>, DateTime>((ref, day) async {
      ref.watch(calorieOverviewRevisionProvider);
      final normalizedDay = normalizeDiaryDay(day);
      final entries = await ref
          .watch(calorieLogRepositoryProvider)
          .readEntriesForDay(normalizedDay);

      final sectionEntries = <MealType, List<CalorieEntry>>{
        for (final mealType in MealType.sectionOrder)
          mealType: <CalorieEntry>[],
      };
      final sectionKcal = <MealType, double>{
        for (final mealType in MealType.sectionOrder) mealType: 0,
      };

      for (final entry in entries) {
        sectionEntries[entry.mealType]?.add(entry);
        sectionKcal[entry.mealType] =
            (sectionKcal[entry.mealType] ?? 0) + entry.totalKcal;
      }

      return MealType.sectionOrder
          .map((mealType) {
            return CalorieMealSection(
              mealType: mealType,
              entries: List<CalorieEntry>.unmodifiable(
                sectionEntries[mealType] ?? const <CalorieEntry>[],
              ),
              totalKcal: sectionKcal[mealType] ?? 0,
            );
          })
          .toList(growable: false);
    });

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
    final sectionsState = ref.watch(
      diaryMealSectionsProvider(widget.selectedDay),
    );
    final loadedSections = sectionsState.asData?.value;
    if (loadedSections != null) {
      _lastSections = loadedSections;
    }
    final sections = loadedSections ?? _lastSections;
    final l10n = AppLocalizations.of(context)!;

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
        if (sections == null)
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
}
