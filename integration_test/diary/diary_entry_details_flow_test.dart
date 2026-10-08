import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/router/hero_sheet_page.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/diary_entry_details_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_entry_delete_dialogs.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_entry_label_section.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';

class _MockUser extends Mock implements User;

/// Deletes or saves the entry in the diary fake and records the stock that
/// went back, like the Firestore batch does.
class _ItemStore implements InventoryCalorieEntryCommitStore {
  new(this.diary);

  final FakeCalorieLogRepository diary;
  final restored = <String, int>{};

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async {
    await diary.saveEntry(entry);
    return _restore(amountsByItemId);
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async {
    await diary.deleteEntry(entry.id);
    return _restore(amountsByItemId);
  }

  List<InventoryCalorieEntryCommitResult> _restore(Map<String, int> amounts) {
    restored.addAll(amounts);
    return [
      for (final itemId in amounts.keys)
        InventoryCalorieEntryCommitResult(
          itemId: itemId,
          quantity: 1,
          currentAmount: 500,
        ),
    ];
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) => throw UnimplementedError();
}

class _Items with InventoryItemWholeListWrites {
  const new();

  @override
  Future<List<InventoryItem>> readAll() async => [
    InventoryItem.create(
      id: 'skyr',
      name: 'Skyr',
      entryDate: DateTime(2026, 5, 10),
      storeName: 'Lidl',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 300,
      amountUnit: InventoryAmountUnit.gram,
    ),
  ];

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.fromFuture(readAll());

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

const _openButtonKey = Key('diary_entry_details_flow_open');

CalorieEntry _entry({String? sourceItemId}) {
  final loggedAt = DateTime(2026, 5, 13, 8);
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
    sourceInventoryItemId: sourceItemId,
    sourceInventoryAmountToRestore: sourceItemId == null ? null : 200,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final end = tester.binding.clock.fromNowBy(const Duration(seconds: 8));
  while (finder.evaluate().isEmpty) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $finder.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Opens the details page of [_entry] from a start page.
Future<void> _openDetails(
  WidgetTester tester,
  FakeCalorieLogRepository logRepository, {
  List<Override> overrides = const [],
  FakePlannedEntryRepository? plans,
}) async {
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(settingsRepository.dispose);
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              key: _openButtonKey,
              onPressed: () => unawaited(
                context.push<void>(
                  AppRoutes.homeCaloriesEntryDetailsPath('entry-1'),
                ),
              ),
              child: const Icon(Icons.open_in_new),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryDetails,
        pageBuilder: (context, state) => HeroSheetPage<void>(
          key: state.pageKey,
          child: DiaryEntryDetailsPage(
            entryId: state.pathParameters['entryId']!,
          ),
        ),
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
      plannedEntryRepositoryProvider.overrideWithValue(
        plans ?? FakePlannedEntryRepository(),
      ),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('de'),
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await _pumpUntilFound(tester, find.byKey(_openButtonKey));
  await tester.tap(find.byKey(_openButtonKey));
  await _pumpUntilFound(tester, find.byKey(DiaryEntryLabelSection.labelKey));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('diary entry details save a changed amount', (tester) async {
    final logRepository = FakeCalorieLogRepository(initialEntries: [_entry()]);
    addTearDown(logRepository.dispose);
    await _openDetails(tester, logRepository);

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '150');
    await tester.pump();
    await tester.tap(find.byKey(DiaryEntryDetailsPage.saveButtonKey));
    await _pumpUntilFound(tester, find.byKey(_openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryEntryDetailsPage), findsNothing);
    expect(logRepository.entries.single.consumedAmount, 150);
    expect(logRepository.entries.single.totalKcal, 150);
  });

  testWidgets('"Nochmal" logs the food a second time', (tester) async {
    final logRepository = FakeCalorieLogRepository(initialEntries: [_entry()]);
    addTearDown(logRepository.dispose);
    await _openDetails(tester, logRepository);

    // An unchanged amount leaves "Nochmal" as the main button.
    expect(find.text('Nochmal'), findsOneWidget);
    await tester.tap(find.byKey(DiaryEntryDetailsPage.saveButtonKey));
    await _pumpUntilFound(tester, find.byKey(_openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryEntryDetailsPage), findsNothing);
    expect(logRepository.entries, hasLength(2));
    expect(logRepository.entries.map((entry) => entry.name), ['Skyr', 'Skyr']);
    expect(logRepository.entries.last.consumedAmount, 200);
  });

  testWidgets('the plan icon plans the food again for a picked day', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository(initialEntries: [_entry()]);
    addTearDown(logRepository.dispose);
    final plans = FakePlannedEntryRepository();
    await _openDetails(tester, logRepository, plans: plans);

    final plan = find.byKey(EatPageScaffold.planButtonKey);
    await tester.ensureVisible(plan);
    await tester.pumpAndSettle();
    await tester.tap(plan);
    await _pumpUntilFound(tester, find.text('OK'));
    await tester.tap(find.text('OK'));
    await _pumpUntilFound(tester, find.byKey(_openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryEntryDetailsPage), findsNothing);
    expect(logRepository.entries, hasLength(1));
    expect(plans.plans.single.name, 'Skyr');
    expect(plans.plans.single.mealType, MealType.breakfast);
    expect(plans.plans.single.consumedAmount, 200);
  });

