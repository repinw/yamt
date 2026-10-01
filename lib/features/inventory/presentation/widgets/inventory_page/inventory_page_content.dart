import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_detail_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_activity_timeline/inventory_activity_timeline.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_error_view.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_loading_view.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_page_lifecycle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_view_toggle_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Builds the inventory page content and coordinates its UI controllers.
class InventoryPageContent extends ConsumerWidget {
  /// Creates inventory page content.
  const new({
    required this.isShowingHistory,
    required this.onToggleView,
    this.includeHomeShellChrome = false,
    super.key,
  });

  /// Whether the activity history is visible.
  final bool isShowingHistory;

  /// Toggles between stock and history.
  final VoidCallback onToggleView;

  /// Whether to render home-shell chrome.
  final bool includeHomeShellChrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..listen(inventoryItemsControllerProvider, logInventoryPageLoadError)
      ..listen(
        preparedMealSelectionControllerProvider.select(
          (state) => state.bindRequestToken,
        ),
        (previous, next) => handleInventoryPageSelectionConfirmed(
          context: context,
          ref: ref,
          previous: previous,
          next: next,
        ),
      );

    final l10n = AppLocalizations.of(context)!;
    final topChromeActions = [
      InventoryViewToggleButton(
        isShowingStock: !isShowingHistory,
        onToggle: onToggleView,
      ),
    ];

    if (isShowingHistory) {
      return InventoryActivityTimeline(
        includeHomeShellChrome: includeHomeShellChrome,
        topChromeActions: topChromeActions,
      );
    }

    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final itemsAsync = ref.watch(inventoryItemsControllerProvider);
    final mealsController = ref.read(preparedMealsControllerProvider.notifier);
    final mealsAsync = ref.watch(preparedMealsControllerProvider);
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);

    if (itemsAsync.isLoading || mealsAsync.isLoading) {
      return InventoryLoadingView(
        includeHomeShellChrome: includeHomeShellChrome,
        topChromeActions: topChromeActions,
      );
    }

    final itemsError = itemsAsync.asError;
    final mealsError = mealsAsync.asError;
    if (itemsError != null || mealsError != null) {
      return InventoryErrorView(
        onRetry: () async {
          await controller.refresh();
          await mealsController.refresh();
        },
        message: l10n.inventoryLoadFailed,
        retryLabel: l10n.inventoryRetryAction,
        includeHomeShellChrome: includeHomeShellChrome,
        topChromeActions: topChromeActions,
      );
    }

    return InventoryList(
      includeHomeShellChrome: includeHomeShellChrome,
      topChromeActions: topChromeActions,
      onOpenMeal: (meal) => unawaited(
        PreparedMealDetailFlow.open(context: context, ref: ref, meal: meal),
      ),
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
}
