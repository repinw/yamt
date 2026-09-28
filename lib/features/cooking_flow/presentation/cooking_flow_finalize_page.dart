import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/presentation/models/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_text_styles.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_weight_input_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Finalize step for cookflow.
class CookingFlowFinalizePage extends StatelessWidget {
  /// Creates finalize step.
  const new({
    required this.storageContainers,
    required this.containerPortions,
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

  /// Portions saved per container, aligned with [storageContainers].
  final List<int> containerPortions;

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
    final colors = FoodLabelColors.of(context);
    final schemeColors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final roundedPortions = portionCount.round();
    // The default follows the intro target, which can exceed six portions.
    final sliderMax = math.max(6, roundedPortions);
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
          containerPortions: containerPortions,
          validationMessage: validationMessage,
          isWeightValid: isWeightValid,
          onContainerChanged: onContainerChanged,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.rule),
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
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Switch(
                      value: splitIntoPortions,
                      onChanged: onSplitIntoPortionsChanged,
                      activeThumbColor: colors.paper,
                      activeTrackColor: colors.ink,
                      inactiveThumbColor: colors.muted,
                      inactiveTrackColor: colors.tile,
                      trackOutlineColor: WidgetStatePropertyAll<Color>(
                        colors.rule,
                      ),
                    ),
                  ],
                ),
                if (splitIntoPortions) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Divider(height: 1, color: colors.rule),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.cookflowHowManyPortions.toUpperCase(),
                    style: context.cookingFlowKickerStyle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colors.ink,
                            inactiveTrackColor: colors.rule,
                            thumbColor: colors.ink,
                            overlayColor: colors.ink.withValues(
                              alpha: AppFoodLabel.sliderOverlayAlpha,
                            ),
                          ),
                          child: Slider(
                            value: portionCount,
                            min: 1,
                            max: sliderMax.toDouble(),
                            divisions: sliderMax - 1,
                            onChanged: onPortionCountChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Text(
                        '$roundedPortions',
                        style: context.cookingFlowDisplayStyle(
                          textTheme.headlineMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
                    colorScheme: schemeColors,
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
  const new({
    required this.containers,
    required this.containerPortions,
    required this.validationMessage,
    required this.isWeightValid,
    required this.onContainerChanged,
  });

  final List<CookingFlowStorageContainerView> containers;
  final List<int> containerPortions;
  final String? validationMessage;
  final bool isWeightValid;
  final ValueChanged<String> onContainerChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final schemeColors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.cookflowStorageContainersTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: colors.ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < containers.length; index++) ...[
          _FinalizeStorageContainerCard(
            container: containers[index],
            index: index,
            portions: containers.length > 1 && index < containerPortions.length
                ? containerPortions[index]
                : null,
            isWeightValid: isWeightValid,
            onContainerChanged: onContainerChanged,
          ),
          if (index < containers.length - 1)
            const SizedBox(height: AppSpacing.lg),
        ],
        if (validationMessage case final String message) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: schemeColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// One container to weigh: name, tare, the gross weight field and the net
/// weight as the large number. Square box with a thin rule.
class _FinalizeStorageContainerCard extends StatelessWidget {
  const new({
    required this.container,
    required this.index,
    required this.portions,
    required this.isWeightValid,
    required this.onContainerChanged,
  });

  final CookingFlowStorageContainerView container;
  final int index;

  /// Portions this container gets; null when there is only one container.
  final int? portions;
  final bool isWeightValid;
  final ValueChanged<String> onContainerChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final schemeColors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final taraWeight = _parseWeight(container.taraController.text);
    final grossWeight = _parseWeight(container.grossWeightController.text);
    final netWeight = grossWeight <= taraWeight ? 0 : grossWeight - taraWeight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.rule),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: AppGraphit.badge,
                  height: AppGraphit.badge,
                  color: colors.tile,
                  child: Icon(
                    Icons.kitchen_rounded,
                    color: colors.ink,
                    size: AppGraphit.toolIcon,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _containerLabel(l10n, container, index),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.cookingFlowDisplayStyle(
                      textTheme.titleLarge,
                    ),
                  ),
                ),
                if (portions case final int count) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.cookflowContainerPortionsLabel(count),
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: <Widget>[
                Text(
                  l10n.cookflowContainerTaraLabel,
                  style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                ),
                const Spacer(),
                Text(
                  '${taraWeight.toStringAsFixed(0)} g',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.cookflowGrossWeightTitle.toUpperCase(),
              style: context.cookingFlowKickerStyle,
            ),
            const SizedBox(height: AppSpacing.xs),
            CookingFlowWeightInputRow(
              controller: container.grossWeightController,
              unitLabel: l10n.cookflowGramUnit,
              hintText: l10n.cookflowGrossWeightHint,
              onChanged: onContainerChanged,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  l10n.cookflowNetWeightLabel,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${netWeight.toStringAsFixed(0)} g',
                  style: context.cookingFlowDisplayStyle(
                    textTheme.headlineMedium,
                    color: isWeightValid ? colors.ink : schemeColors.error,
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
