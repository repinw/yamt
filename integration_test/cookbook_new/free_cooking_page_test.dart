import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/cookbook_new/presentation/free_cooking_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_destination_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_pot_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_actions.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_row_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_text_sheet.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'prepared_meal_eat_sheet_body.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _startKey = ValueKey<String>('start-free-cooking');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('speaks and types rows, cooks, and marks the meal as cooked', (
    tester,
  ) async {
    final meals = _FakeMealRepository();
    final voice = _FakeVoiceService('200 g Reis 500 g Hähnchen');
    await tester.pumpWidget(_app(meals: meals, voice: voice));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(FreeCookingPage.voiceZoneKey));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeCookingRowList.rowKey(0)), findsOneWidget);
    expect(find.byKey(FreeCookingRowList.rowKey(1)), findsOneWidget);
    // Rice is in the Vorrat, chicken is not.
    expect(find.text('1 OF 2 IN STOCK'), findsOneWidget);

    await tester.tap(find.byKey(FreeCookingPage.voiceZoneKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FreeCookingActions.typeKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(FreeCookingTextSheet.fieldKey), 'Salz');
    await tester.tap(find.byKey(FreeCookingTextSheet.addKey));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeCookingRowList.rowKey(2)), findsOneWidget);

    await tester.drag(
      find.byKey(FreeCookingRowList.rowKey(2)),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(FreeCookingRowList.rowKey(2)), findsNothing);

    await tester.enterText(find.byKey(FreeCookingHeader.nameKey), 'Pfanne');
    await tester.tap(find.byKey(FreeCookingActions.cookKey));
    await tester.pumpAndSettle();

    // "Kochen" goes straight on to the "Gekocht" step.
    expect(find.byType(CookedMealPage), findsOneWidget);
    final meal = meals.saved.single;
    expect(meal.name, 'Pfanne');
    expect(meal.isInPot, isTrue);
    expect(meal.components.single.inventoryItemId, 'rice');
    expect(meal.pendingRecipeIngredients, hasLength(1));

    // The open chicken row keeps the meal out of the diary.
    await _showDestination(tester);
    expect(_segment(tester, CookedMealDestination.diary).enabled, isFalse);

    // A weight without the pot cannot be saved.
    await tester.enterText(find.byKey(CookedMealPotSection.grossKey), '1300');
    await tester.pumpAndSettle();
    expect(_saveButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(CookedMealPotSection.morePortionsKey));
    await tester.tap(find.byKey(CookedMealPotSection.utensilKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CookedMealPotSection.utensilOptionKey('pot')).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealPage.saveKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_startKey), findsOneWidget);
    final cooked = meals.saved.single;
    expect(cooked.isInPot, isFalse);
    expect(cooked.totalPortions, 2);
    expect(cooked.potTareWeight, 400);
    expect(cooked.finalNetWeight, 900);
  });

  testWidgets('"To diary" cooks the meal and opens the eat page', (
    tester,
  ) async {
    final meals = _FakeMealRepository();
    await tester.pumpWidget(
      _app(meals: meals, voice: _FakeVoiceService('200 g Reis')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FreeCookingPage.voiceZoneKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FreeCookingPage.voiceZoneKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(FreeCookingHeader.nameKey), 'Reis');
    await tester.tap(find.byKey(FreeCookingActions.cookKey));
    await tester.pumpAndSettle();

    await _showDestination(tester);
    await tester.tap(
      find.byKey(
        CookedMealDestinationSection.segmentKey(CookedMealDestination.diary),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealPage.saveKey));
    await tester.pumpAndSettle();

    expect(meals.saved.single.isInPot, isFalse);
    expect(find.byType(PreparedMealEatSheetBody), findsOneWidget);

    // Closing the eat page leaves the meal in the Vorrat and the step.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(_startKey), findsOneWidget);
  });

  testWidgets('fits under the keyboard and lets go of the name focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(meals: _FakeMealRepository(), voice: _FakeVoiceService('Salz')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(FreeCookingHeader.nameKey));
    // A keyboard over most of the screen covers the actions instead of
    // squeezing them.
    tester.view.viewInsets = FakeViewPadding(
      bottom: tester.view.physicalSize.height * 0.6,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(FreeCookingActions.typeKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(FreeCookingTextSheet.fieldKey), 'Salz');
    await tester.tap(find.byKey(FreeCookingTextSheet.addKey));
    await tester.pumpAndSettle();

    // The name does not take the focus back, so the keyboard stays closed.
    final name = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(FreeCookingHeader.nameKey),
        matching: find.byType(EditableText),
      ),
    );
    expect(name.focusNode.hasFocus, isFalse);

    // Neither after the discard dialog that a back gesture opens.
    await tester.tap(find.byKey(FreeCookingHeader.nameKey));
    await tester.pumpAndSettle();
    expect(name.focusNode.hasFocus, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(name.focusNode.hasFocus, isFalse);
  });

  testWidgets('asks before it discards rows', (tester) async {
    await tester.pumpWidget(
      _app(meals: _FakeMealRepository(), voice: _FakeVoiceService('Salz')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FreeCookingPage.voiceZoneKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(FreeCookingHeader.closeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byKey(_startKey), findsOneWidget);
  });
}

/// Scrolls the "Gekocht" step down to the destination switch.
Future<void> _showDestination(WidgetTester tester) => tester.scrollUntilVisible(
  find.byType(CookedMealDestinationSection),
  200,
  scrollable: find
      .descendant(
        of: find.byType(CookedMealPage),
        matching: find.byType(Scrollable),
      )
      .first,
);

ButtonSegment<CookedMealDestination> _segment(
  WidgetTester tester,
  CookedMealDestination value,
) => tester
    .widget<SegmentedButton<CookedMealDestination>>(
      find.byType(SegmentedButton<CookedMealDestination>),
    )
    .segments
    .singleWhere((segment) => segment.value == value);

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(CookedMealPage.saveKey));

