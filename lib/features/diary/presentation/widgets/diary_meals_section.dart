import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';

/// Provides real meal sections for one Tagebuch day.
final FutureProvider<List<CalorieMealSection>> Function(DateTime)
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

/// Collapsible meal cards for the Tagebuch page.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tagebuch',
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

class _DiaryMealCard extends StatelessWidget {
  const _DiaryMealCard({
    required this.section,
    required this.isExpanded,
    required this.onToggle,
    required this.onTapEntry,
  });

  final CalorieMealSection section;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<CalorieEntry> onTapEntry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: isDark ? 24 : 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: [
                      _MealIcon(mealType: section.mealType),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _mealTitle(section.mealType),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      if (!isExpanded && section.entries.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${numberFormat.format(section.totalKcal.round())} '
                          'kcal',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: isExpanded
                              ? const Color(0xFF10B981)
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? _ExpandedMealBody(
                      section: section,
                      onTapEntry: onTapEntry,
                    )
                  : _CollapsedMealBody(
                      section: section,
                      onTapEntry: onTapEntry,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedMealBody extends StatelessWidget {
  const _CollapsedMealBody({
    required this.section,
    required this.onTapEntry,
  });

  final CalorieMealSection section;
  final ValueChanged<CalorieEntry> onTapEntry;

  @override
  Widget build(BuildContext context) {
    if (section.entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(
          top: AppSpacing.md,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Noch nichts eingetragen',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        right: AppSpacing.xs,
      ),
      child: Column(
        children: [
          for (final entry in section.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTapEntry(entry),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        _CollapsedMealThumb(entry: entry),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${numberFormat.format(entry.totalKcal.round())} '
                          'kcal',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CollapsedMealThumb extends ConsumerWidget {
  const _CollapsedMealThumb({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: 22,
        child: storedImageBytes != null
            ? Image.memory(storedImageBytes, fit: BoxFit.cover)
            : entry.imageUrl == null
            ? _MealThumbFallback(label: entry.name, compact: true)
            : AppCachedNetworkImage(
                imageUrl: entry.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _MealThumbFallback(label: entry.name, compact: true),
              ),
      ),
    );
  }
}

class _ExpandedMealBody extends StatelessWidget {
  const _ExpandedMealBody({
    required this.section,
    required this.onTapEntry,
  });

  final CalorieMealSection section;
  final ValueChanged<CalorieEntry> onTapEntry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            children: [
              if (section.entries.isEmpty)
                const _ExpandedEmptyMeal()
              else
                for (final entry in section.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ExpandedMealEntry(
                      entry: entry,
                      onTap: () => onTapEntry(entry),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedEmptyMeal extends StatelessWidget {
  const _ExpandedEmptyMeal();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Noch nichts eingetragen',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExpandedMealEntry extends StatelessWidget {
  const _ExpandedMealEntry({required this.entry, required this.onTap});

  final CalorieEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0x801F2937) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _MealThumb(entry: entry),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${numberFormat.format(entry.totalKcal.round())} '
                            'kcal',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: const Color(0xFF059669),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _MacroDots(entry: entry, numberFormat: numberFormat),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroDots extends StatelessWidget {
  const _MacroDots({required this.entry, required this.numberFormat});

  final CalorieEntry entry;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _MacroDot(
          color: const Color(0xFF3B82F6),
          label: '${numberFormat.format(entry.totalCarbs.round())}g',
        ),
        _MacroDot(
          color: const Color(0xFFEF4444),
          label: '${numberFormat.format(entry.totalProtein.round())}g',
        ),
        _MacroDot(
          color: const Color(0xFFEAB308),
          label: '${numberFormat.format(entry.totalFat.round())}g',
        ),
      ],
    );
  }
}

class _MacroDot extends StatelessWidget {
  const _MacroDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _MealIcon extends StatelessWidget {
  const _MealIcon({required this.mealType});

  final MealType mealType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        _mealIcon(mealType),
        color: const Color(0xFF059669),
        size: 22,
      ),
    );
  }
}

class _MealThumb extends ConsumerWidget {
  const _MealThumb({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox.square(
        dimension: 48,
        child: storedImageBytes != null
            ? Image.memory(storedImageBytes, fit: BoxFit.cover)
            : entry.imageUrl == null
            ? _MealThumbFallback(label: entry.name)
            : AppCachedNetworkImage(
                imageUrl: entry.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _MealThumbFallback(
                  label: entry.name,
                ),
              ),
      ),
    );
  }
}

class _MealThumbFallback extends StatelessWidget {
  const _MealThumbFallback({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style:
              (compact
                      ? Theme.of(context).textTheme.labelSmall
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
        ),
      ),
    );
  }
}

class _MealCardsSkeleton extends StatelessWidget {
  const _MealCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var index = 0; index < 4; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
      ],
    );
  }
}

String _mealTitle(MealType mealType) {
  return switch (mealType) {
    MealType.breakfast => 'Frühstück',
    MealType.lunch => 'Mittagessen',
    MealType.dinner => 'Abendessen',
    MealType.snack => 'Snacks',
  };
}

IconData _mealIcon(MealType mealType) {
  return switch (mealType) {
    MealType.breakfast => Icons.coffee_rounded,
    MealType.lunch => Icons.restaurant_rounded,
    MealType.dinner => Icons.local_fire_department_rounded,
    MealType.snack => Icons.cookie_rounded,
  };
}
