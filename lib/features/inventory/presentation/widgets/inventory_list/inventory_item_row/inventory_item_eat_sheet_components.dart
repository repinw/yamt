part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatLeadingIcon extends StatelessWidget {
  const _InventoryItemEatLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(icon, color: colors.primary, size: 18),
      ),
    );
  }
}

class _InventoryItemEatFieldCard extends StatelessWidget {
  const _InventoryItemEatFieldCard({
    required this.leadingIcon,
    required this.child,
  });

  static const _minHeight = 66.0;

  final IconData leadingIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              _InventoryItemEatLeadingIcon(icon: leadingIcon),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryItemEatWhenCard extends StatelessWidget {
  const _InventoryItemEatWhenCard({
    required this.label,
    required this.isToday,
    required this.onPressed,
  });

  final String? label;
  final bool isToday;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasLabel = !isToday && label != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('inventory_item_logged_at_button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppInventoryEditorialSurfaces.ghostBorder(colors),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _InventoryItemEatFieldCard._minHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: hasLabel
                  ? Row(
                      key: const Key('inventory_item_logged_at_labeled'),
                      children: [
                        const _InventoryItemEatLeadingIcon(
                          icon: Icons.calendar_today_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            label!,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    )
                  : Row(
                      key: const Key('inventory_item_logged_at_compact'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _InventoryItemEatLeadingIcon(
                          icon: Icons.calendar_today_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
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

class _InventoryItemEatMealTypeSelector extends StatelessWidget {
  const _InventoryItemEatMealTypeSelector({
    required this.selectedMealType,
    required this.onMealTypeSelected,
  });

  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return _InventoryItemEatFieldCard(
      leadingIcon: Icons.restaurant_rounded,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MealType>(
          value: selectedMealType,
          isDense: true,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          dropdownColor: colors.surfaceContainerHigh,
          icon: Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
          items: MealType.sectionOrder
              .map((mealType) {
                return DropdownMenuItem<MealType>(
                  value: mealType,
                  child: Text(
                    mealType.localizedName(l10n),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              })
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            onMealTypeSelected(value);
          },
        ),
      ),
    );
  }
}

class _InventoryItemEatNutritionMetricsRow extends StatelessWidget {
  const _InventoryItemEatNutritionMetricsRow({required this.metrics});

  final List<({String label, String value})> metrics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: _InventoryItemEatNutritionMetric(
                index: index,
                label: metrics[index].label,
                value: metrics[index].value,
                isHighlighted: index == 0,
              ),
            ),
          ),
          if (index < metrics.length - 1)
            Container(
              width: 1,
              height: 34,
              color: colors.outlineVariant.withValues(alpha: 0.3),
            ),
        ],
      ],
    );
  }
}