Widget _app({
  required _FakeMealRepository meals,
  required _FakeVoiceService voice,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              key: _startKey,
              onPressed: () => context.push(AppRoutes.homeFreeCooking),
              child: const Text('Start'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeFreeCooking,
        builder: (context, state) => const FreeCookingPage(),
      ),
      GoRoute(
        path: AppRoutes.homeCookedMeal,
        builder: (context, state) =>
            CookedMealPage(mealId: state.pathParameters['mealId']!),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      preparedMealRepositoryProvider.overrideWithValue(meals),
      inventoryItemRepositoryProvider.overrideWithValue(
        _FakeInventoryRepository([
          InventoryItem.create(
            id: 'rice',
            name: 'Reis',
            entryDate: DateTime.utc(2026, 9, 29),
            storeName: 'Store',
            quantity: 1,
            initialAmount: 1000,
            currentAmount: 1000,
            amountUnit: InventoryAmountUnit.gram,
          ),
        ]),
      ),
      inventoryActivityEventRepositoryProvider.overrideWithValue(
        _FakeActivityRepository(),
      ),
      inventoryActivityActorProvider.overrideWithValue(null),
      voiceSearchServiceProvider.overrideWithValue(voice),
      kitchenUtensilRepositoryProvider.overrideWithValue(
        _FakeUtensilRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

/// Hears [transcript] once, then stays silent.
class _FakeVoiceService implements VoiceSearchService {
  new(this.transcript);

  final String transcript;
  var _heard = false;
  ValueChanged<bool>? _onListening;

  @override
  bool isListening = false;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    isListening = true;
    _onListening = onListeningStateChanged;
    onListeningStateChanged(true);
    if (!_heard) {
      _heard = true;
      scheduleMicrotask(
        () => onResult(
          VoiceSearchRecognition(transcript: transcript, isFinal: true),
        ),
      );
    }
    return null;
  }

  @override
  Future<void> stopListening() async {
    isListening = false;
    _onListening?.call(false);
  }

  @override
  Future<void> cancelListening() => stopListening();
}

class _FakeMealRepository implements PreparedMealRepository {
  final _changes = StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> saved = const [];

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield saved;
    yield* _changes.stream;
  }

  @override
  Future<List<PreparedMeal>> readAll() async => saved;

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async {
    saved = meals;
    _changes.add(meals);
    return true;
  }
}

class _FakeUtensilRepository implements KitchenUtensilRepository {
  @override
  Stream<List<KitchenUtensil>> watchAll() async* {
    yield [
      KitchenUtensil(
        id: 'pot',
        name: 'Topf',
        weightGrams: 400,
        createdAt: DateTime.utc(2026, 9),
        updatedAt: DateTime.utc(2026, 9),
      ),
    ];
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInventoryRepository implements InventoryItemRepository {
  new(this.items);

  List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    this.items = items;
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    this.items = [...this.items, ...items];
    return true;
  }
}

class _FakeActivityRepository implements InventoryActivityEventRepository {
  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return const Stream.empty();
  }

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async => true;
}
