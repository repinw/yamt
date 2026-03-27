import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_refs.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_segmented_button_frame.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_segmented_button_style.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_action_dialogs.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_component_avatar.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

class PreparedMealCard extends ConsumerStatefulWidget {
  const PreparedMealCard({
    super.key,
    required this.meal,
    required this.onEatPressed,
    required this.onThrowAwayPressed,
    required this.onUnbundlePressed,
    required this.onEditPressed,
    required this.onSaveTemplatePressed,
    this.enabled = true,
  });

  final PreparedMeal meal;
  final Future<bool> Function(String mealId, int portions, MealType mealType)
  onEatPressed;
  final Future<bool> Function(String mealId, int portions) onThrowAwayPressed;
  final Future<bool> Function(String mealId) onUnbundlePressed;
  final Future<bool> Function(
    String mealId,
    String name,
    bool imageChanged,
    Uint8List? imageBytes,
  )
  onEditPressed;
  final Future<bool> Function(PreparedMeal meal) onSaveTemplatePressed;
  final bool enabled;

  @override
  ConsumerState<PreparedMealCard> createState() => _PreparedMealCardState();
}

class _PreparedMealCardState extends ConsumerState<PreparedMealCard> {
  var _isExpanded = false;
  var _isWorking = false;
  var _nutritionMode = _PreparedMealNutritionMode.perHundred;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final meal = widget.meal;
    final canEat = widget.enabled && !_isWorking && meal.remainingPortions > 0;
    final storedImageBytes = ref
        .watch(localImageBytesProvider(preparedMealImageRef(meal.id)))
        .asData
        ?.value;
    final eatActionColors = AppInventoryEatActionColors.fromColorScheme(colors);
    final availableNutritionModes = _availableNutritionModes(meal);
    final selectedNutritionMode =
        availableNutritionModes.contains(_nutritionMode)
        ? _nutritionMode
        : availableNutritionModes.first;
    final nutritionMetrics = _buildPreparedMealNutritionMetrics(
      l10n: l10n,
      meal: meal,
      mode: selectedNutritionMode,
    );

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? _toggleExpanded : null,
            child: Padding(
              padding: AppInsets.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PreparedMealCover(
                        label: meal.name,
                        imageBytes: storedImageBytes ?? meal.imageBytes,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              l10n.preparedMealIngredientsCount(
                                meal.components.length,
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                l10n.preparedMealPortionsRemaining(
                                  meal.remainingPortions,
                                  meal.totalPortions,
                                ),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _PreparedMealPrimaryActionButton(
                            label: l10n.inventoryItemEatAction,
                            onPressed: canEat ? _onEatPressed : null,
                            actionColors: eatActionColors,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: LinearProgressIndicator(
                            value: meal.remainingRatio,
                            minHeight: 10,
                            backgroundColor: colors.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${meal.totalKcal.toStringAsFixed(0)} '
                        '${l10n.caloriesUnitKcal}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _isExpanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (nutritionMetrics.isNotEmpty) ...[
                                  if (availableNutritionModes.length > 1) ...[
                                    InventorySegmentedButtonFrame(
                                      child: _PreparedMealNutritionModeToggle(
                                        selectedMode: selectedNutritionMode,
                                        availableModes: availableNutritionModes,
                                        onModeChanged: (mode) {
                                          setState(() {
                                            _nutritionMode = mode;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                  InventoryNutritionStrip(
                                    metrics: nutritionMetrics,
                                    colorScheme: colors,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                ...meal.components.map((component) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        PreparedMealComponentAvatar(
                                          key: Key(
                                            'prepared_meal_ingredient_avatar_'
                                            '${component.inventoryItemId}',
                                          ),
                                          label: component.name,
                                          imageUrl: component.imageUrl,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(child: Text(component.name)),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          '${component.usedAmount} '
                                          '${component.usedUnit.code}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isWorking || !widget.enabled
                                        ? null
                                        : _onEditPressed,
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(
                                      l10n.inventoryReceiptReviewEditAction,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed: _isWorking || !widget.enabled
                                        ? null
                                        : _onThrowAwayPressed,
                                    child: Text(
                                      l10n.inventoryItemThrowAwayAction,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _isWorking || !widget.enabled
                                        ? null
                                        : _onUnbundlePressed,
                                    child: Text(
                                      l10n.preparedMealUnbundleAction,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isWorking || !widget.enabled
                                        ? null
                                        : _onSaveTemplatePressed,
                                    icon: const Icon(
                                      Icons.bookmark_add_outlined,
                                    ),
                                    label: Text(
                                      l10n.preparedMealSaveTemplateAction,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onEatPressed() {
    unawaited(_runEatFlow());
  }

  void _onThrowAwayPressed() {
    unawaited(_runThrowAwayFlow());
  }

  void _onEditPressed() {
    unawaited(_runEditFlow());
  }

  void _onUnbundlePressed() {
    unawaited(
      _runAction(
        () => widget.onUnbundlePressed(widget.meal.id),
        failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
      ),
    );
  }

  void _onSaveTemplatePressed() {
    unawaited(
      _runAction(
        () => widget.onSaveTemplatePressed(widget.meal),
        failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
      ),
    );
  }

  Future<void> _runEatFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showPreparedMealEatDialog(context, widget.meal);
    if (!mounted || result == null) {
      return;
    }

    await _runAction(
      () =>
          widget.onEatPressed(widget.meal.id, result.portions, result.mealType),
      failureMessage: l10n.preparedMealActionFailed,
    );
  }

  Future<void> _runEditFlow() async {
    final result = await showPreparedMealEditSheet(
      context: context,
      meal: widget.meal,
    );
    if (!mounted || result == null) {
      return;
    }

    await _runAction(
      () => widget.onEditPressed(
        widget.meal.id,
        result.name,
        result.imageChanged,
        result.imageBytes,
      ),
      failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  Future<void> _runThrowAwayFlow() async {
    final portions = await showPreparedMealPortionDialog(
      context: context,
      meal: widget.meal,
      title: AppLocalizations.of(context)!.preparedMealThrowAwayTitle,
    );
    if (!mounted || portions == null) {
      return;
    }

    await _runAction(
      () => widget.onThrowAwayPressed(widget.meal.id, portions),
      failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  Future<void> _runAction(
    Future<bool> Function() action, {
    required String failureMessage,
  }) async {
    setState(() {
      _isWorking = true;
    });
    final success = await action();
    if (!mounted) {
      return;
    }
    setState(() {
      _isWorking = false;
    });
    if (success) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

enum _PreparedMealNutritionMode { perHundred, perPortion, total }

class _PreparedMealNutritionModeToggle extends StatelessWidget {
  const _PreparedMealNutritionModeToggle({
    required this.selectedMode,
    required this.availableModes,
    required this.onModeChanged,
  });

  final _PreparedMealNutritionMode selectedMode;
  final List<_PreparedMealNutritionMode> availableModes;
  final ValueChanged<_PreparedMealNutritionMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_PreparedMealNutritionMode>(
      expandedInsets: AppInsets.zero,
      showSelectedIcon: false,
      style: inventorySegmentedButtonStyle(context),
      segments: [
        for (final mode in availableModes)
          ButtonSegment<_PreparedMealNutritionMode>(
            value: mode,
            label: Text(_nutritionModeLabel(l10n, mode)),
          ),
      ],
      selected: <_PreparedMealNutritionMode>{selectedMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        onModeChanged(selection.first);
      },
    );
  }
}

List<_PreparedMealNutritionMode> _availableNutritionModes(PreparedMeal meal) {
  return [
    if (_resolvePerHundredAmountBasis(meal) case final _?) ...[
      _PreparedMealNutritionMode.perHundred,
    ],
    if (meal.totalPortions > 0) _PreparedMealNutritionMode.perPortion,
    _PreparedMealNutritionMode.total,
  ];
}

List<InventoryNutritionMetric> _buildPreparedMealNutritionMetrics({
  required AppLocalizations l10n,
  required PreparedMeal meal,
  required _PreparedMealNutritionMode mode,
}) {
  final multiplier = switch (mode) {
    _PreparedMealNutritionMode.perHundred =>
      _resolvePerHundredMultiplier(meal) ?? 0,
    _PreparedMealNutritionMode.perPortion =>
      meal.totalPortions > 0 ? 1 / meal.totalPortions : 0,
    _PreparedMealNutritionMode.total => 1,
  };

  return [
    InventoryNutritionMetric(
      label: l10n.inventoryNutritionCaloriesShortLabel,
      value: (meal.totalKcal * multiplier).round().toString(),
    ),
    InventoryNutritionMetric(
      label: l10n.inventoryNutritionCarbsShortLabel,
      value: '${formatInventoryNutritionValue(meal.totalCarbs * multiplier)}g',
    ),
    InventoryNutritionMetric(
      label: l10n.caloriesProteinLabel,
      value:
          '${formatInventoryNutritionValue(meal.totalProtein * multiplier)}g',
    ),
    InventoryNutritionMetric(
      label: l10n.caloriesFatLabel,
      value: '${formatInventoryNutritionValue(meal.totalFat * multiplier)}g',
    ),
  ];
}

double? _resolvePerHundredMultiplier(PreparedMeal meal) {
  final amountBasis = _resolvePerHundredAmountBasis(meal);
  if (amountBasis == null || amountBasis <= 0) {
    return null;
  }
  return 100 / amountBasis;
}

int? _resolvePerHundredAmountBasis(PreparedMeal meal) {
  if (meal.components.isEmpty) {
    return null;
  }

  final firstUnit = meal.components.first.usedUnit;
  if (firstUnit == InventoryAmountUnit.piece) {
    return null;
  }

  var totalAmount = 0;
  for (final component in meal.components) {
    if (component.usedUnit != firstUnit || component.usedAmount <= 0) {
      return null;
    }
    totalAmount += component.usedAmount;
  }

  if (totalAmount <= 0) {
    return null;
  }
  return totalAmount;
}

String _nutritionModeLabel(
  AppLocalizations l10n,
  _PreparedMealNutritionMode mode,
) {
  return switch (mode) {
    _PreparedMealNutritionMode.perHundred =>
      l10n.preparedMealNutritionModePerHundred,
    _PreparedMealNutritionMode.perPortion =>
      l10n.preparedMealNutritionModePerPortion,
    _PreparedMealNutritionMode.total => l10n.preparedMealNutritionModeTotal,
  };
}

class _PreparedMealPrimaryActionButton extends StatelessWidget {
  const _PreparedMealPrimaryActionButton({
    required this.label,
    required this.onPressed,
    required this.actionColors,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppInventoryEatActionColors actionColors;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InventoryPrimaryActionButton(
      tooltip: label,
      onPressed: onPressed,
      showText: true,
      label: label,
      width: InventoryItemRowConstants.primaryActionWidth,
      height: InventoryItemRowConstants.primaryActionHeight,
      enabledBackgroundColor: actionColors.backgroundColor,
      disabledBackgroundColor: AppInventoryEditorialSurfaces.section(colors),
      enabledBorderColor: actionColors.borderColor,
      disabledBorderColor: AppInventoryEditorialSurfaces.ghostBorder(colors),
      enabledForegroundColor: actionColors.iconColor,
      disabledForegroundColor: colors.onSurfaceVariant,
    );
  }
}
