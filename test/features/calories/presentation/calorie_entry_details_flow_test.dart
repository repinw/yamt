import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_details_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User;

const _hostPath = '/details';
const _removeKey = Key('remove');
const _belowText = 'Below';

CalorieEntry _stockEntry({String itemId = 'inventory-1'}) {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    sourceInventoryItemId: itemId,
    sourceInventoryAmountToRestore: 2,
    loggedAt: DateTime(2026, 2, 25, 8),
    createdAt: DateTime(2026, 2, 25, 8),
    updatedAt: DateTime(2026, 2, 25, 8),
  );
}

CalorieEntry _preparedMeal() {
  final loggedAt = DateTime(2026, 2, 25, 12);
  return CalorieEntry.bundle(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Chili',
    mealType: MealType.lunch,
    totalKcal: 420,
    totalProtein: 28,
    totalCarbs: 35,
    totalFat: 18,
    bundleSourcePreparedMealId: 'prepared-1',
    bundleConsumedPortions: 2,
    bundleTotalPortions: 4,
    bundleComponents: const [
      CalorieEntryBundleComponent(
        name: 'Beans',
        amountLabel: '150 g',
        totalKcal: 420,
        totalProtein: 28,
        totalCarbs: 35,
        totalFat: 18,
      ),
    ],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

CalorieEntryDeleteFlow _deleteFlow(
  Ref ref, {
  Future<bool> Function(String itemId, int amount)? restoreConsumedItem,
  Future<bool> Function(String itemId)? sourceInventoryItemExists,
  Future<bool> Function({required String mealId, required num portions})?
  restorePreparedMealPortions,
}) {
  return CalorieEntryDeleteFlow(
    deleteEntryById: ref.read(calorieLogRepositoryProvider).deleteEntry,
    restoreConsumedItem: restoreConsumedItem ?? (_, _) async => true,
    rollbackRestoredItem: (_, _, {consumedAt}) async => true,
    restoreConsumedItems: (_) async => true,
    rollbackRestoredItems: (_, {consumedAt}) async => true,
    sourceInventoryItemExists: sourceInventoryItemExists ?? (_) async => true,
    restorePreparedMealPortions:
        restorePreparedMealPortions ??
        ({required mealId, required portions}) async => true,
    rollbackRestoredPreparedMeal: ({
      required mealId,
      required discardedPortions,
    }) async => true,
    sourcePreparedMealExists: (_) async => true,
  );
}

/// Page below the details stand-in, which it opens on its first frame.
class _Below extends StatefulWidget {
  const new();

  @override
  State<_Below> createState() => _BelowState();
}

class _BelowState extends State<_Below> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.push<void>(_hostPath));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text(_belowText));
  }
}

/// Details page stand-in that removes [entry] through the flow.
class _DetailsHost extends StatelessWidget {
  const new({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: _removeKey,
          onPressed: () =>
              unawaited(CalorieEntryDetailsFlow.remove(context, entry: entry)),
          child: const Text('Remove'),
        ),
      ),
    );
  }
}

Future<FakeCalorieLogRepository> _open(
  WidgetTester tester,
  CalorieEntry entry, {
  List<Override> overrides = const <Override>[],
}) async {
  final logRepository = FakeCalorieLogRepository(initialEntries: [entry]);
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(logRepository.dispose);
  addTearDown(settingsRepository.dispose);
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _Below()),
      GoRoute(
        path: _hostPath,
        builder: (context, state) => _DetailsHost(entry: entry),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      firebaseFirestoreProvider.overrideWith((ref) => null),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return logRepository;
}

Future<void> _remove(WidgetTester tester) async {
  await tester.tap(find.byKey(_removeKey));
  await tester.pumpAndSettle();
}

bool _isHostOpen() => find.byType(_DetailsHost).evaluate().isNotEmpty;

void main() {
  testWidgets('deletes only the diary entry when chosen in the dialog', (
    tester,
  ) async {
    final restored = <String>[];
    final repository = await _open(
      tester,
      _stockEntry(),
      overrides: [
        calorieEntryDeleteFlowProvider.overrideWith(
          (ref) => _deleteFlow(
            ref,
            restoreConsumedItem: (itemId, amount) async {
              restored.add(itemId);
              return true;
            },
          ),
        ),
      ],
    );

    await _remove(tester);

    expect(
      find.text('Would you like to return this food to the inventory?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete from diary only'));
    await tester.pumpAndSettle();

    expect(repository.entries, isEmpty);
    expect(restored, isEmpty);
    expect(_isHostOpen(), isFalse);
    expect(find.text('Entry removed'), findsOneWidget);
  });

  testWidgets('keeps the entry when the stock cannot return', (tester) async {
    final repository = await _open(
      tester,
      _stockEntry(),
      overrides: [
        calorieEntryDeleteFlowProvider.overrideWith(
          (ref) => _deleteFlow(ref, restoreConsumedItem: (_, _) async => false),
        ),
      ],
    );

    await _remove(tester);
    await tester.tap(find.text('Return to inventory'));
    await tester.pumpAndSettle();

    expect(
      find.text('The food could not be added back to inventory.'),
      findsOneWidget,
    );
    expect(repository.entries, hasLength(1));
    expect(_isHostOpen(), isTrue);
  });

  testWidgets('offers the diary-only delete when the stock item is gone', (
    tester,
  ) async {
    final repository = await _open(
      tester,
      _stockEntry(itemId: 'missing-item'),
      overrides: [
        calorieEntryDeleteFlowProvider.overrideWith(
          (ref) =>
              _deleteFlow(ref, sourceInventoryItemExists: (_) async => false),
        ),
      ],
    );

    await _remove(tester);

    expect(find.text('Food no longer in inventory'), findsOneWidget);
    expect(
      find.text(
        '"Skyr" is no longer in inventory, so it cannot be returned. '
        'Delete it from the diary only?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete from diary'));
    await tester.pumpAndSettle();

    expect(repository.entries, isEmpty);
    expect(_isHostOpen(), isFalse);
  });

  testWidgets('asks again when the stock item disappears while returning', (
    tester,
  ) async {
    var sourceChecks = 0;
    final repository = await _open(
      tester,
      _stockEntry(),
      overrides: [
        calorieEntryDeleteFlowProvider.overrideWith(
          (ref) => _deleteFlow(
            ref,
            sourceInventoryItemExists: (_) async {
              sourceChecks += 1;
              return sourceChecks == 1;
            },
          ),
        ),
      ],
    );

    await _remove(tester);
    await tester.tap(find.text('Return to inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Food no longer in inventory'), findsOneWidget);

    await tester.tap(find.text('Delete from diary'));
    await tester.pumpAndSettle();

    expect(repository.entries, isEmpty);
    expect(_isHostOpen(), isFalse);
  });

  testWidgets('keeps a prepared meal entry when its portions cannot return', (
    tester,
  ) async {
    final repository = await _open(
      tester,
      _preparedMeal(),
      overrides: [
        calorieEntryDeleteFlowProvider.overrideWith(
          (ref) => _deleteFlow(
            ref,
            restorePreparedMealPortions: ({
              required mealId,
              required portions,
            }) async => false,
          ),
        ),
      ],
    );

    await _remove(tester);
    await tester.tap(find.text('Return to inventory'));
    await tester.pumpAndSettle();

    expect(
      find.text('The meal could not be returned to inventory.'),
      findsOneWidget,
    );
    expect(repository.entries, hasLength(1));
    expect(_isHostOpen(), isTrue);
    expect(find.text(_belowText), findsNothing);
  });
}
