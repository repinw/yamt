import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/product_search/application/'
    'product_ai_nutrition_selection.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_input.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kcal density adjustment card for AI nutrition.
class AiDensityAdjustCard extends StatelessWidget {
  /// Creates a density adjustment card.
  const AiDensityAdjustCard({
    required this.selection,
    required this.onChanged,
    super.key,
  });

  /// Current nutrition selection.
  final ProductAiNutritionSelection selection;

  /// Called when kcal density changes.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryManualAddAiSearchDensityTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.inventoryManualAddAiSearchDensityHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Slider(
              key: const Key('manual_product_ai_density_slider'),
              value: selection.per100Kcal,
              min: selection.minPer100Kcal,
              max: selection.maxPer100Kcal,
              onChanged: onChanged,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.inventoryManualAddAiSearchDensityMinLabel(
                      formatManualProductDouble(selection.minPer100Kcal),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  l10n.inventoryManualAddAiSearchDensityBaseLabel(
                    formatManualProductDouble(selection.basePer100Kcal),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.inventoryManualAddAiSearchDensityMaxLabel(
                      formatManualProductDouble(selection.maxPer100Kcal),
                    ),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Weight input field for AI portion calculation.
class AiWeightField extends StatelessWidget {
  /// Creates an AI weight field.
  const AiWeightField({
    required this.controller,
    required this.errorText,
    required this.labelText,
    required this.onChanged,
    super.key,
  });

  /// Weight text controller.
  final TextEditingController controller;

  /// Error text.
  final String? errorText;

  /// Field label.
  final String labelText;

  /// Called when value changes.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: TextField(
        key: const Key('manual_product_ai_weight_field'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          manualProductSingleDecimalInputFormatter,
        ],
        textAlign: TextAlign.end,
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          suffixText: 'g',
          errorText: errorText,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
