import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

extension FridgeAmountUnitL10n on FridgeAmountUnit {
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      FridgeAmountUnit.gram => l10n.caloriesUnitGram,
      FridgeAmountUnit.milliliter => l10n.caloriesUnitMilliliter,
      FridgeAmountUnit.piece => l10n.inventoryReceiptReviewWeightUnitPiece,
    };
  }
}
