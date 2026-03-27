import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_creation_coordinator.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _deleteUndoSnackBarDuration = Duration(seconds: 4);

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen(inventoryItemsControllerProvider, _logLoadErrorOnce);
    ref.listen(
      preparedMealSelectionControllerProvider.select(
        (state) => state.bindRequestToken,
      ),
      _onCreatePreparedMealRequested,
    );

    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final itemsAsync = ref.watch(inventoryItemsControllerProvider);
    final mealsController = ref.read(preparedMealsControllerProvider.notifier);
    final mealsAsync = ref.watch(preparedMealsControllerProvider);
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);

    if (itemsAsync.isLoading || mealsAsync.isLoading) {
      return const _InventoryLoadingView();
    }

    final itemsError = itemsAsync.asError;
    final mealsError = mealsAsync.asError;
    if (itemsError != null || mealsError != null) {
      return _InventoryErrorView(
        onRetry: () async {
          await controller.refresh();
          await mealsController.refresh();
        },
        message: l10n.inventoryLoadFailed,
        retryLabel: l10n.inventoryRetryAction,
      );
    }

    final items = itemsAsync.value ?? const <InventoryItem>[];
    final meals = mealsAsync.value ?? const <PreparedMeal>[];

    return InventoryList(
      items: items,
      preparedMeals: meals,
      onDeleteItem: (itemId) =>
          _deleteItemWithUndo(context: context, ref: ref, itemId: itemId),
      onEatItem: (itemId, amount) => _eatItemWithCalorieBridge(
        context: context,
        ref: ref,
        itemId: itemId,
        amount: amount,
        itemsSnapshot: items,
      ),
      onThrowAwayItem: controller.throwAwayItem,
      onEatPreparedMeal: (mealId, portions, mealType) => ref
          .read(preparedMealsControllerProvider.notifier)
          .consumePreparedMeal(
            mealId: mealId,
            consumedPortions: portions,
            mealType: mealType,
          ),
      onThrowAwayPreparedMeal: (mealId, portions) => ref
          .read(preparedMealsControllerProvider.notifier)
          .throwAwayPreparedMeal(mealId: mealId, discardedPortions: portions),
      onUnbundlePreparedMeal: ref
          .read(preparedMealsControllerProvider.notifier)
          .unbundlePreparedMeal,
      onEditPreparedMeal: (mealId, name, imageBase64) => _updatePreparedMeal(
        context: context,
        ref: ref,
        mealId: mealId,
        name: name,
        imageBase64: imageBase64,
      ),
      onSavePreparedMealTemplate: (meal) =>
          _savePreparedMealTemplate(context: context, ref: ref, meal: meal),
      isSelectionMode: selectionState.isSelectionMode,
      selectedItemIds: selectionState.selectedItemIds,
      onItemLongPress: (itemId) {
        ref
            .read(preparedMealSelectionControllerProvider.notifier)
            .enterSelection(itemId);
      },
      onSelectionToggle: (itemId) {
        ref
            .read(preparedMealSelectionControllerProvider.notifier)
            .toggleSelection(itemId);
      },
    );
  }

  Future<void> _onCreatePreparedMealRequested(int? previous, int next) async {
    if (previous == next || next < 1) {
      return;
    }
    await runPreparedMealCreationFlow(context: context, ref: ref);
  }

  Future<bool> _savePreparedMealTemplate({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
  }) async {
    final saved = await ref
        .read(preparedMealTemplatesControllerProvider.notifier)
        .saveTemplateFromMeal(meal);
    if (!saved || !context.mounted) {
      return saved;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.preparedMealTemplateSavedMessage,
        ),
      ),
    );
    return true;
  }

  Future<bool> _updatePreparedMeal({
    required BuildContext context,
    required WidgetRef ref,
    required String mealId,
    required String name,
    required String? imageBase64,
  }) async {
    final saved = await ref
        .read(preparedMealsControllerProvider.notifier)
        .updatePreparedMealDetails(
          mealId: mealId,
          name: name,
          imageBase64: imageBase64,
        );
    if (!saved || !context.mounted) {
      return saved;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.preparedMealUpdatedMessage),
      ),
    );
    return true;
  }

  Future<bool> _deleteItemWithUndo({
    required BuildContext context,
    required WidgetRef ref,
    required String itemId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final deleted = await controller.deleteItem(itemId);
    if (!deleted || !context.mounted) {
      return deleted;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: _deleteUndoSnackBarDuration,
        persist: false,
        content: Text(l10n.inventoryItemDeletedMessage),
        action: SnackBarAction(
          label: l10n.commonUndoAction,
          onPressed: () {
            unawaited(_undoDelete(context: context, ref: ref));
          },
        ),
      ),
    );
    return true;
  }

  void _logLoadErrorOnce(
    AsyncValue<List<InventoryItem>>? previous,
    AsyncValue<List<InventoryItem>> next,
  ) {
    final nextError = next.asError;
    if (nextError == null) {
      return;
    }

    final previousError = previous?.asError;
    final unchangedError = identical(previousError?.error, nextError.error);
    final unchangedStack = previousError?.stackTrace == nextError.stackTrace;
    if (unchangedError && unchangedStack) {
      return;
    }

    developer.log(
      'Failed to load inventory items.',
      name: 'InventoryPage',
      error: nextError.error,
      stackTrace: nextError.stackTrace,
    );
  }

  Future<void> _undoDelete({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final restored = await ref
        .read(inventoryItemsControllerProvider.notifier)
        .undoLastDeletedItem();
    if (!context.mounted) {
      return;
    }
    if (restored) {
      messenger.hideCurrentSnackBar();
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.inventoryItemActionFailed)),
    );
  }

  Future<bool> _eatItemWithCalorieBridge({
    required BuildContext context,
    required WidgetRef ref,
    required String itemId,
    required int amount,
    required List<InventoryItem> itemsSnapshot,
  }) async {
    InventoryItem? selectedItem;
    for (final item in itemsSnapshot) {
      if (item.id == itemId) {
        selectedItem = item;
        break;
      }
    }

    final saved = await ref
        .read(inventoryItemsControllerProvider.notifier)
        .eatItem(itemId, amount);
    if (!saved || selectedItem == null || !context.mounted) {
      return saved;
    }

    unawaited(
      InventoryCalorieBridgeFlow.onEatCompleted(
        context: context,
        ref: ref,
        itemBeforeMutation: selectedItem,
        consumedAmount: amount,
      ),
    );
    return true;
  }
}

class _InventoryLoadingView extends StatelessWidget {
  const _InventoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: AppSizes.inlineProgressIndicator,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.progressStrokeWidth,
        ),
      ),
    );
  }
}

class _InventoryErrorView extends StatelessWidget {
  const _InventoryErrorView({
    required this.onRetry,
    required this.message,
    required this.retryLabel,
  });

  final Future<void> Function() onRetry;
  final String message;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardRadius = BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return Center(
      child: Padding(
        padding: AppInsets.pageLarge,
        child: DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: cardRadius,
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_tethering_error_rounded,
                  color: colors.error,
                  size: AppSizes.welcomeIcon * 0.45,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
