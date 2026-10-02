import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_unit_aliases.dart';
import 'package:yamt/features/product_search_hub/domain/manual_product_search_value_utils.dart';

/// A product's serving: the printed label, its amount, and the unit code.
typedef ManualProductServing = ({
  String? size,
  double? quantity,
  String? quantityUnit,
});

/// Text of the "grams per piece" input for [serving]: its amount when it
/// is in grams or milliliters, otherwise empty.
String manualProductPieceWeightText(ManualProductServing serving) {
  final unit = resolveInventoryAmountUnitAlias(serving.quantityUnit);
  if (unit == null || unit.base == InventoryAmountUnit.piece) {
    return '';
  }
  return formatManualProductDouble(switch (serving.quantity) {
    final quantity? => quantity * unit.multiplier,
    null => null,
  });
}

/// The serving to save. For a package counted in pieces, the entered grams
/// of one piece become the serving: the eat page offers it as the weight of
/// one piece. A new amount drops the old label, which would no longer match.
ManualProductServing resolveManualProductServing({
  required InventoryAmountUnit? packageUnit,
  required String pieceWeightText,
  required ManualProductServing serving,
}) {
  final grams = parseManualProductDouble(pieceWeightText);
  if (packageUnit != InventoryAmountUnit.piece ||
      grams == null ||
      grams <= 0 ||
      manualProductPieceWeightText(serving) ==
          formatManualProductDouble(grams)) {
    return serving;
  }
  return (size: null, quantity: grams, quantityUnit: 'g');
}
