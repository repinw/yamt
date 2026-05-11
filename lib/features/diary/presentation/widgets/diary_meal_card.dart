part of 'diary_meals_section.dart';

class _DiaryMealCard extends StatelessWidget {
  const _DiaryMealCard({
    required this.section,
    required this.isExpanded,
    required this.onToggle,
    required this.onTapEntry,
    required this.onQuickAdd,
    super.key,
  });

  final CalorieMealSection section;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<CalorieEntry> onTapEntry;
  final ValueChanged<DiaryQuickEatSource> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.06),
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
                enableFeedback: false,
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
                          section.mealType.localizedName(l10n),
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
                          '${l10n.caloriesUnitKcal}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.xs),
                      DiaryMealQuickAddMenu(
                        mealType: section.mealType,
                        onSelected: onQuickAdd,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: isExpanded
                              ? accentColors.today
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
      final l10n = AppLocalizations.of(context)!;
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.diaryMealsEmpty,
            key: DiaryMealsSectionKeys.collapsedEmpty(section.mealType),
            style: TextStyle(
              color: colors.onSurfaceVariant,
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
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;

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
                  enableFeedback: false,
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
                          '${l10n.caloriesUnitKcal}',
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

class _ExpandedMealBody extends StatelessWidget {
  const _ExpandedMealBody({
    required this.section,
    required this.onTapEntry,
  });

  final CalorieMealSection section;
  final ValueChanged<CalorieEntry> onTapEntry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            children: [
              if (section.entries.isEmpty)
                _ExpandedEmptyMeal(mealType: section.mealType)
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
  const _ExpandedEmptyMeal({required this.mealType});

  final MealType mealType;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        AppLocalizations.of(context)!.diaryMealsEmpty,
        key: DiaryMealsSectionKeys.expandedEmpty(mealType),
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
    final isDark = colors.brightness == Brightness.dark;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        enableFeedback: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow.withValues(
              alpha: isDark ? 0.74 : 0.58,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
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
                            '${l10n.caloriesUnitKcal}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: accentColors.meal,
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
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _MacroDot(
          color: accentColors.carbs,
          label:
              '${numberFormat.format(entry.totalCarbs.round())}'
              '${l10n.caloriesUnitGram}',
        ),
        _MacroDot(
          color: accentColors.protein,
          label:
              '${numberFormat.format(entry.totalProtein.round())}'
              '${l10n.caloriesUnitGram}',
        ),
        _MacroDot(
          color: accentColors.fat,
          label:
              '${numberFormat.format(entry.totalFat.round())}'
              '${l10n.caloriesUnitGram}',
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
    final colors = Theme.of(context).colorScheme;
    final accentColors = DiaryAccentColors.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        _mealIcon(mealType),
        color: accentColors.meal,
        size: 22,
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

IconData _mealIcon(MealType mealType) {
  return switch (mealType) {
    MealType.breakfast => Icons.coffee_rounded,
    MealType.lunch => Icons.restaurant_rounded,
    MealType.dinner => Icons.local_fire_department_rounded,
    MealType.snack => Icons.cookie_rounded,
  };
}
