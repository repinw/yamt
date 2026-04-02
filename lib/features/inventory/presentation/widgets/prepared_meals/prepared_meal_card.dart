import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_segmented_button_frame.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_segmented_button_style.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_action_dialogs.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_component_avatar.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/prepared_meals/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'prepared_meal_card_display.dart';
part 'prepared_meal_card_content.dart';
part 'prepared_meal_card_actions.dart';
part 'prepared_meal_card_pending_ingredient.dart';

const _preparedMealCardLogName = 'PreparedMealCard';

class PreparedMealCard extends ConsumerStatefulWidget {
  const PreparedMealCard({
    super.key,
    required this.meal,
    required this.onEatPressed,
    required this.onThrowAwayPressed,
    required this.onUnbundlePressed,
    required this.onEditPressed,
    required this.onSaveTemplatePressed,
    this.onFillPendingIngredientPressed,
    this.onIgnorePendingIngredientPressed,
    this.initiallyExpanded = false,
    this.enabled = true,
  });

  final PreparedMeal meal;
  final Future<bool> Function(String mealId, int portions, MealType mealType)
  onEatPressed;
  final Future<bool> Function(
    String mealId,
    int portions,
    InventoryDiscardReason reason,
  )
  onThrowAwayPressed;
  final Future<bool> Function(
    String mealId,
    String ingredient,
    List<String> inventoryItemIds,
  )?
  onFillPendingIngredientPressed;
  final Future<bool> Function(String mealId, String ingredient)?
  onIgnorePendingIngredientPressed;
  final Future<bool> Function(String mealId) onUnbundlePressed;
  final Future<bool> Function(
    String mealId,
    String name,
    bool imageChanged,
    Uint8List? imageBytes,
  )
  onEditPressed;
  final Future<bool> Function(PreparedMeal meal) onSaveTemplatePressed;
  final bool initiallyExpanded;
  final bool enabled;

  @override
  ConsumerState<PreparedMealCard> createState() => _PreparedMealCardState();
}

class _PreparedMealCardState extends ConsumerState<PreparedMealCard>
    with _PreparedMealCardActions {
  var _isExpanded = false;
  var _isWorking = false;
  var _displayMode = _PreparedMealDisplayMode.perHundred;

  @override
  bool get expandedState => _isExpanded;

  @override
  set expandedState(bool value) => _isExpanded = value;

  @override
  bool get workingState => _isWorking;

  @override
  set workingState(bool value) => _isWorking = value;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant PreparedMealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.initiallyExpanded && widget.initiallyExpanded) {
      _isExpanded = true;
    }
    if (!_isWorking) {
      return;
    }

    if (_mealAdvanced(oldWidget.meal, widget.meal)) {
      setState(() {
        _isWorking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final meal = widget.meal;
    final canEat =
        widget.enabled &&
        !_isWorking &&
        meal.remainingPortions > 0 &&
        !meal.hasPendingRecipeIngredients;
    final inventoryItems =
        ref.watch(inventoryItemsControllerProvider).asData?.value ??
        const <InventoryItem>[];
    final ingredientCount =
        meal.components.length + meal.pendingRecipeIngredients.length;
    final imageRef = maybeLocalImageAssetRef(meal.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final currency = buildCurrencyFormat(
      locale: l10n.localeName,
      currencyCode: meal.currencyCode,
    );
    final eatActionColors = AppInventoryEatActionColors.fromColorScheme(colors);
    final availableDisplayModes = _availableDisplayModes(meal);
    final selectedDisplayMode = availableDisplayModes.contains(_displayMode)
        ? _displayMode
        : availableDisplayModes.first;
    final nutritionMetrics = _buildPreparedMealNutritionMetrics(
      l10n: l10n,
      meal: meal,
      mode: selectedDisplayMode,
    );
    final priceLabel = _priceModeLabel(l10n: l10n, mode: selectedDisplayMode);
    final priceValue = currency.format(
      _resolvePreparedMealPrice(meal: meal, mode: selectedDisplayMode),
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
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PreparedMealCardHeader(
                  meal: meal,
                  imageBytes: storedImageBytes,
                  ingredientCount: ingredientCount,
                  canEat: canEat,
                  actionColors: eatActionColors,
                  enabled: widget.enabled,
                  onTap: _toggleExpanded,
                  onEatPressed: _onEatPressed,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? _PreparedMealCardExpandedContent(
                          meal: meal,
                          inventoryItems: inventoryItems,
                          colors: colors,
                          isWorking: _isWorking,
                          enabled: widget.enabled,
                          nutritionMetrics: nutritionMetrics,
                          availableDisplayModes: availableDisplayModes,
                          selectedDisplayMode: selectedDisplayMode,
                          priceLabel: priceLabel,
                          priceValue: priceValue,
                          onModeChanged: (mode) {
                            setState(() {
                              _displayMode = mode;
                            });
                          },
                          onFillPendingIngredient: _onFillPendingIngredient,
                          onIgnorePendingIngredient: _onIgnorePendingIngredient,
                          onEditPressed: _onEditPressed,
                          onThrowAwayPressed: _onThrowAwayPressed,
                          onUnbundlePressed: _onUnbundlePressed,
                          onSaveTemplatePressed: _onSaveTemplatePressed,
                          hasFillPendingIngredientAction:
                              widget.onFillPendingIngredientPressed != null,
                          hasIgnorePendingIngredientAction:
                              widget.onIgnorePendingIngredientPressed != null,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _mealAdvanced(PreparedMeal previous, PreparedMeal next) {
    return previous.remainingPortions != next.remainingPortions ||
        previous.name != next.name ||
        previous.imageAssetId != next.imageAssetId ||
        previous.updatedAt != next.updatedAt;
  }
}
