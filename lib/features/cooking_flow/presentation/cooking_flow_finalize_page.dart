import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_weight_input_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Finalize step for cookflow.
class CookingFlowFinalizePage extends StatelessWidget {
  /// Creates finalize step.
  const CookingFlowFinalizePage({
    required this.storageContainers,
    required this.isWeightValid,
    required this.nutritionPreview,
    required this.splitIntoPortions,
    required this.validationMessage,
    required this.portionCount,
    required this.onContainerChanged,
    required this.onSplitIntoPortionsChanged,
    required this.onPortionCountChanged,
    super.key,
  });

  /// Final storage containers.
  final List<CookingFlowStorageContainerView> storageContainers;

  /// Whether current entered weights are valid.
  final bool isWeightValid;

  /// Preview nutrition for the currently selected cookflow result.
  final CookingFlowNutritionPreview nutritionPreview;

  /// Whether meal is split into portions.
  final bool splitIntoPortions;

  /// Inline validation message shown below weight card.
  final String? validationMessage;

  /// Selected portion count.
  final double portionCount;

  /// Called when any container text field changes.
  final ValueChanged<String> onContainerChanged;

  /// Portion toggle callback.
  final ValueChanged<bool> onSplitIntoPortionsChanged;

  /// Portion slider callback.
  final ValueChanged<double> onPortionCountChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final roundedPortions = portionCount.round();
    final caloriesValue =
        '${nutritionPreview.kcal.toNutritionMetricValue()} kcal';
    final carbsValue = '${nutritionPreview.carbs.toNutritionMetricValue()}g';
    final proteinValue =
        '${nutritionPreview.protein.toNutritionMetricValue()}g';
    final fatValue = '${nutritionPreview.fat.toNutritionMetricValue()}g';

    return CookingFlowStepLayout(
      title: l10n.cookflowFinalizeTitle,
      subtitle: l10n.cookflowFinalizeBody,
      children: <Widget>[
        _FinalizeStorageContainersSection(
          containers: storageContainers,
          validationMessage: validationMessage,
          isWeightValid: isWeightValid,
          onContainerChanged: onContainerChanged,
        ),
        const SizedBox(height: AppSpacing.xxxxl),
        DecoratedBox(
          decoration: AppEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(
              AppEditorial.cardRadius,
            ),
            blurRadius: 22,
            shadowOffset: const Offset(0, 10),
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.cookflowSplitIntoPortionsLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Switch(
                      value: splitIntoPortions,
                      onChanged: onSplitIntoPortionsChanged,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppSeedColors.orange,
                    ),
                  ],
                ),
                if (splitIntoPortions) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Divider(
                    height: 1,
                    color: colors.outlineVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.cookflowHowManyPortions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppSeedColors.orange,
                            inactiveTrackColor: colors.outlineVariant,
                            thumbColor: Colors.grey.shade700,
                          ),
                          child: Slider(
                            value: portionCount,
                            min: 1,
                            max: 6,
                            divisions: 5,
                            onChanged: onPortionCountChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Text(
                        '$roundedPortions',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  NutritionMetricsStrip(
                    metrics: <NutritionMetric>[
                      NutritionMetric(
                        label: l10n.cookflowCaloriesShortLabel,
                        value: caloriesValue,
                      ),
                      NutritionMetric(
                        label: l10n.cookflowCarbsShortLabel,
                        value: carbsValue,
                      ),
                      NutritionMetric(
                        label: l10n.cookflowProteinShortLabel,
                        value: proteinValue,
                      ),
                      NutritionMetric(
                        label: l10n.cookflowFatShortLabel,
                        value: fatValue,
                      ),
                    ],
                    colorScheme: colors,
                    highlightedMetricIndex: 0,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FinalizeStorageContainersSection extends StatelessWidget {
  const _FinalizeStorageContainersSection({
    required this.containers,
    required this.validationMessage,
    required this.isWeightValid,
    required this.onContainerChanged,
  });

  final List<CookingFlowStorageContainerView> containers;
  final String? validationMessage;
  final bool isWeightValid;
  final ValueChanged<String> onContainerChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: AppEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppEditorial.cardRadius),
        blurRadius: 22,
        shadowOffset: const Offset(0, 10),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  l10n.cookflowStorageContainersTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var index = 0; index < containers.length; index++) ...[
              _FinalizeStorageContainerCard(
                container: containers[index],
                index: index,
                isWeightValid: isWeightValid,
                onContainerChanged: onContainerChanged,
              ),
              if (index < containers.length - 1)
                const SizedBox(height: AppSpacing.xxl),
            ],
            if (validationMessage case final String message) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinalizeStorageContainerCard extends StatelessWidget {
  const _FinalizeStorageContainerCard({
    required this.container,
    required this.index,
    required this.isWeightValid,
    required this.onContainerChanged,
  });

  final CookingFlowStorageContainerView container;
  final int index;
  final bool isWeightValid;
  final ValueChanged<String> onContainerChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final taraWeight = _parseWeight(container.taraController.text);
    final grossWeight = _parseWeight(container.grossWeightController.text);
    final netWeight = grossWeight <= taraWeight ? 0 : grossWeight - taraWeight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.kitchen_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _containerLabel(l10n, container, index),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: <Widget>[
                Text(
                  l10n.cookflowContainerTaraLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${taraWeight.toStringAsFixed(0)} g',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.cookflowGrossWeightTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CookingFlowWeightInputRow(
              controller: container.grossWeightController,
              unitLabel: l10n.cookflowGramUnit,
              hintText: l10n.cookflowGrossWeightHint,
              onChanged: onContainerChanged,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: <Widget>[
                Text(
                  l10n.cookflowNetWeightLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${netWeight.toStringAsFixed(0)} g',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isWeightValid ? AppSeedColors.orange : colors.error,
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

String _containerLabel(
  AppLocalizations l10n,
  CookingFlowStorageContainerView container,
  int index,
) {
  final label = container.labelController.text.trim();
  if (label.isNotEmpty) {
    return label;
  }
  return l10n.cookflowContainerNameHint(index + 1);
}

double _parseWeight(String value) {
  return parseCookingFlowQuantity(value) ?? 0;
}
