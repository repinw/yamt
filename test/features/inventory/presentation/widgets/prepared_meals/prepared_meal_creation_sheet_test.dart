import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_creation_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _item({
  required String id,
  required String name,
  int currentAmount = 120,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: currentAmount,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 200,
      per100Protein: 10,
      per100Carbs: 20,
      per100Fat: 5,
    ),
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

class _CreationSheetHarness extends StatefulWidget {
  const _CreationSheetHarness({required this.items});

  final List<InventoryItem> items;

  @override
  State<_CreationSheetHarness> createState() => _CreationSheetHarnessState();
}

class _CreationSheetHarnessState extends State<_CreationSheetHarness> {
  String? _resultLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final result = await showPreparedMealCreationSheet(
                context: context,
                items: widget.items,
              );
              if (!mounted || result == null) {
                return;
              }
              setState(() {
                _resultLabel =
                    'created:${result.name}:${result.totalPortions}:'
                    '${result.items.length}';
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
  testWidgets('shows snackbar when submit contains invalid fields', (
    tester,
  ) async {
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
          home: _CreationSheetHarness(
            items: <InventoryItem>[_item(id: 'rice', name: 'Rice')],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Meal name'), '');
    final createButton = find.widgetWithText(FilledButton, 'Create meal');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a meal name.'), findsOneWidget);
    expect(find.text('Please check the highlighted fields.'), findsOneWidget);
    expect(find.textContaining('created:'), findsNothing);
  });

  testWidgets('returns meal result on happy path submit', (tester) async {
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
          home: _CreationSheetHarness(
            items: <InventoryItem>[
              _item(id: 'rice', name: 'Rice'),
              _item(id: 'beans', name: 'Beans'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Lunch Box',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Portions'), '3');
    final createButton = find.widgetWithText(FilledButton, 'Create meal');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('created:Lunch Box:3:2'), findsOneWidget);
  });
}
