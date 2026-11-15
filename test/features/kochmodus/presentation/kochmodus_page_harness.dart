import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../helpers/fake_signed_in_user.dart';
import '../../../support/prepared_meal_test_data.dart';
import 'kochmodus_cooking_harness.dart';

/// Where the cooking page of [openPage] lives.
const kochmodusTestPath = '/cook';

/// A utensil with [weight] grams.
KitchenUtensil utensil(String id, String name, {int weight = 900}) =>
    KitchenUtensil(
      id: id,
      name: name,
      weightGrams: weight,
      createdAt: DateTime.utc(2026, 10),
      updatedAt: DateTime.utc(2026, 10),
    );

/// A Kochbuch recipe with ingredient lines and instructions.
PreparedMeal kochmodusRecipe({
  List<String> ingredients = const ['500 g Hackfleisch', '200 g Karotten'],
  List<String> ignored = const [],
  List<String> steps = const [],
}) =>
    preparedMealTestData(id: 't1', name: 'Eintopf', totalPortions: 4).copyWith(
      recipeIngredients: ingredients,
      ignoredRecipeIngredients: ignored,
      recipeInstructions: steps,
    );

/// Puts [recipe] into the cookbook of [harness] before the page opens.
void addRecipe(KochmodusCookingHarness harness, PreparedMeal recipe) {
  harness.cook.templates = FakePreparedMealTemplateRepository(
    templates: [recipe],
  );
}

/// Opens [page] (a cooking or assigning page) on top of the stub home of
/// [harness]; "back" and "Zum
/// Kochbuch" lead to that home. The screen lock calls land in [wake];
/// [overrides] come last, and [routes] are what the page may push. The app
/// speaks [locale].
Future<void> openPage(
  WidgetTester tester,
  KochmodusCookingHarness harness,
  Widget page, {
  List<bool>? wake,
  List<Override> overrides = const [],
  List<RouteBase> routes = const [],
  Locale locale = const Locale('en'),
}) async {
  // A tall screen, so every row of a long step is built.
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(800, 1600);
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(key: homeKey),
      ),
      GoRoute(path: kochmodusTestPath, builder: (context, state) => page),
      ...routes,
    ],
  );
  addTearDown(router.dispose);
  harness.router = router;
  final container = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(
        FakeSignedInAuth(
          FakeSignedInUser(kochmodusTestUserId, displayName: 'Ada'),
        ),
      ),
      appPreferencesProvider.overrideWithValue(harness.preferences),
      clockProvider.overrideWithValue(() => harness.now),
      cookRunRepositoryProvider.overrideWithValue(
        harness.runsOverride ?? harness.cook.runs,
      ),
      cookedMealRepositoryProvider.overrideWithValue(harness.cook.meals),
      inventoryItemRepositoryProvider.overrideWithValue(harness.cook.inventory),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        harness.cook.templates,
      ),
      kitchenUtensilRepositoryProvider.overrideWithValue(harness.utensils),
      localNotificationsProvider.overrideWithValue(harness.notifications),
      voiceSearchServiceProvider.overrideWithValue(harness.voice),
      screenWakeLockProvider.overrideWithValue(
        ScreenWakeLock(
          toggle: ({required on}) async {
            wake?.add(on);
          },
        ),
      ),
      appRouterProvider.overrideWith((ref) => router),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  harness.container = container;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  unawaited(router.push<void>(kochmodusTestPath));
  await harness.idle(tester);
  // The page has slid in.
  await tester.pumpAndSettle();
}
