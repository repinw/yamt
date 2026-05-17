import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Home-shell top chrome for the inventory tab.
class InventoryHomeShellTopChrome extends ConsumerWidget {
  /// Creates inventory top chrome.
  const InventoryHomeShellTopChrome({
    super.key,
    this.actions = const <Widget>[],
  });

  /// Tab-owned actions.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);
    return HomeShellTabTopChrome(
      title: selectionState.isSelectionMode
          ? l10n.preparedMealSelectionCount(selectionState.selectedCount)
          : l10n.inventoryPageTitle,
      actions: _buildActions(context, ref, l10n, selectionState),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
  ) {
    if (selectionState.isSelectionMode) {
      return _buildSelectionActions(
        ref,
        l10n,
        selectionState,
        shouldUseCompactHomeChrome(context),
      );
    }

    return [
      ...actions,
      IconButton(
        tooltip: l10n.homeShopping,
        onPressed: () => context.push(AppRoutes.homeShopping),
        icon: const Icon(Icons.shopping_cart_rounded),
      ),
    ];
  }

  List<Widget> _buildSelectionActions(
    WidgetRef ref,
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
    bool useCompactSelectionActions,
  ) {
    final isAddingIngredients = selectionState.isAddingIngredientsToMeal;
    final selectionActionLabel = isAddingIngredients
        ? l10n.preparedMealAddIngredientAction
        : l10n.preparedMealBindAction;
    final selectionActionIcon = isAddingIngredients
        ? Icons.add_rounded
        : Icons.restaurant_menu_rounded;
    final canConfirmSelection =
        selectionState.selectedCount >= (isAddingIngredients ? 1 : 2);

    if (useCompactSelectionActions) {
      return [
        IconButton(
          tooltip: l10n.inventoryReceiptReviewCancelAction,
          onPressed: () {
            ref
                .read(preparedMealSelectionControllerProvider.notifier)
                .clearSelection();
          },
          icon: const Icon(Icons.close_rounded),
        ),
        IconButton.filledTonal(
          tooltip: selectionActionLabel,
          onPressed: canConfirmSelection
              ? () {
                  ref
                      .read(preparedMealSelectionControllerProvider.notifier)
                      .confirmSelection();
                }
              : null,
          icon: Icon(selectionActionIcon),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () {
          ref
              .read(preparedMealSelectionControllerProvider.notifier)
              .clearSelection();
        },
        child: Text(l10n.inventoryReceiptReviewCancelAction),
      ),
      FilledButton.tonalIcon(
        onPressed: canConfirmSelection
            ? () {
                ref
                    .read(preparedMealSelectionControllerProvider.notifier)
                    .confirmSelection();
              }
            : null,
        icon: Icon(selectionActionIcon),
        label: Text(selectionActionLabel),
      ),
    ];
  }
}
