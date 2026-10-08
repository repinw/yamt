import 'package:material_ui/material_ui.dart';

/// Text controller and focus node of one eat sheet field.
///
/// Focusing the field selects its text, so typing replaces the amount.
class EatSheetTextField {
  /// Creates the field state.
  new() {
    focusNode.addListener(_selectAllOnFocus);
  }

  /// Text controller.
  final controller = TextEditingController();

  /// Focus node.
  final focusNode = FocusNode();

  /// Shows [text] unless the field already holds it.
  void sync(String text) {
    if (controller.text == text) {
      return;
    }
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Shows [text] unless the field already holds the same value, so a typed
  /// "37," stays while the value it gives is 37. Zero counts as no value, so
  /// a cleared field or a "0," on the way to "0,5" stays while the amount is
  /// empty, and shows the next amount picked elsewhere.
  void syncValue(String text, double? Function(String text) parse) {
    double? amount(String text) {
      final value = parse(text);
      return value == null || value <= 0 ? null : value;
    }

    if (amount(controller.text) == amount(text)) {
      return;
    }
    sync(text);
  }

  /// Releases the controller and focus node.
  void dispose() {
    focusNode.dispose();
    controller.dispose();
  }

  void _selectAllOnFocus() {
    if (!focusNode.hasFocus) {
      return;
    }
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }
}
