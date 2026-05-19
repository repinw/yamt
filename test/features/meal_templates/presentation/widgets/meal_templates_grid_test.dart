import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_grid.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../support/prepared_meal_test_data.dart';

void main() {
  testWidgets('renders all templates in the grid', (tester) async {
    final templates = [
      preparedMealTestData(),
      preparedMealTestData(id: 'meal-2', name: 'Tacos'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookingFlowSessionSnapshotProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MealTemplatesGrid(
                  templates: templates,
                  includeAppBar: false,
                  onOpen: (_) {},
                  onEdit: (_) async => true,
                  onDelete: (_) async => true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rice bowl'), findsOneWidget);
    expect(find.text('Tacos'), findsOneWidget);
  });
}
