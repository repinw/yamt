import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';

import '../../../helpers/l10n_test_utils.dart';

void main() {
  testWidgets('maps all fridge amount units for English localization', (
    tester,
  ) async {
    final l10n = await pumpLocalizations(tester, locale: const Locale('en'));

    expect(InventoryAmountUnit.gram.localizedName(l10n), 'g');
    expect(InventoryAmountUnit.milliliter.localizedName(l10n), 'ml');
    expect(InventoryAmountUnit.piece.localizedName(l10n), 'pc');
  });

  testWidgets('maps all fridge amount units for German localization', (
    tester,
  ) async {
    final l10n = await pumpLocalizations(tester, locale: const Locale('de'));

    expect(InventoryAmountUnit.gram.localizedName(l10n), 'g');
    expect(InventoryAmountUnit.milliliter.localizedName(l10n), 'ml');
    expect(InventoryAmountUnit.piece.localizedName(l10n), 'Stk');
  });
}
