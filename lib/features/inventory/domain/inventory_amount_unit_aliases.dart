import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';

/// Conversion details for an inventory amount unit alias.
typedef InventoryAmountUnitConversion = ({
  InventoryAmountUnit base,
  double multiplier,
  int scale,
});

/// Resolves an inventory amount unit alias into base unit, multiplier,
/// and scale.
InventoryAmountUnitConversion? resolveInventoryAmountUnitAlias(
  String? rawUnit,
) {
  if (rawUnit == null || rawUnit.isEmpty) {
    return null;
  }
  return inventoryAmountUnitAliases[rawUnit.trim().toLowerCase()];
}

/// Unit aliases mapping normalized strings to unit conversions.
const inventoryAmountUnitAliases = <String, InventoryAmountUnitConversion>{
  'g': (base: InventoryAmountUnit.gram, multiplier: 1.0, scale: 1),
  'gr': (base: InventoryAmountUnit.gram, multiplier: 1.0, scale: 1),
  'gram': (base: InventoryAmountUnit.gram, multiplier: 1.0, scale: 1),
  'grams': (base: InventoryAmountUnit.gram, multiplier: 1.0, scale: 1),
  'gramm': (base: InventoryAmountUnit.gram, multiplier: 1.0, scale: 1),
  'kg': (base: InventoryAmountUnit.gram, multiplier: 1000.0, scale: 1),
  'kilogram': (base: InventoryAmountUnit.gram, multiplier: 1000.0, scale: 1),
  'kilograms': (base: InventoryAmountUnit.gram, multiplier: 1000.0, scale: 1),
  'kilogramm': (base: InventoryAmountUnit.gram, multiplier: 1000.0, scale: 1),
  'kilo': (base: InventoryAmountUnit.gram, multiplier: 1000.0, scale: 1),
  'mg': (base: InventoryAmountUnit.gram, multiplier: 0.001, scale: 1),
  'milligram': (base: InventoryAmountUnit.gram, multiplier: 0.001, scale: 1),
  'milligramm': (base: InventoryAmountUnit.gram, multiplier: 0.001, scale: 1),
  'ml': (base: InventoryAmountUnit.milliliter, multiplier: 1.0, scale: 1),
  'milliliter': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 1.0,
    scale: 1,
  ),
  'milliliters': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 1.0,
    scale: 1,
  ),
  'millilitre': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 1.0,
    scale: 1,
  ),
  'millilitres': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 1.0,
    scale: 1,
  ),
  'cl': (base: InventoryAmountUnit.milliliter, multiplier: 10.0, scale: 1),
  'centiliter': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 10.0,
    scale: 1,
  ),
  'centilitre': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 10.0,
    scale: 1,
  ),
  'dl': (base: InventoryAmountUnit.milliliter, multiplier: 100.0, scale: 1),
  'deciliter': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 100.0,
    scale: 1,
  ),
  'decilitre': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 100.0,
    scale: 1,
  ),
  'l': (base: InventoryAmountUnit.milliliter, multiplier: 1000.0, scale: 1),
  'liter': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 1000.0,
    scale: 1,
  ),
  'liters': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 1000.0,
    scale: 1,
  ),
  'litre': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 1000.0,
    scale: 1,
  ),
  'litres': (
    base: InventoryAmountUnit.milliliter,
    multiplier: 1000.0,
    scale: 1,
  ),
  'pc': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'pcs': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'piece': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'pieces': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'st': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'st.': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'stk': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'stk.': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'stück': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'stueck': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'flasche': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'flaschen': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'dose': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'dosen': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'packung': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'packungen': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'pkg': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'pkg.': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'glas': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'gläser': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'glaeser': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'becher': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'riegel': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'tafel': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'tafeln': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'portion': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'portionen': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'beutel': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'bund': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'rolle': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
  'rollen': (
    base: InventoryAmountUnit.piece,
    multiplier: 1.0,
    scale: inventoryPieceAmountScale,
  ),
};
