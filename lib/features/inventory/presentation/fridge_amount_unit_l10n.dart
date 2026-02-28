import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

extension FridgeAmountUnitL10n on FridgeAmountUnit {
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      FridgeAmountUnit.gram => l10n.inventoryUnitGram,
      FridgeAmountUnit.milliliter => l10n.inventoryUnitMilliliter,
      FridgeAmountUnit.piece => l10n.inventoryUnitPiece,
    };
  }
}
