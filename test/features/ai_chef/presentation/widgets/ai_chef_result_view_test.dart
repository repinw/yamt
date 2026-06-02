import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_result_view.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('result view renders recipe and inventory match badge', (
    tester,
  ) async {
    var didSave = false;
    var didClose = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 700,
            child: AiChefResultView(
              recipe: _recipe(),
              inventoryIngredients: const <String>['Tomato'],
              isSaving: false,
              onSave: () {
                didSave = true;
              },
              onClose: () {
                didClose = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tomato Pasta'), findsOneWidget);
    expect(find.text('200 g Tomato'), findsOneWidget);
    expect(find.text('120 g pasta'), findsOneWidget);
    expect(find.text('Boil pasta.'), findsOneWidget);
    expect(find.text('Add tomato sauce.'), findsOneWidget);
    expect(find.text('From your stock'), findsOneWidget);

    await tester.tap(find.text('Save to Cookbook'));
    await tester.tap(find.text('Close'));

    expect(didSave, isTrue);
    expect(didClose, isTrue);
  });
}

PreparedMeal _recipe() {
  return PreparedMeal(
    id: 'recipe-1',
    name: 'Tomato Pasta',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 500,
    totalProtein: 20,
    totalCarbs: 60,
    totalFat: 12,
    createdAt: DateTime.parse('2026-04-02T12:00:00Z'),
    updatedAt: DateTime.parse('2026-04-02T12:00:00Z'),
    components: const <PreparedMealComponent>[],
    recipeIngredients: const <String>['200 g Tomato', '120 g pasta'],
    recipeInstructions: const <String>[
      'Boil pasta.',
      'Add tomato sauce.',
    ],
  );
}
