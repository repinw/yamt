import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';

/// A text input of the product editor, in the order of the page.
enum ManualProductFormField {
  /// Brand.
  brand('receipt_review_manual_brand_field'),

  /// Product name.
  name('receipt_review_manual_name_field'),

  /// Package size.
  weightAmount('receipt_review_manual_weight_field'),

  /// Grams of one piece, shown for a package counted in pieces.
  pieceWeight('receipt_review_manual_piece_weight_field'),

  /// Barcode.
  barcode('receipt_review_manual_barcode_field'),

  /// Energy per 100 g in kcal.
  kcal('receipt_review_manual_kcal_field'),

  /// Fat per 100 g.
  fat('receipt_review_manual_fat_field'),

  /// Saturated fat per 100 g.
  saturatedFat('receipt_review_manual_saturated_fat_field'),

  /// Polyunsaturated fat per 100 g.
  polyunsaturatedFat('receipt_review_manual_polyunsaturated_fat_field'),

  /// Carbohydrate per 100 g.
  carbs('receipt_review_manual_carbs_field'),

  /// Sugar per 100 g.
  sugar('receipt_review_manual_sugar_field'),

  /// Fiber per 100 g.
  fiber('receipt_review_manual_fiber_field'),

  /// Protein per 100 g.
  protein('receipt_review_manual_protein_field'),

  /// Salt per 100 g.
  salt('receipt_review_manual_salt_field');

  new(this._keyName);

  final String _keyName;

  /// Key of the input.
  Key get key => Key(_keyName);

  /// Whether the product cannot be saved without this value: the name and
  /// the seven values of the EU nutrition label.
  bool get isRequired => switch (this) {
    name ||
    kcal ||
    fat ||
    saturatedFat ||
    carbs ||
    sugar ||
    protein ||
    salt => true,
    brand ||
    weightAmount ||
    pieceWeight ||
    barcode ||
    polyunsaturatedFat ||
    fiber => false,
  };

  /// Text of this input in [state].
  String textIn(InventoryReceiptManualProductState state) => switch (this) {
    brand => state.brandText,
    name => state.nameText,
    weightAmount => state.weightAmount,
    pieceWeight => state.pieceWeightText,
    barcode => state.barcode,
    kcal => state.kcalText,
    fat => state.fatText,
    saturatedFat => state.saturatedFatText,
    polyunsaturatedFat => state.polyunsaturatedFatText,
    carbs => state.carbsText,
    sugar => state.sugarText,
    fiber => state.fiberText,
    protein => state.proteinText,
    salt => state.saltText,
  };
}
