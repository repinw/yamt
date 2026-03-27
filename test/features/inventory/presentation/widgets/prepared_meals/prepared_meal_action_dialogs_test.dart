import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_action_dialogs.dart';
import 'package:yamt/l10n/app_localizations.dart';

PreparedMeal _meal() {
  final sourceItem = InventoryItem.create(
    id: 'item-1',
    name: 'Rice',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: 200,
    currentAmount: 200,
    amountUnit: InventoryAmountUnit.gram,
  );

  return PreparedMeal(
    id: 'meal-1',
    name: 'Rice bowl',
    totalPortions: 3,
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

class _ActionDialogsHarness extends StatefulWidget {
  const _ActionDialogsHarness({required this.meal});

  final PreparedMeal meal;

  @override
  State<_ActionDialogsHarness> createState() => _ActionDialogsHarnessState();
}

class _ActionDialogsHarnessState extends State<_ActionDialogsHarness> {
  String? _resultLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final result = await showPreparedMealEatDialog(
                context,
                widget.meal,
              );
              if (!mounted || result == null) {
                return;
              }
              setState(() {
                _resultLabel = 'eat:${result.portions}:${result.mealType.name}';
              });
            },
            child: const Text('Open eat'),
          ),
          TextButton(
            onPressed: () async {
              final result = await showPreparedMealPortionDialog(
                context: context,
                meal: widget.meal,
                title: 'Throw away portions',
              );
              if (!mounted || result == null) {
                return;
              }
              setState(() {
                _resultLabel = 'portions:$result';
              });
            },
            child: const Text('Open portions'),
          ),
          if (_resultLabel != null) Text(_resultLabel!),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('eat dialog shows snackbar for invalid portions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: _meal()),
      ),
    );

    await tester.tap(find.text('Open eat'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '99');
    await tester.tap(find.text('Eat'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Please enter a valid portion count within the available range.',
      ),
      findsOneWidget,
    );
    expect(find.text('Eat prepared meal'), findsOneWidget);
  });

  testWidgets('portion dialog returns selected amount on confirm', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: _meal()),
      ),
    );

    await tester.tap(find.text('Open portions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('portions:1'), findsOneWidget);
  });
}
