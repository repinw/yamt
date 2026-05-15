import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card_actions.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card_content.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card_display.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal card.
@Dependencies([InventoryItemsController, preparedMealImagePicker])
class PreparedMealCard extends ConsumerStatefulWidget {
  /// The prepared meal card.
  const PreparedMealCard({
    required this.meal,
    required this.onEatPressed,
    required this.onThrowAwayPressed,
    required this.onUnbundlePressed,
    required this.onEditPressed,
    required this.onSaveTemplatePressed,
    super.key,
    this.onFillPendingIngredientPressed,
    this.onIgnorePendingIngredientPressed,
    this.onSelectEditIngredientsPressed,
    this.initiallyExpanded = false,
    this.enabled = true,
  });

  /// The meal.
  final PreparedMeal meal;

  /// The on eat pressed.
  final Future<bool> Function({
    required String mealId,
    required num portions,
    required MealType mealType,
    required DateTime loggedDay,
  })
  onEatPressed;

  /// The on throw away pressed.
  final Future<bool> Function(
    String mealId,
    num portions,
    InventoryDiscardReason reason,
  )
  onThrowAwayPressed;

  /// The on fill pending ingredient pressed.
  final Future<bool> Function(
    String mealId,
    String ingredient,
    List<String> inventoryItemIds,
  )?
  onFillPendingIngredientPressed;

  /// The on ignore pending ingredient pressed.
  final Future<bool> Function(String mealId, String ingredient)?
  onIgnorePendingIngredientPressed;

  /// The on unbundle pressed.
  final Future<bool> Function(String mealId) onUnbundlePressed;

  /// The on edit pressed.
  final Future<bool> Function(String mealId, PreparedMealEditSheetResult result)
  onEditPressed;

  /// The on select edit ingredients pressed.
  final Future<bool> Function(
    String mealId,
    PreparedMealEditSheetResult result,
  )?
  onSelectEditIngredientsPressed;

  /// The on save template pressed.
  final Future<bool> Function(PreparedMeal meal) onSaveTemplatePressed;

  /// The initially expanded.
  final bool initiallyExpanded;

  /// The enabled.
  final bool enabled;

  @override
  ConsumerState<PreparedMealCard> createState() => _PreparedMealCardState();
}

class _PreparedMealCardState extends ConsumerState<PreparedMealCard>
    with PreparedMealCardActions<PreparedMealCard> {
  static const _inventoryItemListEquality = ListEquality<InventoryItem>();
  static const _ingredientListEquality = ListEquality<String>();

  var _isExpanded = false;
  var _isWorking = false;
  PreparedMealDisplayMode _displayMode = PreparedMealDisplayMode.perHundred;
  List<InventoryItem> _cachedSuggestionInventoryItems = const <InventoryItem>[];
  List<String> _cachedPendingIngredients = const <String>[];
  Map<String, List<InventoryItem>> _cachedPendingSuggestions =
      const <String, List<InventoryItem>>{};

  @override
  bool get expandedState => _isExpanded;

  @override
  set expandedState(bool value) => _isExpanded = value;

  @override
  bool get workingState => _isWorking;

  @override
  set workingState(bool value) => _isWorking = value;

  @override
  PreparedMeal get actionMeal => widget.meal;

  @override
  Future<bool> Function({
    required DateTime loggedDay,
    required String mealId,
    required MealType mealType,
    required num portions,
  })
  get eatPressedAction => widget.onEatPressed;

  @override
  Future<bool> Function(
    String mealId,
    num portions,
    InventoryDiscardReason reason,
  )
  get throwAwayPressedAction => widget.onThrowAwayPressed;

  @override
  Future<bool> Function(
    String mealId,
    String ingredient,
    List<String> inventoryItemIds,
  )?
  get fillPendingIngredientPressedAction =>
      widget.onFillPendingIngredientPressed;

  @override
  Future<bool> Function(String mealId, String ingredient)?
  get ignorePendingIngredientPressedAction =>
      widget.onIgnorePendingIngredientPressed;

  @override
  Future<bool> Function(String mealId, PreparedMealEditSheetResult result)
  get editPressedAction => widget.onEditPressed;

  @override
  Future<bool> Function(String mealId, PreparedMealEditSheetResult result)?
  get selectEditIngredientsPressedAction =>
      widget.onSelectEditIngredientsPressed;

  @override
  Future<bool> Function(String mealId) get unbundlePressedAction =>
      widget.onUnbundlePressed;

  @override
  Future<bool> Function(PreparedMeal meal) get saveTemplatePressedAction =>
      widget.onSaveTemplatePressed;

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
    final pendingIngredientSuggestions = _pendingIngredientSuggestions(
      meal: meal,
      inventoryItems: inventoryItems,
    );
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
    final availableDisplayModes = availablePreparedMealDisplayModes(meal);
    final selectedDisplayMode = availableDisplayModes.contains(_displayMode)
        ? _displayMode
        : availableDisplayModes.first;
    final nutritionMetrics = buildPreparedMealNutritionMetrics(
      l10n: l10n,
      meal: meal,
      mode: selectedDisplayMode,
    );
    final priceLabel = preparedMealPriceModeLabel(
      l10n: l10n,
      mode: selectedDisplayMode,
    );
    final priceValue = currency.format(
      resolvePreparedMealPrice(meal: meal, mode: selectedDisplayMode),
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
                PreparedMealCardHeader(
                  meal: meal,
                  imageBytes: storedImageBytes,
                  ingredientCount: ingredientCount,
                  isExpanded: _isExpanded,
                  canEat: canEat,
                  enabled: widget.enabled,
                  onTap: toggleExpanded,
                  onEatPressed: handleEatPressed,
                ),
                SizedBox(height: _isExpanded ? AppSpacing.xxs : 0),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? PreparedMealCardExpandedContent(
                          meal: meal,
                          inventoryItems: inventoryItems,
                          pendingIngredientSuggestions:
                              pendingIngredientSuggestions,
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
                          onFillPendingIngredient: handleFillPendingIngredient,
                          onIgnorePendingIngredient:
                              handleIgnorePendingIngredient,
                          onEditPressed: handleEditPressed,
                          onThrowAwayPressed: handleThrowAwayPressed,
                          onUnbundlePressed: handleUnbundlePressed,
                          onSaveTemplatePressed: handleSaveTemplatePressed,
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

  Map<String, List<InventoryItem>> _pendingIngredientSuggestions({
    required PreparedMeal meal,
    required List<InventoryItem> inventoryItems,
  }) {
    if (_inventoryItemListEquality.equals(
          inventoryItems,
          _cachedSuggestionInventoryItems,
        ) &&
        _ingredientListEquality.equals(
          meal.pendingRecipeIngredients,
          _cachedPendingIngredients,
        )) {
      return _cachedPendingSuggestions;
    }

    final suggestions = <String, List<InventoryItem>>{
      for (final ingredient in meal.pendingRecipeIngredients)
        ingredient: matchInventoryItemsForIngredient(
          ingredient: ingredient,
          inventoryItems: inventoryItems,
          localeCode: Localizations.localeOf(context).languageCode,
        ).take(3).toList(growable: false),
    };
    _cachedSuggestionInventoryItems = List<InventoryItem>.from(
      inventoryItems,
      growable: false,
    );
    _cachedPendingIngredients = List<String>.from(
      meal.pendingRecipeIngredients,
      growable: false,
    );
    _cachedPendingSuggestions = suggestions;
    return suggestions;
  }
}
