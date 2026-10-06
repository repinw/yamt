import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/router/hero_sheet_page.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_amount_edit_flow.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_stock_adjustment.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/presentation/diary_entry_details_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_entry_actions_card.dart';
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
    'eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User;

/// Writes the delete and its stock change to the diary fake and records the
/// stock that went back and came out again.
class _ItemStore implements InventoryCalorieEntryCommitStore {
  const new(this.diary, {required this.restored, required this.takenBack});

  final CalorieLogRepositoryContract diary;
  final List<(String, int)> restored;
  final List<(String, int)> takenBack;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async {
    await diary.deleteEntry(entry.id);
    restored.addAll([
      for (final e in amountsByItemId.entries) (e.key, e.value),
    ]);
    return [
      for (final itemId in amountsByItemId.keys)
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
  }) async {
    await diary.saveEntry(entry);
    takenBack.addAll([
      for (final pending in pendingConsumptions)
        (pending.itemId, pending.amount),
    ]);
    return const [];
  }
}

class _Items implements InventoryItemRepository {
  const new(this.ids);

  final List<String> ids;

  @override
  Future<List<InventoryItem>> readAll() async => [
    for (final id in ids)
      InventoryItem.create(
        id: id,
        name: 'Skyr',
        entryDate: DateTime(2026, 2, 20),
        storeName: 'Aldi',
        quantity: 1,
        initialAmount: 500,
        currentAmount: 500,
        amountUnit: InventoryAmountUnit.gram,
      ),
  ];

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.fromFuture(readAll());

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

final _now = DateTime(2026, 2, 26, 9, 30);
const _diaryText = 'Diary below';

CalorieEntry _skyr({
  String? sourceInventoryItemId,
  int? sourceInventoryAmountToRestore,
}) {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    brand: 'Milbona, Lidl',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    sourceInventoryItemId: sourceInventoryItemId,
    sourceInventoryAmountToRestore: sourceInventoryAmountToRestore,
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
    bundleConsumedPortions: 0.5,
    bundleTotalPortions: 4,
    bundleComponents: const [
      CalorieEntryBundleComponent(
        name: 'Beans',
        amountLabel: '150 g',
        totalKcal: 120,
        totalProtein: 8,
        totalCarbs: 18,
        totalFat: 1,
      ),
    ],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

CalorieEntry _quickEntry() {
  final loggedAt = DateTime(2026, 2, 25, 15);
  return buildQuickCalorieEntry(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Kuchen',
    mealType: MealType.snack,
    loggedAt: loggedAt,
    now: loggedAt,
    kcal: 350,
    fat: 18,
  );
}

/// Diary stand-in that opens the details page on its first frame, so the
/// page can close back to it.
class _OpenDetails extends StatefulWidget {
  const new();

  @override
  State<_OpenDetails> createState() => _OpenDetailsState();
}

class _OpenDetailsState extends State<_OpenDetails> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          context.push<void>(AppRoutes.homeCaloriesEntryDetailsPath('entry-1')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text(_diaryText));
  }
}

Future<FakeCalorieLogRepository> _open(
  WidgetTester tester,
  List<CalorieEntry> entries, {
  List<Override> overrides = const <Override>[],
  Locale locale = const Locale('en'),
}) async {
  final logRepository = FakeCalorieLogRepository(initialEntries: entries);
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(logRepository.dispose);
  addTearDown(settingsRepository.dispose);
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _OpenDetails()),
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
      clockProvider.overrideWithValue(() => _now),
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
        locale: locale,
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return logRepository;
}

Finder get _saveButton => find.byKey(DiaryEntryDetailsPage.saveButtonKey);

bool _isPageOpen() => find.byType(DiaryEntryDetailsPage).evaluate().isNotEmpty;

/// Taps the undo of the top snack bar. The diary below the page shows the
/// same snack bar.
Future<void> _tapUndo(WidgetTester tester) async {
  await tester.tap(find.text('Undo').last);
  await tester.pumpAndSettle();
}

Future<void> _pickMeal(WidgetTester tester, String meal) async {
  await tester.tap(find.byKey(EatWhenMenu.buttonKey));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(CheckedPopupMenuItem<Object>, meal));
  await tester.pumpAndSettle();
}

