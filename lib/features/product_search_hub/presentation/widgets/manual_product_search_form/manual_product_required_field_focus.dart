import 'package:material_ui/material_ui.dart';

/// Keyboard focus for the required text fields of the product form.
///
/// Confirming a required field on the keyboard moves to the next required
/// field that is still empty, in form order: name, kcal, fat, carbs, protein.
class ManualProductRequiredFieldFocus {
  /// Name field.
  final name = FocusNode();

  /// Kcal field.
  final kcal = FocusNode();

  /// Fat field.
  final fat = FocusNode();

  /// Carbs field.
  final carbs = FocusNode();

  /// Protein field.
  final protein = FocusNode();

  List<FocusNode> get _order => [name, kcal, fat, carbs, protein];

  /// Focuses the next empty required field after [current].
  ///
  /// [values] holds the field texts in form order. Without an empty field
  /// left, the keyboard closes.
  void focusNextEmpty(FocusNode current, List<String> values) {
    final order = _order;
    for (var i = order.indexOf(current) + 1; i < order.length; i++) {
      if (values[i].trim().isEmpty) {
        order[i].requestFocus();
        return;
      }
    }
    current.unfocus();
  }

  /// Releases the focus nodes.
  void dispose() {
    for (final node in _order) {
      node.dispose();
    }
  }
}
