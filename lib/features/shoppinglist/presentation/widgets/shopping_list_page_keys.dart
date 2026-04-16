import 'package:flutter/material.dart';

/// Defines shopping list page keys.
class ShoppingListPageKeys {
  const ShoppingListPageKeys._();

  /// The clear crossed off button.
  static const clearCrossedOffButton = Key(
    'shopping_list_clear_crossed_off_button',
  );

  /// The clear crossed off confirm button.
  static const clearCrossedOffConfirmButton = Key(
    'shopping_list_clear_crossed_off_confirm_button',
  );

  /// The clear crossed off cancel button.
  static const clearCrossedOffCancelButton = Key(
    'shopping_list_clear_crossed_off_cancel_button',
  );
}