Future<void> _tapCardLine(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens the entry with its label and amount', (tester) async {
    await _open(tester, [_skyr()]);

    expect(find.text('Skyr'), findsOneWidget);
    expect(find.text('MILBONA'), findsOneWidget);
    expect(find.byKey(DiaryEntryLabelSection.labelKey), findsOneWidget);
    expect(find.text('Per 100 g'), findsOneWidget);
    expect(find.text('200 g'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(EatAmountRuler.fieldKey));
    expect(field.controller?.text, '200');
    expect(find.text('FEB 25 · BREAKFAST'), findsOneWidget);
    expect(find.text('200 kcal'), findsOneWidget);
    expect(find.byKey(DiaryEntryActionsCard.eatAgainKey), findsOneWidget);
    expect(find.byKey(DiaryEntryActionsCard.removeKey), findsOneWidget);
  });

  testWidgets('saves a changed amount, closes, and can undo it', (
    tester,
  ) async {
    final repository = await _open(tester, [_skyr()]);

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '150');
    await tester.pump();

    expect(find.text('150 kcal'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(repository.entries.single.consumedAmount, 200);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    final saved = repository.entries.single;
    expect(saved.consumedAmount, 150);
    expect(saved.totalKcal, 150);
    expect(saved.totalProtein, 15);
    expect(_isPageOpen(), isFalse);
    expect(find.text(_diaryText), findsOneWidget);
    expect(find.text('Entry updated'), findsOneWidget);

    await _tapUndo(tester);

    expect(repository.entries.single.consumedAmount, 200);
    expect(repository.entries.single.totalKcal, 200);
  });

  testWidgets('saving an unchanged amount only closes the page', (
    tester,
  ) async {
    final repository = await _open(tester, [_skyr()]);
    final stored = repository.entries.single;

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(_isPageOpen(), isFalse);
    expect(identical(repository.entries.single, stored), isTrue);
  });

  testWidgets('an invalid amount disables saving', (tester) async {
    await _open(tester, [_skyr()]);

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '0');
    await tester.pump();

    expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);
    expect(
      find.text('Please enter a number greater than zero.'),
      findsOneWidget,
    );
  });

  testWidgets('a changed amount moves the stock of an inventory entry', (
    tester,
  ) async {
    final adjustedAmounts = <double>[];
    final repository = await _open(
      tester,
      [
        _skyr(
          sourceInventoryItemId: 'inventory-1',
          sourceInventoryAmountToRestore: 200,
        ),
      ],
      overrides: [
        calorieInventoryStockAdjusterProvider.overrideWith((ref) {
          return ({
            required itemId,
            required reservedAmount,
            required consumedAmount,
          }) async {
            adjustedAmounts.add(consumedAmount);
            return CalorieInventoryStockAdjustment(
              status: CalorieInventoryStockAdjustmentStatus.applied,
              reservedAmount: consumedAmount.round(),
            );
          };
        }),
      ],
    );

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '300');
    await tester.pump();
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(repository.entries.single.consumedAmount, 300);
    expect(repository.entries.single.sourceInventoryAmountToRestore, 300);
    expect(adjustedAmounts, <double>[300]);

    await _tapUndo(tester);

    expect(repository.entries.single.consumedAmount, 200);
    expect(repository.entries.single.sourceInventoryAmountToRestore, 200);
    expect(adjustedAmounts, <double>[300, 200]);
  });

  testWidgets('removes the entry, closes, and can undo it', (tester) async {
    final repository = await _open(tester, [_skyr()]);

    await _tapCardLine(tester, DiaryEntryActionsCard.removeKey);

    expect(repository.entries, isEmpty);
    expect(_isPageOpen(), isFalse);
    expect(find.text('Entry removed'), findsOneWidget);

    await _tapUndo(tester);

    expect(repository.entries.single.id, 'entry-1');
  });

  testWidgets('removing an inventory entry can return its stock', (
    tester,
  ) async {
    final restored = <(String, int)>[];
    final takenBack = <(String, int)>[];
    final repository = await _open(
      tester,
      [
        _skyr(
          sourceInventoryItemId: 'inventory-1',
          sourceInventoryAmountToRestore: 200,
        ),
      ],
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(
          const _Items(['inventory-1']),
        ),
        inventoryCalorieEntryCommitStoreProvider.overrideWith(
          (ref) => _ItemStore(
            ref.watch(calorieLogRepositoryProvider),
            restored: restored,
            takenBack: takenBack,
          ),
        ),
      ],
    );

    await _tapCardLine(tester, DiaryEntryActionsCard.removeKey);
    await tester.tap(find.text('Return to inventory'));
    await tester.pumpAndSettle();

    expect(repository.entries, isEmpty);
    expect(restored, [('inventory-1', 200)]);
    expect(_isPageOpen(), isFalse);
    expect(find.text('Returned to inventory'), findsOneWidget);

    await _tapUndo(tester);

    expect(repository.entries.single.id, 'entry-1');
    expect(takenBack, [('inventory-1', 200)]);
  });

  testWidgets('moves the entry to another meal at once and can undo it', (
    tester,
  ) async {
    final repository = await _open(tester, [_skyr()]);

    await _pickMeal(tester, 'Snack');

    expect(repository.entries.single.mealType, MealType.snack);
    expect(repository.entries.single.updatedAt, _now);
    expect(_isPageOpen(), isTrue);
    expect(find.text('FEB 25 · SNACK'), findsOneWidget);
    expect(find.text('Entry updated'), findsWidgets);

    await _tapUndo(tester);

    expect(repository.entries.single.mealType, MealType.breakfast);
    expect(find.text('FEB 25 · BREAKFAST'), findsOneWidget);
  });

  testWidgets('keeps the stored meal when the move fails', (tester) async {
    final repository = await _open(tester, [_skyr()]);
    repository.saveShouldFail = true;

    await _pickMeal(tester, 'Snack');

    expect(repository.entries.single.mealType, MealType.breakfast);
    expect(find.text('FEB 25 · BREAKFAST'), findsOneWidget);
    expect(find.text('Could not save entry.'), findsWidgets);
  });

  testWidgets('logs the same food again and closes', (tester) async {
    final repository = await _open(tester, [_skyr()]);

    await _tapCardLine(tester, DiaryEntryActionsCard.eatAgainKey);

    expect(repository.entries, hasLength(2));
    final repeated = repository.entries.last;
    expect(repeated.id, isNot('entry-1'));
    expect(repeated.consumedAmount, 200);
    expect(repeated.loggedAt, _now);
    expect(_isPageOpen(), isFalse);
    expect(find.text('Logged again'), findsOneWidget);
  });

  testWidgets('shows a prepared meal with its foods and without a ruler', (
    tester,
  ) async {
    await _open(tester, [_preparedMeal()], locale: const Locale('de'));

    expect(find.text('Chili'), findsOneWidget);
    expect(find.text('MAHLZEITEN'), findsOneWidget);
    expect(find.text('0,5/4 Portionen'), findsOneWidget);
    expect(find.textContaining('Je 100'), findsNothing);
    expect(find.byKey(EatAmountRuler.fieldKey), findsNothing);
    expect(find.text('Beans'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(find.byKey(DiaryEntryActionsCard.eatAgainKey), findsNothing);
    expect(find.byKey(DiaryEntryActionsCard.removeKey), findsOneWidget);
  });

  testWidgets('shows a quick entry with its typed values only', (tester) async {
    await _open(tester, [_quickEntry()], locale: const Locale('de'));

    expect(find.text('Kuchen'), findsOneWidget);
    expect(find.text('Gegessen'), findsOneWidget);
    expect(find.textContaining('Je 100'), findsNothing);
    expect(find.text('100 g'), findsNothing);
    expect(find.byKey(EatAmountRuler.fieldKey), findsNothing);
    expect(find.byKey(DiaryEntryActionsCard.eatAgainKey), findsOneWidget);
  });

  testWidgets('shows a message for a missing entry', (tester) async {
    await _open(tester, const <CalorieEntry>[]);

    expect(find.text('Entry not found.'), findsOneWidget);
  });

  testWidgets('fits a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _open(tester, [_skyr()]);

    expect(tester.takeException(), isNull);
  });
}
