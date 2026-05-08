import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/presentation/'
    'kitchen_utensils_page.dart';
import 'package:yamt/features/meal_templates/presentation/meal_templates_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../support/fake_prepared_meal_image_picker.dart';

class _FakeKitchenUtensilRepository implements KitchenUtensilRepository {
  _FakeKitchenUtensilRepository({List<KitchenUtensil>? initialUtensils})
    : _utensils = List<KitchenUtensil>.from(
        initialUtensils ?? const <KitchenUtensil>[],
      );

  final StreamController<List<KitchenUtensil>> _controller =
      StreamController<List<KitchenUtensil>>.broadcast();
  List<KitchenUtensil> _utensils;

  @override
  Stream<List<KitchenUtensil>> watchAll() {
    return Stream<List<KitchenUtensil>>.multi((controller) {
      controller.add(List<KitchenUtensil>.from(_utensils));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<KitchenUtensil>> readAll() async {
    return List<KitchenUtensil>.from(_utensils);
  }

  @override
  Future<bool> save(KitchenUtensil utensil) async {
    final index = _utensils.indexWhere((current) => current.id == utensil.id);
    if (index < 0) {
      _utensils = [..._utensils, utensil];
    } else {
      final nextUtensils = List<KitchenUtensil>.from(_utensils);
      nextUtensils[index] = utensil;
      _utensils = nextUtensils;
    }
    _controller.add(List<KitchenUtensil>.from(_utensils));
    return true;
  }

  @override
  Future<bool> delete(String utensilId) async {
    _utensils = _utensils
        .where((utensil) => utensil.id != utensilId)
        .toList(growable: false);
    _controller.add(List<KitchenUtensil>.from(_utensils));
    return true;
  }

  @override
  Future<String?> uploadImage({
    required String utensilId,
    required String imageId,
    required Uint8List bytes,
  }) async {
    return 'users/owner-1/kitchen_utensils/$utensilId/images/$imageId.jpg';
  }

  @override
  Future<bool> deleteImage(String imageStoragePath) async {
    return true;
  }

  @override
  Future<String?> imageUrl(String imageStoragePath) async {
    return 'https://example.test/$imageStoragePath';
  }

  Future<void> dispose() => _controller.close();
}

class _FakePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  const _FakePreparedMealTemplateRepository();

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.value(const <PreparedMeal>[]);
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return const <PreparedMeal>[];
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> templates) async {
    return true;
  }
}

class _FakePreparedMealRecipeImporter extends PreparedMealRecipeImporter {
  const _FakePreparedMealRecipeImporter();

  @override
  Future<PreparedMealRecipeImport?> importRecipe(
    String recipeUrl, {
    String? localeName,
  }) async {
    return null;
  }
}

@Dependencies([preparedMealImagePicker])
Widget _buildKitchenHarness({
  required KitchenUtensilRepository repository,
  PreparedMealImagePicker? imagePicker,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const KitchenUtensilsPage(),
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      householdDataOwnerUserIdProvider.overrideWith((ref) => 'owner-1'),
      kitchenUtensilRepositoryProvider.overrideWithValue(repository),
      preparedMealImagePickerProvider.overrideWithValue(
        imagePicker ?? FakePreparedMealImagePicker(),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

@Dependencies([preparedMealImagePicker])
Widget _buildCookbookHarness({
  required KitchenUtensilRepository kitchenRepository,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const MealTemplatesPage(),
      ),
      GoRoute(
        path: AppRoutes.homeKitchenUtensils,
        builder: (context, state) => const KitchenUtensilsPage(),
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      householdDataOwnerUserIdProvider.overrideWith((ref) => 'owner-1'),
      kitchenUtensilRepositoryProvider.overrideWithValue(kitchenRepository),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        const _FakePreparedMealTemplateRepository(),
      ),
      preparedMealRecipeImporterProvider.overrideWithValue(
        const _FakePreparedMealRecipeImporter(),
      ),
      preparedMealImagePickerProvider.overrideWithValue(
        FakePreparedMealImagePicker(),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

@Dependencies([preparedMealImagePicker])
void main() {
  testWidgets('adds edits and deletes a kitchen utensil', (tester) async {
    final repository = _FakeKitchenUtensilRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildKitchenHarness(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('No kitchen utensils saved yet.'), findsOneWidget);

    await tester.tap(find.byTooltip('Add utensil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Pot');
    await tester.enterText(
      find.widgetWithText(TextField, 'Weight (g)'),
      '420',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add utensil'));
    await tester.pumpAndSettle();

    expect(find.text('Pot'), findsOneWidget);
    expect(find.text('420 g'), findsOneWidget);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Weight (g)'),
      '430',
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('430 g'), findsOneWidget);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete utensil'));
    await tester.pumpAndSettle();

    expect(find.text('Pot'), findsNothing);
    expect(find.text('No kitchen utensils saved yet.'), findsOneWidget);
  });

  testWidgets('validates name or photo and weight', (tester) async {
    final repository = _FakeKitchenUtensilRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildKitchenHarness(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add utensil'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add utensil'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a weight greater than 0.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Weight (g)'),
      '100',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add utensil'));
    await tester.pumpAndSettle();

    expect(find.text('Add a name or photo.'), findsOneWidget);
  });

  testWidgets('opens kitchen utensils from cookbook action', (tester) async {
    final kitchenRepository = _FakeKitchenUtensilRepository();
    addTearDown(kitchenRepository.dispose);

    await tester.pumpWidget(
      _buildCookbookHarness(kitchenRepository: kitchenRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Templates'), findsOneWidget);

    await tester.tap(find.byTooltip('Kitchen utensils'));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen utensils'), findsOneWidget);
    expect(find.text('No kitchen utensils saved yet.'), findsOneWidget);
  });
}
