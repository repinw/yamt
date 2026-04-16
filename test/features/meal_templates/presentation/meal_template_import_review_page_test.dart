import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/meal_templates/presentation/meal_template_import_review_page.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  _FakePreparedMealTemplateRepository({this.saveSucceeds = true});

  final bool saveSucceeds;
  final StreamController<List<PreparedMeal>> _controller =
      StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _templates = const <PreparedMeal>[];
  List<PreparedMeal> savedTemplates = const <PreparedMeal>[];

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add(List<PreparedMeal>.from(_templates));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return List<PreparedMeal>.from(_templates);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> templates) async {
    if (!saveSucceeds) {
      return false;
    }
    _templates = List<PreparedMeal>.from(templates);
    savedTemplates = List<PreparedMeal>.from(templates);
    _controller.add(List<PreparedMeal>.from(_templates));
    return true;
  }

  Future<void> dispose() => _controller.close();
}

Widget _buildHarness({
  required PreparedMealTemplateRepository repository,
  required MealTemplateImportReviewArgs args,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/review'),
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => MealTemplateImportReviewPage(args: args),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(
      locale: const Locale('de'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('saves imported recipe template and pops back', (tester) async {
    final repository = _FakePreparedMealTemplateRepository();
    addTearDown(repository.dispose);
    const args = MealTemplateImportReviewArgs(
      importedRecipe: PreparedMealRecipeImport(
        recipeUrl: 'https://chefkoch.de/rezepte/42/kartoffelsuppe.html',
        title: 'Kartoffelsuppe',
        servings: 4,
        ingredients: <String>['1 kg Kartoffeln', '500 ml Brühe'],
        instructionsPreview: <String>['Kochen', 'Servieren'],
      ),
      preferredName: '',
      preferredPortions: null,
    );

    await tester.pumpWidget(_buildHarness(repository: repository, args: args));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Rezept prüfen'), findsOneWidget);
    expect(find.text('Kurze Anleitung'), findsOneWidget);

    await tester.tap(find.text('Als Vorlage speichern'));
    await tester.pumpAndSettle();

    expect(repository.savedTemplates, hasLength(1));
    expect(repository.savedTemplates.single.name, 'Kartoffelsuppe');
    expect(repository.savedTemplates.single.totalPortions, 4);
    expect(find.text('Vorlage gespeichert.'), findsOneWidget);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('shows localized save failure message', (tester) async {
    final repository = _FakePreparedMealTemplateRepository(saveSucceeds: false);
    addTearDown(repository.dispose);
    const args = MealTemplateImportReviewArgs(
      importedRecipe: PreparedMealRecipeImport(
        recipeUrl: 'https://chefkoch.de/rezepte/42/kartoffelsuppe.html',
        title: 'Kartoffelsuppe',
        servings: 4,
        ingredients: <String>['1 kg Kartoffeln'],
      ),
      preferredName: '',
      preferredPortions: null,
    );

    await tester.pumpWidget(_buildHarness(repository: repository, args: args));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Als Vorlage speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Vorlage konnte nicht erstellt werden.'), findsOneWidget);
    expect(repository.savedTemplates, isEmpty);
  });
}