  testWidgets('diary entry details stay open on close while saving', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository(initialEntries: [_entry()]);
    addTearDown(logRepository.dispose);
    final saveGate = Completer<void>();
    logRepository.saveGate = saveGate.future;
    await _openDetails(tester, logRepository);

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '150');
    await tester.pump();
    await tester.tap(find.byKey(DiaryEntryDetailsPage.saveButtonKey));
    await tester.pump();
    await tester.tap(find.byKey(DiaryEntryDetailsPage.closeButtonKey));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DiaryEntryDetailsPage), findsOneWidget);

    saveGate.complete();
    await _pumpUntilFound(tester, find.byKey(_openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryEntryDetailsPage), findsNothing);
    expect(logRepository.entries.single.consumedAmount, 150);
  });

  testWidgets('removing an entry gives its stock back to the Vorrat', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository(
      initialEntries: [_entry(sourceItemId: 'skyr')],
    );
    addTearDown(logRepository.dispose);
    final itemStore = _ItemStore(logRepository);
    await _openDetails(
      tester,
      logRepository,
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(const _Items()),
        inventoryCalorieEntryCommitStoreProvider.overrideWithValue(itemStore),
      ],
    );

    final remove = find.byKey(EatPageScaffold.deleteButtonKey);
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await _pumpUntilFound(
      tester,
      find.byKey(diaryEntryReturnToInventoryButtonKey),
    );
    await tester.tap(find.byKey(diaryEntryReturnToInventoryButtonKey));
    await _pumpUntilFound(tester, find.byKey(_openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryEntryDetailsPage), findsNothing);
    expect(logRepository.entries, isEmpty);
    expect(itemStore.restored, {'skyr': 200});
  });

  testWidgets('a smaller amount gives the difference back to the Vorrat', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository(
      initialEntries: [_entry(sourceItemId: 'skyr')],
    );
    addTearDown(logRepository.dispose);
    final itemStore = _ItemStore(logRepository);
    await _openDetails(
      tester,
      logRepository,
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(const _Items()),
        inventoryCalorieEntryCommitStoreProvider.overrideWithValue(itemStore),
      ],
    );

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '150');
    await tester.pump();
    await tester.tap(find.byKey(DiaryEntryDetailsPage.saveButtonKey));
    await _pumpUntilFound(tester, find.byKey(_openButtonKey));
    await tester.pumpAndSettle();

    expect(logRepository.entries.single.consumedAmount, 150);
    expect(logRepository.entries.single.sourceInventoryAmountToRestore, 150);
    expect(itemStore.restored, {'skyr': 50});
  });
}
