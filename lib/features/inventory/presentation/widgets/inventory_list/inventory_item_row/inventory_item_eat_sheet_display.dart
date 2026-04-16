part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatSectionCard extends StatelessWidget {
  const _InventoryItemEatSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
        boxShadow: [
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

class _InventoryItemEatCardTitle extends StatelessWidget {
  const _InventoryItemEatCardTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InventoryItemEatQuickChip extends StatelessWidget {
  const _InventoryItemEatQuickChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryItemEatQuickChipScroller extends StatelessWidget {
  const _InventoryItemEatQuickChipScroller({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _InventoryItemEatNutritionMetric extends StatelessWidget {
  const _InventoryItemEatNutritionMetric({
    required this.index,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final int index;
  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final valueColor = isHighlighted ? colors.primary : colors.onSurface;
    final valueText = Text(
      key: Key('inventory_item_nutrition_value_$index'),
      value,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: valueColor,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(fit: BoxFit.scaleDown, child: valueText),
        ),
        const SizedBox(height: 6),
        Text(
          key: Key('inventory_item_nutrition_label_$index'),
          label.toUpperCase(),
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.35,
          ),
        ),
      ],
    );
  }
}
