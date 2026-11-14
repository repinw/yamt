import 'package:material_ui/material_ui.dart';

/// Keys of the list import for tests.
class ShoppingImportKeys {
  const new _();

  /// The switch segment for pasted text.
  static const modeText = Key('shopping_import_mode_text');

  /// The switch segment for a scanned list.
  static const modeScan = Key('shopping_import_mode_scan');

  /// The field for the pasted list.
  static const textField = Key('shopping_import_text_field');

  /// The count of pasted lines.
  static const lineCount = Key('shopping_import_line_count');

  /// The button that empties the field.
  static const clearButton = Key('shopping_import_clear_button');

  /// The button that pastes from the clipboard.
  static const pasteButton = Key('shopping_import_paste_button');

  /// The button that reads the pasted list.
  static const readButton = Key('shopping_import_read_button');

  /// The button that opens the scanner.
  static const scanButton = Key('shopping_import_scan_button');

  /// The view shown while the list is read.
  static const reading = Key('shopping_import_reading');

  /// The retry button after a failed or empty read.
  static const retryButton = Key('shopping_import_retry_button');

  /// The count of products found.
  static const foundCount = Key('shopping_import_found_count');

  /// The button that puts the selected products on the list.
  static const addButton = Key('shopping_import_add_button');

  /// The lines the reader passed over.
  static const skipped = Key('shopping_import_skipped');

  /// The name field of the rename dialog.
  static const renameField = Key('shopping_import_rename_field');

  /// The save button of the rename dialog.
  static const renameSave = Key('shopping_import_rename_save');

  /// The row of the product at [index].
  static Key row(int index) => ValueKey('shopping_import_row_$index');

  /// The tappable name of the product at [index].
  static Key rowName(int index) => ValueKey('shopping_import_row_name_$index');

  /// The select checkbox of the product at [index].
  static Key rowCheckbox(int index) =>
      ValueKey('shopping_import_row_checkbox_$index');

  /// The line under the name of the product at [index].
  static Key rowDetail(int index) =>
      ValueKey('shopping_import_row_detail_$index');

  /// The quantity of the product at [index].
  static Key rowQuantity(int index) =>
      ValueKey('shopping_import_row_quantity_$index');
}
