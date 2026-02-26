import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/data/receipt_to_fridge_item_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_quick_add_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../calories/support/fake_calories_repositories.dart';
import '../shoppinglist/support/fake_shopping_list_repository.dart';

class _MockUser extends Mock implements User {}

_MockUser _authenticatedUser() {
  final user = _MockUser();
  when(() => user.uid).thenReturn('uid-123');
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.displayName).thenReturn('Jane Doe');
  when(() => user.email).thenReturn('jane@example.com');
  return user;
}

class _FakeAppPreferences implements AppPreferences {
  _FakeAppPreferences({Map<String, Object>? initialValues})
    : _values = initialValues ?? <String, Object>{};

  final Map<String, Object> _values;

  @override
  String? getStringSync(String key) {
    return _values[key] as String?;
  }

  @override
  int? getIntSync(String key) {
    return _values[key] as int?;
  }

  @override
  Future<String?> getString(String key) async {
    return _values[key] as String?;
  }

  @override
  Future<int?> getInt(String key) async {
    return _values[key] as int?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }
}

class _FakeReceiptInputRepository implements ReceiptInputRepository {
  _FakeReceiptInputRepository({required this.onPickFromFiles});

  final Future<ReceiptInputBatchResult> Function() onPickFromFiles;

  @override
  Future<ReceiptInputResult> pickFromCamera() async {
    return const ReceiptInputResult.canceled();
  }

  @override
  Future<ReceiptInputResult> pickFromFile() async {
    return const ReceiptInputResult.canceled();
  }

  @override
  Future<ReceiptInputBatchResult> pickFromFiles() {
    return onPickFromFiles();
  }
}

class _FakeReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  _FakeReceiptAnalysisRepository({required this.onAnalyzeSelection});

  final Future<ReceiptAnalysisResult> Function(ReceiptInputSelection selection)
  onAnalyzeSelection;

  @override
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) {
    return onAnalyzeSelection(selection);
  }
}

class _FakeReceiptToFridgeItemMapper implements ReceiptToFridgeItemMapper {
  _FakeReceiptToFridgeItemMapper({required this.onMap});

  final List<FridgeItem> Function(ReceiptAnalysisExtraction extraction) onMap;

  @override
  List<FridgeItem> map(ReceiptAnalysisExtraction extraction) {
    return onMap(extraction);
  }
}

