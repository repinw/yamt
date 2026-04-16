import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory amount unit l10n extension.
extension InventoryAmountUnitL10n on InventoryAmountUnit {
  /// Localized name.
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      InventoryAmountUnit.gram => l10n.inventoryUnitGram,
      InventoryAmountUnit.milliliter => l10n.inventoryUnitMilliliter,
      InventoryAmountUnit.piece => l10n.inventoryUnitPiece,
    };
  }
}
