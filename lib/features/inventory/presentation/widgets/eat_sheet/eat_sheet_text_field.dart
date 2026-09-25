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