ReceiptInputSelection _receiptSelection({required String name}) {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: name,
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

FridgeItem _mappedFridgeItem() {
  return FridgeItem(
    id: 'mapped-item',
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-21T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.99,
  );
}

ProviderContainer _createContainer({List overrides = const <Object>[]}) {
  final shoppingRepository = FakeShoppingListRepository();
  final calorieLogRepository = FakeCalorieLogRepository();
  final calorieSettingsRepository = FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream<User?>.value(_authenticatedUser()),
      ),
      appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
      shoppingListRepositoryProvider.overrideWithValue(shoppingRepository),
      calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        calorieSettingsRepository,
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  addTearDown(shoppingRepository.dispose);
  addTearDown(calorieLogRepository.dispose);
  addTearDown(calorieSettingsRepository.dispose);
  return container;
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpFor(
  WidgetTester tester, {
  int steps = 6,
  Duration step = const Duration(milliseconds: 120),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

void main() {
  testWidgets('home shell shows app bar and tabs for authenticated user', (
    tester,
  ) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    expect(find.text('Inventory'), findsAtLeastNWidgets(1));
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('inventory FAB opens receipt action sheet', (tester) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);

    expect(find.text('Scan receipt (camera)'), findsOneWidget);
    expect(find.text('Upload receipt (image/PDF)'), findsOneWidget);
  });

  testWidgets('shopping FAB opens add dialog and adds item', (tester) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await _pumpUi(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(ShoppingQuickAddDialogKeys.nameField), findsOneWidget);

    await tester.enterText(
      find.byKey(ShoppingQuickAddDialogKeys.nameField),
      'Milk',
    );
    await tester.enterText(
      find.byKey(ShoppingQuickAddDialogKeys.brandField),
      'Acme',
    );
    await tester.tap(find.byKey(ShoppingQuickAddDialogKeys.confirmButton));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('shopping FAB shows validation error on empty name', (
    tester,
  ) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await _pumpUi(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);
    await tester.enterText(
      find.byKey(ShoppingQuickAddDialogKeys.nameField),
      ' ',
    );
    await tester.tap(find.byKey(ShoppingQuickAddDialogKeys.confirmButton));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Please enter an item name.'), findsOneWidget);
  });

  testWidgets('shopping quick-add cancel closes dialog and keeps list', (
    tester,
  ) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await _pumpUi(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);
    await tester.enterText(
      find.byKey(ShoppingQuickAddDialogKeys.nameField),
      'Milk',
    );
    await tester.tap(find.byKey(ShoppingQuickAddDialogKeys.cancelButton));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Milk'), findsNothing);
  });

  testWidgets('calories FAB opens add-options sheet and manual entry route', (
    tester,
  ) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byIcon(Icons.local_fire_department_outlined));
    await _pumpUi(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);

    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);

    await tester.tap(find.byKey(CaloriesPageKeys.addOptionsManualButton));
    await _pumpUi(tester);
    expect(find.text('Add calorie entry'), findsOneWidget);
    expect(find.byKey(CalorieEntryEditorKeys.nameField), findsOneWidget);
  });

  testWidgets('settings FAB shows context snackbar', (tester) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('Settings').first);
    await _pumpUi(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);
    expect(find.text('Settings action coming soon.'), findsOneWidget);
  });

  testWidgets('inventory upload canceled closes dialog without snackbar', (
    tester,
  ) async {
    final inputRepository = _FakeReceiptInputRepository(
      onPickFromFiles: () async => const ReceiptInputBatchResult.canceled(),
    );
    final container = _createContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(inputRepository),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);
    final context = tester.element(find.byType(Scaffold).first);
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);
    await tester.tap(find.text('Upload receipt (image/PDF)'));
    await _pumpFor(tester);

    expect(find.text(l10n.inventoryReceiptBatchTitle), findsNothing);
    expect(find.text(l10n.inventoryReceiptSelectionFailed), findsNothing);
    expect(find.text(l10n.inventoryReceiptAnalysisFailed), findsNothing);
  });

  testWidgets(
    'inventory upload shows selection-failed snackbar on input error',
    (tester) async {
      final inputRepository = _FakeReceiptInputRepository(
        onPickFromFiles: () async => const ReceiptInputBatchResult.failed(
          errorCode: ReceiptInputErrorCodes.filePickFailed,
        ),
      );
      final container = _createContainer(
        overrides: [
          receiptInputRepositoryProvider.overrideWithValue(inputRepository),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpUi(tester);
      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.byType(FloatingActionButton));
      await _pumpUi(tester);
      await tester.tap(find.text('Upload receipt (image/PDF)'));
      await _pumpFor(tester);

      expect(find.text(l10n.inventoryReceiptSelectionFailed), findsOneWidget);
    },
  );

  testWidgets(
    'inventory upload shows analysis-failed snackbar for empty batch',
    (tester) async {
      final inputRepository = _FakeReceiptInputRepository(
        onPickFromFiles: () async => ReceiptInputBatchResult.selected(
          selections: <ReceiptInputSelection>[_receiptSelection(name: 'a.jpg')],
        ),
      );
      final analysisRepository = _FakeReceiptAnalysisRepository(
        onAnalyzeSelection: (_) async => const ReceiptAnalysisResult.failed(
          errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
        ),
      );
      final container = _createContainer(
        overrides: [
          receiptInputRepositoryProvider.overrideWithValue(inputRepository),
          receiptAnalysisRepositoryProvider.overrideWithValue(
            analysisRepository,
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpUi(tester);
      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.byType(FloatingActionButton));
      await _pumpUi(tester);
      await tester.tap(find.text('Upload receipt (image/PDF)'));
      await _pumpFor(tester);

      expect(find.text(l10n.inventoryReceiptAnalysisFailed), findsOneWidget);
    },
  );

  testWidgets('inventory upload opens progress dialog and review sheet', (
    tester,
  ) async {
    final inputRepository = _FakeReceiptInputRepository(
      onPickFromFiles: () async => ReceiptInputBatchResult.selected(
        selections: <ReceiptInputSelection>[_receiptSelection(name: 'a.jpg')],
      ),
    );
    final analysisRepository = _FakeReceiptAnalysisRepository(
      onAnalyzeSelection: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return const ReceiptAnalysisResult.succeeded(
          rawResponse: '{"items":[{"name":"Milk"}]}',
          extraction: ReceiptAnalysisExtraction(
            root: <String, dynamic>{},
            items: <ReceiptAnalysisItem>[
              ReceiptAnalysisItem(
                name: 'Milk',
                rawPayload: <String, dynamic>{'n': 'Milk'},
              ),
            ],
          ),
        );
      },
    );
    final mapper = _FakeReceiptToFridgeItemMapper(
      onMap: (_) => <FridgeItem>[_mappedFridgeItem()],
    );
    final container = _createContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(inputRepository),
        receiptAnalysisRepositoryProvider.overrideWithValue(analysisRepository),
        receiptToFridgeItemMapperProvider.overrideWithValue(mapper),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);
    final context = tester.element(find.byType(Scaffold).first);
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);
    await tester.tap(find.text('Upload receipt (image/PDF)'));
    await tester.pump();
    expect(find.text(l10n.inventoryReceiptBatchTitle), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await _pumpFor(tester, steps: 2);
    expect(find.text(l10n.inventoryReceiptReviewTitle), findsOneWidget);

    await tester.tap(find.text(l10n.inventoryReceiptReviewCancelAction));
    await _pumpFor(tester);
    expect(find.text(l10n.inventoryReceiptBatchTitle), findsOneWidget);

    await tester.tap(find.text(l10n.inventoryReceiptBatchCloseAction));
    await _pumpFor(tester);
    expect(find.text(l10n.inventoryReceiptBatchTitle), findsNothing);
  });

  testWidgets(
    'inventory upload keeps batch dialog when review is swiped down',
    (tester) async {
      final inputRepository = _FakeReceiptInputRepository(
        onPickFromFiles: () async => ReceiptInputBatchResult.selected(
          selections: <ReceiptInputSelection>[_receiptSelection(name: 'a.jpg')],
        ),
      );
      final analysisRepository = _FakeReceiptAnalysisRepository(
        onAnalyzeSelection: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return const ReceiptAnalysisResult.succeeded(
            rawResponse: '{"items":[{"name":"Milk"}]}',
            extraction: ReceiptAnalysisExtraction(
              root: <String, dynamic>{},
              items: <ReceiptAnalysisItem>[
                ReceiptAnalysisItem(
                  name: 'Milk',
                  rawPayload: <String, dynamic>{'n': 'Milk'},
                ),
              ],
            ),
          );
        },
      );
      final mapper = _FakeReceiptToFridgeItemMapper(
        onMap: (_) => <FridgeItem>[_mappedFridgeItem()],
      );
      final container = _createContainer(
        overrides: [
          receiptInputRepositoryProvider.overrideWithValue(inputRepository),
          receiptAnalysisRepositoryProvider.overrideWithValue(
            analysisRepository,
          ),
          receiptToFridgeItemMapperProvider.overrideWithValue(mapper),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpUi(tester);
      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.byType(FloatingActionButton));
      await _pumpUi(tester);
      await tester.tap(find.text('Upload receipt (image/PDF)'));
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpFor(tester, steps: 2);

      expect(find.text(l10n.inventoryReceiptReviewTitle), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.drag(find.byType(BottomSheet), const Offset(0, 500));
      await _pumpFor(tester);

      expect(find.text(l10n.inventoryReceiptReviewTitle), findsNothing);
      expect(find.text(l10n.inventoryReceiptBatchTitle), findsOneWidget);

      await tester.tap(find.text(l10n.inventoryReceiptBatchCloseAction));
      await _pumpFor(tester);
      expect(find.text(l10n.inventoryReceiptBatchTitle), findsNothing);
    },
  );
}
