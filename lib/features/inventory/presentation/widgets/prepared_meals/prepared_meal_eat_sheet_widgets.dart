// Internal split file. Public names are imported only by sibling widgets.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_amount_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_hero.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_quick_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_quick_chip_scroller.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum PreparedMealEatAmountMode { portions, grams }

class PreparedMealQuickOption {
  const PreparedMealQuickOption({required this.label, required this.value});

  final String label;
  final num value;
}

class PreparedMealEatHero extends StatelessWidget {
  const PreparedMealEatHero({required this.meal, required this.imageBytes});

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
      fallback: PreparedMealEatHeroFallback(label: meal.name),
    );
  }
}

class PreparedMealEatHeroFallback extends StatelessWidget {
  const PreparedMealEatHeroFallback({required this.label});

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

class PreparedMealEatPortionsSection extends StatelessWidget {
  const PreparedMealEatPortionsSection({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.amountMode,
    required this.canUseGrams,
    required this.selectedAmount,
    required this.quickOptions,
    required this.remainingLabel,
    required this.clearTooltip,
    required this.onAmountModeChanged,
    required this.onChanged,
    required this.onClearAndFocus,
    required this.onSubmitted,
    required this.onQuickOptionSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final PreparedMealEatAmountMode amountMode;
  final bool canUseGrams;
  final num? selectedAmount;
  final List<PreparedMealQuickOption> quickOptions;
  final String remainingLabel;
  final String clearTooltip;
  final ValueChanged<PreparedMealEatAmountMode>? onAmountModeChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearAndFocus;
  final VoidCallback onSubmitted;
  final ValueChanged<num> onQuickOptionSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryEatFlowAmountCard(
          controller: controller,
          focusNode: focusNode,
          errorText: errorText,
          allowFractionalInput: true,
          clearTooltip: clearTooltip,
          fieldKey: const Key('prepared_meal_portions_field'),
          clearButtonKey: const Key('prepared_meal_portions_clear_button'),
          trailing: PreparedMealEatAmountModeSelector(
            amountMode: amountMode,
            canUseGrams: canUseGrams,
            onChanged: onAmountModeChanged,
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
                      isSelected: selectedAmount == option.value,
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

class PreparedMealEatAmountModeSelector extends StatelessWidget {
  const PreparedMealEatAmountModeSelector({
    required this.amountMode,
    required this.canUseGrams,
    required this.onChanged,
  });

  final PreparedMealEatAmountMode amountMode;
  final bool canUseGrams;
  final ValueChanged<PreparedMealEatAmountMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final options = [
      PreparedMealEatAmountMode.portions,
      if (canUseGrams) PreparedMealEatAmountMode.grams,
    ];

    return DropdownButtonHideUnderline(
      child: AppDropdownButton<PreparedMealEatAmountMode>(
        key: const Key('prepared_meal_amount_mode_dropdown'),
        value: amountMode,
        isExpanded: true,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        dropdownColor: colors.surfaceContainerHigh,
        icon: Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        items: [
          for (final option in options)
            DropdownMenuItem<PreparedMealEatAmountMode>(
              value: option,
              child: Text(
                _labelForMode(option, l10n),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) {
          if (value == null) {
            return;
          }
          onChanged?.call(value);
        },
      ),
    );
  }

  String _labelForMode(
    PreparedMealEatAmountMode mode,
    AppLocalizations l10n,
  ) {
    return switch (mode) {
      PreparedMealEatAmountMode.portions => l10n.preparedMealPortionsToUseLabel,
      PreparedMealEatAmountMode.grams => l10n.inventoryItemEatSheetUnitGram,
    };
  }
}
