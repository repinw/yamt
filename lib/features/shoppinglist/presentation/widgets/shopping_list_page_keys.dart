import 'package:material_ui/material_ui.dart';

/// Defines shopping list page keys.
class ShoppingListPageKeys {
  const new _();

  /// The line that counts the entries in the cart.
  static const progressLabel = Key('shopping_list_progress_label');

  /// The button that opens the add dialog.
  static const addButton = Key('shopping_list_add_button');

  /// The button that finishes the shopping trip.
  static const finishButton = Key('shopping_list_finish_button');

  /// The confirm button of the finish dialog.
  static const finishConfirmButton = Key('shopping_list_finish_confirm_button');

  /// The cancel button of the finish dialog.
  static const finishCancelButton = Key('shopping_list_finish_cancel_button');

  /// The quantity in the entry sheet.
  static const sheetQuantity = Key('shopping_list_sheet_quantity');

  /// The favorite switch in the entry sheet.
  static const sheetFavorite = Key('shopping_list_sheet_favorite');

  /// The schedule row in the entry sheet.
  static const sheetSchedule = Key('shopping_list_sheet_schedule');

  /// The button in the entry sheet that takes the entry off the list.
  static const sheetRemoveButton = Key('shopping_list_sheet_remove_button');

  /// The button in the entry sheet that moves the entry to or from the cart.
  static const sheetCartButton = Key('shopping_list_sheet_cart_button');

  /// The tile of the entry with [id].
  static Key tile(String id) => ValueKey('shopping_list_tile_$id');

  /// The quantity badge on the tile of the entry with [id].
  static Key tileQuantity(String id) =>
      ValueKey('shopping_list_tile_quantity_$id');

  /// The cart chip of the entry with [id].
  static Key cartChip(String id) => ValueKey('shopping_list_cart_chip_$id');
}
