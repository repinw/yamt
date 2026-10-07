import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_gone_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../support/prepared_meal_test_data.dart';

/// A meal page that closes when its meal is gone.
class _MealPage extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PreparedMealGoneFlow.closeWhenGone(ref, context, 'meal-1');
    return Scaffold(
      body: TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('on top')),
        ),
        child: const Text('meal page'),
      ),
    );
  }
}

void main() {
  testWidgets('a gone meal closes its page and what is open on top', (
    tester,
  ) async {
    final meals = StreamController<List<PreparedMeal>>.broadcast();
    addTearDown(meals.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuickEatMealsProvider.overrideWith((ref) => meals.stream),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const _MealPage()),
                ),
                child: const Text('home'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    meals.add([preparedMealTestData()]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('meal page'));
    await tester.pumpAndSettle();
    expect(find.text('on top'), findsOneWidget);

    meals.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('on top'), findsNothing);
    expect(find.text('meal page'), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('Meal is no longer in stock'), findsOneWidget);
  });
}
