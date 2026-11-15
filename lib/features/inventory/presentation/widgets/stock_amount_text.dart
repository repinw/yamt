import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _perKilo = 1000;
const _maxFractionDigits = 2;

/// [amount] of a stock in [unit] and [scale] as a cook says it: "250 g",
/// "1 kg", "1,5 l", "6 Stk". Grams and ml from 1000 on count in kg and l.
String stockAmountText(
  AppLocalizations l10n, {
  required int amount,
  required InventoryAmountUnit unit,
  int scale = 1,
}) {
  final big = unit != InventoryAmountUnit.piece && amount >= _perKilo;
  if (big) {
    final value = NumberFormat.decimalPattern(l10n.localeName)
      ..maximumFractionDigits = _maxFractionDigits;
    final text = value.format(amount / _perKilo);
    return unit == InventoryAmountUnit.gram
        ? l10n.stockAmountKilograms(text)
        : l10n.stockAmountLiters(text);
  }
  return l10n.inventoryEatSheetAmountWithUnit(
    formatInventoryAmountValue(amount: amount, unit: unit, scale: scale),
    unit.localizedName(l10n),
  );
}
