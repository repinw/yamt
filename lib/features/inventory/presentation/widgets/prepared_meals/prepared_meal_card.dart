import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
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
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

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

class _PreparedMealCardState extends ConsumerState<PreparedMealCard> {
  var _isExpanded = false;
  var _isWorking = false;
  var _displayMode = _PreparedMealDisplayMode.perHundred;

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
                InkWell(
                  onTap: widget.enabled ? _toggleExpanded : null,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PreparedMealCover(
                              label: meal.name,
                              imageBytes: storedImageBytes,
                              imageUrl: meal.imageUrl,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    meal.hasPendingRecipeIngredients
                                        ? '${l10n.preparedMealIngredientsCount(ingredientCount)} • '
                                              // TODO(l10n): Localize incomplete meal label.
                                              'Unvollständig'
                                        : l10n.preparedMealIngredientsCount(
                                            ingredientCount,
                                          ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                child: LinearProgressIndicator(
                                  value: meal.remainingRatio,
                                  minHeight: 10,
                                  backgroundColor:
                                      colors.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              '${meal.totalKcal.toStringAsFixed(0)} '
                              '${l10n.caloriesUnitKcal}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                                if (availableDisplayModes.length > 1) ...[
                                  InventorySegmentedButtonFrame(
                                    child: _PreparedMealDisplayModeToggle(
                                      selectedMode: selectedDisplayMode,
                                      availableModes: availableDisplayModes,
                                      onModeChanged: (mode) {
                                        setState(() {
                                          _displayMode = mode;
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
                                const SizedBox(height: AppSpacing.sm),
                                _PreparedMealPriceCard(
                                  label: priceLabel,
                                  value: priceValue,
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
                              if (meal.hasPendingRecipeIngredients) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  // TODO(l10n): Localize incomplete meal hint.
                                  'Diese Mahlzeit ist noch nicht vollstaendig '
                                  'und kann erst gegessen werden, wenn alle '
                                  'fehlenden Zutaten ergaenzt wurden.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ...meal.pendingRecipeIngredients.map((
                                  ingredient,
                                ) {
                                  final suggestions =
                                      _matchingInventoryItemsForIngredient(
                                        ingredient: ingredient,
                                        inventoryItems: inventoryItems,
                                      ).take(3).toList(growable: false);
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: _PreparedMealPendingIngredientRow(
                                      ingredient: ingredient,
                                      suggestions: suggestions,
                                      onAssignPressed:
                                          !_isWorking &&
                                              widget.enabled &&
                                              widget.onFillPendingIngredientPressed !=
                                                  null
                                          ? () => _onFillPendingIngredient(
                                              ingredient: ingredient,
                                              inventoryItems: inventoryItems,
                                            )
                                          : null,
                                      onIgnorePressed:
                                          !_isWorking &&
                                              widget.enabled &&
                                              widget.onIgnorePendingIngredientPressed !=
                                                  null
                                          ? () => _onIgnorePendingIngredient(
                                              ingredient,
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                              ],
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
                                  child: Text(l10n.preparedMealUnbundleAction),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isWorking || !widget.enabled
                                      ? null
                                      : _onSaveTemplatePressed,
                                  icon: const Icon(Icons.bookmark_add_outlined),
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

  void _onFillPendingIngredient({
    required String ingredient,
    required List<InventoryItem> inventoryItems,
  }) {
    unawaited(
      _runFillPendingIngredientFlow(
        ingredient: ingredient,
        inventoryItems: inventoryItems,
      ),
    );
  }

  void _onIgnorePendingIngredient(String ingredient) {
    unawaited(_runIgnorePendingIngredientFlow(ingredient: ingredient));
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
    final result = await showPreparedMealEatDialog(
      context,
      widget.meal,
      useRootNavigator: false,
    );
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
    log(
      '_runThrowAwayFlow(): opening portion dialog for ${widget.meal.id}',
      name: _preparedMealCardLogName,
    );
    final portions = await showPreparedMealPortionDialog(
      context: context,
      meal: widget.meal,
      title: AppLocalizations.of(context)!.preparedMealThrowAwayTitle,
      useRootNavigator: false,
    );
    if (!mounted || portions == null) {
      log(
        '_runThrowAwayFlow(): portion dialog cancelled for ${widget.meal.id}',
        name: _preparedMealCardLogName,
      );
      return;
    }
    log(
      '_runThrowAwayFlow(): confirmed portions=$portions for ${widget.meal.id}',
      name: _preparedMealCardLogName,
    );

    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    log(
      '_runThrowAwayFlow(): opening reason dialog for ${widget.meal.id}',
      name: _preparedMealCardLogName,
    );
    final reason = await showInventoryDiscardReasonDialog(
      context,
      useRootNavigator: false,
    );
    if (!mounted || reason == null) {
      log(
        '_runThrowAwayFlow(): reason dialog cancelled for ${widget.meal.id}',
        name: _preparedMealCardLogName,
      );
      return;
    }
    log(
      '_runThrowAwayFlow(): confirmed reason=${reason.name} '
      'for ${widget.meal.id}',
      name: _preparedMealCardLogName,
    );

    await _runAction(
      () => widget.onThrowAwayPressed(widget.meal.id, portions, reason),
      failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  Future<void> _runFillPendingIngredientFlow({
    required String ingredient,
    required List<InventoryItem> inventoryItems,
  }) async {
    final selectedItemIds = await _showPendingIngredientSelectionSheet(
      context: context,
      ingredient: ingredient,
      inventoryItems: inventoryItems,
    );
    if (!mounted || selectedItemIds == null || selectedItemIds.isEmpty) {
      return;
    }

    await _runAction(
      () => widget.onFillPendingIngredientPressed!(
        widget.meal.id,
        ingredient,
        selectedItemIds,
      ),
      // TODO(l10n): Localize pending ingredient fill failure text.
      failureMessage: 'Zutat konnte nicht zur Mahlzeit hinzugefuegt werden.',
    );
  }

  Future<void> _runIgnorePendingIngredientFlow({
    required String ingredient,
  }) async {
    await _runAction(
      () =>
          widget.onIgnorePendingIngredientPressed!(widget.meal.id, ingredient),
      // TODO(l10n): Localize pending ingredient ignore failure text.
      failureMessage: 'Zutat konnte nicht ignoriert werden.',
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

  bool _mealAdvanced(PreparedMeal previous, PreparedMeal next) {
    return previous.remainingPortions != next.remainingPortions ||
        previous.name != next.name ||
        previous.imageAssetId != next.imageAssetId ||
        previous.updatedAt != next.updatedAt;
  }
}

class _PreparedMealPendingIngredientRow extends StatelessWidget {
  const _PreparedMealPendingIngredientRow({
    required this.ingredient,
    required this.suggestions,
    this.onAssignPressed,
    this.onIgnorePressed,
  });

  final String ingredient;
  final List<InventoryItem> suggestions;
  final VoidCallback? onAssignPressed;
  final VoidCallback? onIgnorePressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final suggestionNames = suggestions.map((item) => item.name).join(', ');
    final previewImageUrl = suggestions.isEmpty
        ? null
        : suggestions.first.imageUrl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            _PendingIngredientPreview(
              label: ingredient,
              imageUrl: previewImageUrl,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingredient),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    suggestions.isEmpty
                        // TODO(l10n): Localize pending ingredient subtitle.
                        ? 'Noch nicht belegt'
                        : suggestionNames,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onAssignPressed,
              // TODO(l10n): Localize pending ingredient action tooltip.
              tooltip: 'Zutat ergänzen',
              icon: const Icon(Icons.add_link_rounded),
            ),
            IconButton(
              onPressed: onIgnorePressed,
              // TODO(l10n): Localize pending ingredient ignore tooltip.
              tooltip: 'Zutat ignorieren',
              icon: const Icon(Icons.visibility_off_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingIngredientPreview extends StatelessWidget {
  const _PendingIngredientPreview({required this.label, this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 44,
        child: imageUrl == null
            ? ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: colors.onSurfaceVariant,
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

Future<List<String>?> _showPendingIngredientSelectionSheet({
  required BuildContext context,
  required String ingredient,
  required List<InventoryItem> inventoryItems,
}) {
  final sortedItems = inventoryItems
      .where((item) => !item.isFullyConsumed)
      .toList(growable: false);
  sortedItems.sort((left, right) {
    final rightScore = _ingredientMatchScore(
      ingredient: ingredient,
      item: right,
    );
    final leftScore = _ingredientMatchScore(ingredient: ingredient, item: left);
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final draftSelection = <String>{};
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.8;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // TODO(l10n): Localize pending ingredient sheet title.
                      'Zutat aus Inventar ergänzen',
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ingredient,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: sortedItems.isEmpty
                          ? const Center(
                              child: Text('Keine Inventarartikel vorhanden.'),
                            )
                          : ListView.builder(
                              itemCount: sortedItems.length,
                              itemBuilder: (context, index) {
                                final item = sortedItems[index];
                                final isSelected = draftSelection.contains(
                                  item.id,
                                );
                                return CheckboxListTile(
                                  value: isSelected,
                                  contentPadding: EdgeInsets.zero,
                                  secondary: _PendingIngredientPreview(
                                    label: item.name,
                                    imageUrl: item.imageUrl,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    _pendingIngredientInventoryAmount(item),
                                  ),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked ?? false) {
                                        draftSelection.add(item.id);
                                      } else {
                                        draftSelection.remove(item.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Abbrechen'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () => Navigator.of(
                            dialogContext,
                          ).pop(draftSelection.toList(growable: false)),
                          child: const Text('Übernehmen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

List<InventoryItem> _matchingInventoryItemsForIngredient({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
}) {
  final candidates = inventoryItems
      .where((item) => !item.isFullyConsumed)
      .toList(growable: false);
  if (candidates.isEmpty) {
    return const <InventoryItem>[];
  }

  final sortedCandidates = List<InventoryItem>.from(candidates);
  sortedCandidates.sort((left, right) {
    final rightScore = _ingredientMatchScore(
      ingredient: ingredient,
      item: right,
    );
    final leftScore = _ingredientMatchScore(ingredient: ingredient, item: left);
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  return sortedCandidates
      .where(
        (item) => _ingredientMatchScore(ingredient: ingredient, item: item) > 0,
      )
      .toList(growable: false);
}

int _ingredientMatchScore({
  required String ingredient,
  required InventoryItem item,
}) {
  final normalizedIngredient = _normalizeMatchText(ingredient);
  final normalizedItem = _normalizeMatchText(
    '${item.name} ${item.brand ?? ''}',
  );
  if (normalizedIngredient.isEmpty || normalizedItem.isEmpty) {
    return 0;
  }

  var score = 0;
  if (normalizedItem == normalizedIngredient) {
    score += 100;
  }
  if (normalizedItem.contains(normalizedIngredient)) {
    score += 60;
  }
  if (normalizedIngredient.contains(normalizedItem)) {
    score += 30;
  }

  final ingredientTokens = _matchTokens(normalizedIngredient);
  final itemTokens = _matchTokens(normalizedItem);
  for (final token in ingredientTokens) {
    if (itemTokens.contains(token)) {
      score += token.length >= 5 ? 15 : 10;
      continue;
    }
    if (normalizedItem.contains(token)) {
      score += 4;
    }
  }
  return score;
}

String _normalizeMatchText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]+'), ' ').trim();
}

Set<String> _matchTokens(String value) {
  const stopWords = <String>{
    'frisch',
    'frische',
    'frischer',
    'frisches',
    'klein',
    'kleine',
    'kleiner',
    'gross',
    'grosse',
    'grosses',
    'groß',
    'große',
    'großes',
    'etwas',
    'zum',
    'zur',
    'und',
  };
  return value
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.length >= 3 && !stopWords.contains(token))
      .toSet();
}

String _pendingIngredientInventoryAmount(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return '${item.currentAmount} ${item.amountUnit!.code}';
  }
  return '${item.quantity}x';
}

enum _PreparedMealDisplayMode { perHundred, perPortion, total }

class _PreparedMealDisplayModeToggle extends StatelessWidget {
  const _PreparedMealDisplayModeToggle({
    required this.selectedMode,
    required this.availableModes,
    required this.onModeChanged,
  });

  final _PreparedMealDisplayMode selectedMode;
  final List<_PreparedMealDisplayMode> availableModes;
  final ValueChanged<_PreparedMealDisplayMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_PreparedMealDisplayMode>(
      expandedInsets: AppInsets.zero,
      showSelectedIcon: false,
      style: inventorySegmentedButtonStyle(context),
      segments: [
        for (final mode in availableModes)
          ButtonSegment<_PreparedMealDisplayMode>(
            value: mode,
            label: Text(_displayModeLabel(l10n, mode)),
          ),
      ],
      selected: <_PreparedMealDisplayMode>{selectedMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        onModeChanged(selection.first);
      },
    );
  }
}

List<_PreparedMealDisplayMode> _availableDisplayModes(PreparedMeal meal) {
  return [
    if (meal.perHundredAmountBasis != null) ...[
      _PreparedMealDisplayMode.perHundred,
    ],
    if (meal.totalPortions > 0) _PreparedMealDisplayMode.perPortion,
    _PreparedMealDisplayMode.total,
  ];
}

List<InventoryNutritionMetric> _buildPreparedMealNutritionMetrics({
  required AppLocalizations l10n,
  required PreparedMeal meal,
  required _PreparedMealDisplayMode mode,
}) {
  final multiplier = _resolvePreparedMealDisplayMultiplier(
    meal: meal,
    mode: mode,
  );

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

double _resolvePreparedMealPrice({
  required PreparedMeal meal,
  required _PreparedMealDisplayMode mode,
}) {
  return meal.totalPrice *
      _resolvePreparedMealDisplayMultiplier(meal: meal, mode: mode);
}

double _resolvePreparedMealDisplayMultiplier({
  required PreparedMeal meal,
  required _PreparedMealDisplayMode mode,
}) {
  return switch (mode) {
    _PreparedMealDisplayMode.perHundred => meal.perHundredMultiplier ?? 0,
    _PreparedMealDisplayMode.perPortion =>
      meal.totalPortions > 0 ? 1 / meal.totalPortions : 0,
    _PreparedMealDisplayMode.total => 1,
  };
}

String _displayModeLabel(AppLocalizations l10n, _PreparedMealDisplayMode mode) {
  return switch (mode) {
    _PreparedMealDisplayMode.perHundred =>
      l10n.preparedMealNutritionModePerHundred,
    _PreparedMealDisplayMode.perPortion =>
      l10n.preparedMealNutritionModePerPortion,
    _PreparedMealDisplayMode.total => l10n.preparedMealNutritionModeTotal,
  };
}

String _priceModeLabel({
  required AppLocalizations l10n,
  required _PreparedMealDisplayMode mode,
}) {
  return switch (mode) {
    _PreparedMealDisplayMode.perHundred => l10n.preparedMealPricePerHundred,
    _PreparedMealDisplayMode.perPortion => l10n.preparedMealPricePerPortion,
    _PreparedMealDisplayMode.total => l10n.preparedMealPriceTotal,
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

class _PreparedMealPriceCard extends StatelessWidget {
  const _PreparedMealPriceCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = Color.alphaBlend(
      colors.secondary.withValues(alpha: 0.05),
      colors.surfaceContainerLowest,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          InventoryItemRowConstants.nutritionStripRadius,
        ),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
