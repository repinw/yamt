import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<AppLocalizations> _localizations(
  WidgetTester tester,
  Locale locale,
) async {
  AppLocalizations? localizations;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          localizations = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();

  expect(localizations, isNotNull);
  return localizations!;
}

void main() {
  testWidgets('maps all consumed units for English localization', (
    tester,
  ) async {
    final l10n = await _localizations(tester, const Locale('en'));

    expect(ConsumedUnit.grams.localizedName(l10n), 'g');
    expect(ConsumedUnit.milliliters.localizedName(l10n), 'ml');
  });

  testWidgets('maps all consumed units for German localization', (
    tester,
  ) async {
    final l10n = await _localizations(tester, const Locale('de'));

    expect(ConsumedUnit.grams.localizedName(l10n), 'g');
    expect(ConsumedUnit.milliliters.localizedName(l10n), 'ml');
  });
}
