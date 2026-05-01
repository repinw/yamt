part of 'prepared_meal_action_dialogs.dart';

class _PreparedMealQuickOption {
  const _PreparedMealQuickOption({required this.label, required this.value});

  final String label;
  final int value;
}

class _PreparedMealEatHero extends StatelessWidget {
  const _PreparedMealEatHero({required this.meal, required this.imageBytes});

  final PreparedMeal meal;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InventoryEatFlowHero(
      title: meal.name,
      eyebrow: l10n.preparedMealEatTitle,
      imageUrl: meal.imageUrl,
      imageBytes: imageBytes,
      imageKey: const Key('prepared_meal_eat_sheet_hero_cover'),
      cancelButtonKey: const Key('prepared_meal_eat_cancel_button'),
      fallback: _PreparedMealEatHeroFallback(label: meal.name),
    );
  }
}

class _PreparedMealEatHeroFallback extends StatelessWidget {
  const _PreparedMealEatHeroFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PreparedMealEatPortionsSection extends StatelessWidget {
  const _PreparedMealEatPortionsSection({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.selectedPortions,
    required this.quickOptions,
    required this.remainingLabel,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClearAndFocus,
    required this.onSubmitted,
    required this.onQuickOptionSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final int? selectedPortions;
  final List<_PreparedMealQuickOption> quickOptions;
  final String remainingLabel;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearAndFocus;
  final VoidCallback onSubmitted;
  final ValueChanged<int> onQuickOptionSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryEatFlowAmountCard(
          controller: controller,
          focusNode: focusNode,
          errorText: errorText,
          allowFractionalInput: false,
          clearTooltip: clearTooltip,
          fieldKey: const Key('prepared_meal_portions_field'),
          clearButtonKey: const Key('prepared_meal_portions_clear_button'),
          trailing: _PreparedMealEatPortionLabel(
            label: l10n.preparedMealPortionsToUseLabel,
          ),
          onChanged: onChanged,
          onClearAndFocus: onClearAndFocus,
          onSubmitted: onSubmitted,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: InventoryEatFlowQuickChipScroller(
                children: [
                  for (final option in quickOptions)
                    InventoryEatFlowQuickChip(
                      label: option.label,
                      isSelected: selectedPortions == option.value,
                      onPressed: () => onQuickOptionSelected(option.value),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              remainingLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreparedMealEatPortionLabel extends StatelessWidget {
  const _PreparedMealEatPortionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
