import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_sections.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_trip_summary.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_order_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_scope_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_ticks_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_shelf_choices_controller.dart';

part 'shopping_list_view.g.dart';

/// Everything the list page shows, ready to render.
class ShoppingListView {
  /// Creates the view.
  const new({
    required this.scope,
    required this.sections,
    required this.trip,
    required this.scopeCounts,
  });

  /// The list shown.
  final ShoppingListScope scope;

  /// The entries of [scope] as tiles, cart and saved products.
  final ShoppingListSections sections;

  /// What finishing the trip does with the entries of [scope], by their
  /// stored state.
  final ShoppingTripSummary trip;

  /// The entries on each list, for the switch between them.
  final Map<ShoppingListScope, int> scopeCounts;
}

/// The list page as the user sees it: the stored list of the chosen scope,
/// with taps not saved yet, by shelf or by name. Loads and fails with the
/// list.
@riverpod
AsyncValue<ShoppingListView> shoppingListView(Ref ref) {
  final scope = ref.watch(shoppingListScopeControllerProvider);
  final order = ref.watch(shoppingListOrderControllerProvider);
  final choices =
      ref.watch(shoppingShelfChoicesControllerProvider).value ?? const {};
  final ticks = ref.watch(shoppingListTicksControllerProvider);
  return ref.watch(shoppingListControllerProvider).whenData((items) {
    final visible = [
      for (final item in items)
        if (scope.shows(item)) item,
    ];
    return ShoppingListView(
      scope: scope,
      sections: ShoppingListSections(
        visible,
        justTicked: ticks.justTicked,
        pendingDone: ticks.pendingDone,
        byShelf: order == ShoppingListOrder.byShelf,
        choices: choices,
      ),
      trip: ShoppingTripSummary(visible),
      scopeCounts: _countsByScope(items),
    );
  });
}

Map<ShoppingListScope, int> _countsByScope(List<ShoppingListItem> items) => {
  for (final scope in ShoppingListScope.values)
    scope: items.where((item) => !item.isArchived && scope.shows(item)).length,
};

/// The entries of the list an addition goes to: the private list in the
/// private scope, else the household list. Adding merges only within it.
@riverpod
List<ShoppingListItem> shoppingAddTargetItems(Ref ref) {
  final addsPrivate = ref
      .watch(shoppingListScopeControllerProvider)
      .addsPrivate;
  final items = ref.watch(shoppingListControllerProvider).value ?? const [];
  return [
    for (final item in items)
      if (item.isPrivate == addsPrivate) item,
  ];
}
