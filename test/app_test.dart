import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';

import 'features/calories/support/fake_calories_repositories.dart';
import 'helpers/memory_app_preferences.dart';
import 'helpers/system_back_test_utils.dart';

void main() {
  testWidgets('YAMT builds router app from provider in the saved theme', (
    tester,
  ) async {
    final nativeModes = await _pumpApp(tester, [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('root')),
      ),
    ]);

    expect(find.text('root'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(nativeModes, ['dark']);
  });

  testWidgets('YAMT closes the keyboard before the back leaves a page', (
    tester,
  ) async {
    const fieldKey = Key('app_test_field');
    await _pumpApp(tester, [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('root')),
        routes: [
          GoRoute(
            path: 'form',
            builder: (context, state) =>
                const Scaffold(body: TextField(key: fieldKey)),
          ),
        ],
      ),
    ]);
    GoRouter.of(tester.element(find.text('root'))).push<void>('/form').ignore();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(fieldKey), 'Kantine');
    await openTestKeyboard(tester);

    await pressSystemBack(tester);

    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.text('Kantine'), findsOneWidget);

    await closeTestKeyboard(tester);
    await pressSystemBack(tester);

    expect(find.byKey(fieldKey), findsNothing);
    expect(find.text('root'), findsOneWidget);
  });
}

/// Pumps the app with [routes] in the dark theme and returns the theme
/// modes that reached the native side.
Future<List<Object?>> _pumpApp(
  WidgetTester tester,
  List<RouteBase> routes,
) async {
  final nativeModes = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('de.yamt.app/theme_mode'),
    (call) async => nativeModes.add(call.arguments),
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('de.yamt.app/theme_mode'),
      null,
    ),
  );
  final router = GoRouter(initialLocation: '/', routes: routes);
  addTearDown(router.dispose);
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(settingsRepository.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appRouterProvider.overrideWithValue(router),
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(initialStrings: {'app_theme_mode_v1': 'dark'}),
        ),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        inventoryItemsControllerProvider.overrideWith(
          _EmptyInventoryItemsController.new,
        ),
        preparedMealsControllerProvider.overrideWith(
          _EmptyPreparedMealsController.new,
        ),
      ],
      child: const YAMT(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.pump();
  return nativeModes;
}

class _EmptyInventoryItemsController extends InventoryItemsController {
  @override
  Future<List<InventoryItem>> build() async {
    return const <InventoryItem>[];
  }
}

class _EmptyPreparedMealsController extends PreparedMealsController {
  @override
  Future<List<PreparedMeal>> build() async {
    return const <PreparedMeal>[];
  }
}
