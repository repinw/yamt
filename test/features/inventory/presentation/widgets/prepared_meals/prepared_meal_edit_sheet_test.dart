import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/fake_local_image_store.dart';

PreparedMeal _meal() {
  final sourceItem = InventoryItem.create(
    id: 'item-1',
    name: 'Rice',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 200,
    currentAmount: 200,
    amountUnit: InventoryAmountUnit.gram,
  );

  return PreparedMeal(
    id: 'meal-1',
    name: 'Rice bowl',
    imageAssetId: 'asset-meal-1',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 8,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: [
      PreparedMealComponent(
        inventoryItemId: sourceItem.id,
        name: sourceItem.name,
        brand: sourceItem.brand,
        imageUrl: sourceItem.imageUrl,
        usedAmount: 100,
        usedUnit: InventoryAmountUnit.gram,
        totalKcal: 400,
        totalProtein: 20,
        totalCarbs: 40,
        totalFat: 8,
        sourceItemSnapshot: sourceItem,
      ),
    ],
  );
}

class _FakePreparedMealImagePicker implements PreparedMealImagePicker {
  @override
  Future<Uint8List?> pickFromCamera() async => null;

  @override
  Future<Uint8List?> pickFromFile() async => null;

  @override
  bool get supportsCamera => false;
}

class _EditSheetHarness extends StatefulWidget {
  const _EditSheetHarness({required this.meal});

  final PreparedMeal meal;

  @override
  State<_EditSheetHarness> createState() => _EditSheetHarnessState();
}

class _EditSheetHarnessState extends State<_EditSheetHarness> {
  String? _resultLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final result = await showPreparedMealEditSheet(
                context: context,
                meal: widget.meal,
              );
              if (!mounted || result == null) {
                return;
              }
              setState(() {
                _resultLabel =
                    'edited:${result.name}:${result.imageChanged}:'
                    '${result.imageBytes != null}';
              });
            },
            child: const Text('Open'),
          ),
          if (_resultLabel != null) Text(_resultLabel!),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('returns updated name on happy path submit', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealImagePickerProvider.overrideWithValue(
            _FakePreparedMealImagePicker(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _EditSheetHarness(meal: _meal()),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Updated bowl',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('edited:Updated bowl:false:false'), findsOneWidget);
  });

  testWidgets('can remove image and returns changed state', (tester) async {
    final localImageStore = FakeLocalImageStore();
    await localImageStore.saveBytes(
      imageRef: localImageAssetRef('asset-meal-1'),
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localImageStoreProvider.overrideWithValue(localImageStore),
          preparedMealImagePickerProvider.overrideWithValue(
            _FakePreparedMealImagePicker(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _EditSheetHarness(meal: _meal()),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove image'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('edited:Rice bowl:true:false'), findsOneWidget);
  });
}
