import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_open_meal_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../support/prepared_meal_test_data.dart';

Future<void> _pumpCard(WidgetTester tester, DateTime createdAt) {
  final meal = preparedMealTestData(id: 'pot')
      .copyWith(inPot: true, createdAt: createdAt);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 2, 20)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CookbookOpenMealCard(meal: meal, onContinue: () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a pot from today shows the time', (tester) async {
    await _pumpCard(tester, DateTime(2026, 10, 2, 18, 30));

    expect(find.text('In the pot since 6:30 PM'), findsOneWidget);
  });

  testWidgets('a pot from an earlier day shows the day', (tester) async {
    await _pumpCard(tester, DateTime(2026, 9, 28, 18, 30));

    expect(find.text('In the pot since Sep 28'), findsOneWidget);
  });
}
