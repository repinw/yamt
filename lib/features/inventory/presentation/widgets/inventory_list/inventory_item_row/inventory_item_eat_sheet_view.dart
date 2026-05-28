// Internal split file. Public names are imported only by sibling widgets.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_amount_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_quick_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_quick_chip_scroller.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_sheet_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_when_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet_display.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet_hero.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet_input_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet_models.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_nutrition_strip.dart';

class InventoryItemEatSheetView extends StatelessWidget {
  const InventoryItemEatSheetView({required this.data});

  final InventoryItemEatSheetViewData data;

  @override
  Widget build(BuildContext context) {
    return InventoryEatFlowSheetScaffold(
      viewInsetsBottom: data.viewInsetsBottom,
      hero: InventoryItemEatHero(
        itemName: data.hero.itemName,
        eyebrow: data.hero.eyebrow,
        imageUrl: data.hero.imageUrl,
      ),
      confirmActionText: data.footer.confirmActionText,
      confirmButtonKey: const Key(
        'inventory_item_amount_dialog_confirm_button',
      ),
      onConfirm: data.footer.onConfirm,
      children: [
        if (data.nutritionMetrics.isNotEmpty) ...[
          NutritionMetricsStrip(
            metrics: [
              for (final metric in data.nutritionMetrics)
                NutritionMetric(label: metric.label, value: metric.value),
            ],
            highlightedMetricIndex: 0,
            metricValueKeyPrefix: 'inventory_item_nutrition_value',
            metricLabelKeyPrefix: 'inventory_item_nutrition_label',
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        _InventoryItemEatAmountSection(data: data.amountSection),
        if (data.manualPortionSection case final manual?) ...[
          const SizedBox(height: AppSpacing.md),
          _InventoryItemEatManualSection(data: manual),
        ],
        const SizedBox(height: AppSpacing.xxxl),
        _InventoryItemEatWhenSection(data: data.whenSection),
        if (data.inedibleSection case final inedible?) ...[
          const SizedBox(height: AppSpacing.xxxl),
          InventoryItemEatInedibleAmountSection(
            amountController: inedible.controller,
            amountFocusNode: inedible.focusNode,
            amountErrorText: inedible.errorText,
            unitLabel: inedible.unitLabel,
            summaryText: inedible.summaryText,
            isExpanded: inedible.isExpanded,
            onAmountChanged: inedible.onChanged,
            onSubmitted: inedible.onSubmitted,
            onToggleExpanded: inedible.onToggleExpanded,
          ),
        ],
      ],
    );
  }
}

class _InventoryItemEatAmountSection extends StatelessWidget {
  const _InventoryItemEatAmountSection({required this.data});

  final InventoryItemEatSheetAmountSectionData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryEatFlowAmountCard(
          controller: data.controller,
          focusNode: data.focusNode,
          errorText: data.errorText,
          allowFractionalInput: data.allowFractionalInput,
          clearTooltip: data.clearTooltip,
          fieldKey: const Key('inventory_item_amount_dialog_field'),
          clearButtonKey: const Key(
            'inventory_item_amount_dialog_clear_button',
          ),
          trailing: _InventoryItemEatAmountModeSelector(data: data),
          onChanged: data.onChanged,
          onClearAndFocus: data.onClearAndFocus,
          onSubmitted: data.onSubmitted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          data.availableAmountLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (data.quickOptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: InventoryEatFlowQuickChipScroller(
                  children: [
                    for (final option in data.quickOptions)
                      InventoryEatFlowQuickChip(
                        label: option.label,
                        isSelected: data.selectedAmount == option.value,
                        onPressed: () {
                          data.onQuickOptionSelected(option.value);
                        },
                      ),
                  ],
                ),
              ),
              if (data.totalLabel != null) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  data.totalLabel!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ] else if (data.totalLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              data.totalLabel!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InventoryItemEatManualSection extends StatelessWidget {
  const _InventoryItemEatManualSection({required this.data});

  final InventoryItemEatSheetManualPortionSectionData data;

  @override
  Widget build(BuildContext context) {
    return InventoryItemEatSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryItemEatCardTitle(text: data.title),
          const SizedBox(height: AppSpacing.lg),
          InventoryItemEatManualPortionSection(
            amountController: data.controller,
            amountFocusNode: data.focusNode,
            amountErrorText: data.errorText,
            selectedUnit: data.selectedUnit,
            onAmountChanged: data.onAmountChanged,
            onUnitChanged: data.onUnitChanged,
            onSubmitted: data.onSubmitted,
          ),
          if (data.suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            InventoryEatFlowQuickChipScroller(
              children: [
                for (final suggestion in data.suggestions)
                  InventoryEatFlowQuickChip(
                    label: suggestion.label,
                    isSelected:
                        data.selectedUnit == suggestion.unit &&
                        data.controller.text.trim() ==
                            formatInventoryNutritionValue(suggestion.amount),
                    onPressed: () => data.onSuggestionPressed(
                      amount: suggestion.amount,
                      unit: suggestion.unit,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InventoryItemEatWhenSection extends StatelessWidget {
  const _InventoryItemEatWhenSection({required this.data});

  final InventoryItemEatSheetWhenSectionData data;

  @override
  Widget build(BuildContext context) {
    return InventoryEatFlowWhenSection(
      isToday: data.isToday,
      label: data.label,
      selectedMealType: data.selectedMealType,
      loggedAtButtonKey: const Key('inventory_item_logged_at_button'),
      loggedAtCompactKey: const Key('inventory_item_logged_at_compact'),
      loggedAtLabeledKey: const Key('inventory_item_logged_at_labeled'),
      onPickLoggedAt: data.onPickLoggedAt,
      onMealTypeSelected: data.onMealTypeSelected,
    );
  }
}

class _InventoryItemEatAmountModeSelector extends StatelessWidget {
  const _InventoryItemEatAmountModeSelector({required this.data});

  final InventoryItemEatSheetAmountSectionData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: AppDropdownButton<String>(
        key: const Key('inventory_item_amount_mode_dropdown'),
        value: data.selectedModeId,
        isExpanded: true,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        dropdownColor: colors.surfaceContainerHigh,
        icon: Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        items: [
          for (final option in data.modeOptions)
            DropdownMenuItem<String>(
              value: option.id,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) {
          if (value == null) {
            return;
          }
          data.onModeSelected(value);
        },
      ),
    );
  }
}
