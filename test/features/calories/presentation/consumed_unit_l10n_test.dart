import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';

import '../../../helpers/l10n_test_utils.dart';

void main() {
  testWidgets('maps all consumed units for English localization', (
    tester,
  ) async {
    final l10n = await pumpLocalizations(tester, locale: const Locale('en'));

    expect(ConsumedUnit.grams.localizedName(l10n), 'g');
    expect(ConsumedUnit.milliliters.localizedName(l10n), 'ml');
  });

  testWidgets('maps all consumed units for German localization', (
    tester,
  ) async {
    final l10n = await pumpLocalizations(tester, locale: const Locale('de'));

    expect(ConsumedUnit.grams.localizedName(l10n), 'g');
    expect(ConsumedUnit.milliliters.localizedName(l10n), 'ml');
  });
}
