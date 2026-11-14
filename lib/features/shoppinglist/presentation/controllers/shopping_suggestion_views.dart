import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_add_offer.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_scope_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_view.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_shelf_choices_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_suggestion_queue_controller.dart';

part 'shopping_suggestion_views.g.dart';

/// The [suggestions] the strip shows: without the products still to buy on
/// the list shown, the pushed back ones behind all others.
@riverpod
List<ShoppingSuggestion> shoppingVisibleSuggestions(
  Ref ref,
  ShoppingSuggestionList suggestions,
) => visibleShoppingSuggestions(
  suggestions.items,
  items: ref.watch(shoppingListControllerProvider).value ?? const [],
  scope: ref.watch(shoppingListScopeControllerProvider),
  pushedBack: ref.watch(shoppingSuggestionQueueControllerProvider),
);

/// What the add sheet offers for the typed [text], in the catalog of
/// [languageCode], matched against the list the addition goes to.
@riverpod
ShoppingAddOffer shoppingAddOfferFor(
  Ref ref, {
  required String text,
  required String languageCode,
  required ShoppingSuggestionList suggestions,
}) => shoppingAddOffer(
  text,
  items: ref.watch(shoppingAddTargetItemsProvider),
  suggestions: suggestions.items,
  catalog: shoppingCatalogIn(languageCode),
  choices: ref.watch(shoppingShelfChoicesControllerProvider).value ?? const {},
);
