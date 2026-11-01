import 'package:yamt/features/cooking/application/stock_suggestion.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// [amount] in [unit] as "150 g", "2 Stk"; [unit] `null` counts pieces.
String cookAmountText(
  AppLocalizations l10n,
  int amount,
  InventoryAmountUnit? unit, {
  int scale = 1,
}) {
  final value = formatInventoryAmountValue(
    amount: amount,
    unit: unit ?? InventoryAmountUnit.piece,
    scale: scale,
  );
  return switch (unit) {
    InventoryAmountUnit.gram => l10n.cookAmountGrams(value),
    InventoryAmountUnit.milliliter => l10n.cookAmountMilliliters(value),
    InventoryAmountUnit.piece || null => l10n.cookAmountPieces(value),
  };
}

/// What [item] still holds, as "500 g".
String cookItemStock(AppLocalizations l10n, InventoryItem item) =>
    cookItemAmount(l10n, item, item.availableAmount);

/// [take] as "150 g Barilla", or "Barilla" when it takes nothing.
String cookTakeText(AppLocalizations l10n, CookTakeView take) =>
    take.amount <= 0
    ? take.item.name
    : l10n.cookAmountOf(
        cookItemAmount(l10n, take.item, take.amount),
        take.item.name,
      );

/// [amount] of [item] in its unit, as "150 g".
String cookItemAmount(AppLocalizations l10n, InventoryItem item, int amount) =>
    cookAmountText(l10n, amount, item.amountUnit, scale: cookAmountScale(item));
