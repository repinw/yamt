import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_dialog.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _CompletingAiChefRepository extends FirebaseAiChefRepository {
  _CompletingAiChefRepository(this.recipeFuture);

  final Future<PreparedMeal?> recipeFuture;

  @override
  Future<PreparedMeal?> generateAiRecipe({
    required String languageCode,
    required String seed,
    List<String> inventoryIngredients = const [],
  }) {
    return recipeFuture;
  }
}

class _RecordingPreparedMealTemplatesController
    extends PreparedMealTemplatesController {
  _RecordingPreparedMealTemplatesController({required this.onSave});

  final void Function(PreparedMeal recipe) onSave;

  @override
  FutureOr<List<PreparedMeal>> build() {
    return const <PreparedMeal>[];
  }

  @override
  Future<PreparedMealTemplateSaveResult> saveRecipeTemplate(
    PreparedMeal template,
  ) async {
    onSave(template);
    return const PreparedMealTemplateSaveResult.success('template-1');
  }
}

void main() {
  testWidgets('dialog completes setup loading result and save flow', (
    tester,
  ) async {
    final recipeCompleter = Completer<PreparedMeal?>();
    PreparedMeal? savedRecipe;
    final templatesController = _RecordingPreparedMealTemplatesController(
      onSave: (recipe) {
        savedRecipe = recipe;
      },
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Scaffold(
              body: FilledButton(
                onPressed: () {
                  unawaited(
                    showAiChefDialog(
                      context,
                      inventoryItemsLoader: () async {
                        return const <InventoryItem>[];
                      },
                    ),
                  );
                },
                child: const Text('Open AI Chef'),
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChefRepositoryProvider.overrideWithValue(
            _CompletingAiChefRepository(recipeCompleter.future),
          ),
          preparedMealTemplatesControllerProvider.overrideWith(
            () => templatesController,
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Open AI Chef'));
    await tester.pumpAndSettle();

    expect(find.text('What should the AI cook?'), findsOneWidget);

    await tester.tap(find.text('Generate recipe'));
    await tester.pump();

    expect(find.text('AI is cooking...'), findsOneWidget);

    recipeCompleter.complete(_recipe());
    await tester.pumpAndSettle();

    expect(find.text('Tomato Pasta'), findsOneWidget);

    await tester.tap(find.text('Save to Cookbook'));
    await tester.pumpAndSettle();

    expect(savedRecipe?.name, 'Tomato Pasta');
    expect(find.text('Tomato Pasta'), findsNothing);
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
    recipeInstructions: const <String>['Boil pasta.'],
  );
}
