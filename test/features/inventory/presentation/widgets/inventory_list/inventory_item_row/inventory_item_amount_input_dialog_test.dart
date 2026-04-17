import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_amount_input_dialog.dart';

class _AmountDialogHarness extends StatelessWidget {
  const _AmountDialogHarness({required this.onResult});

  final ValueChanged<int?> onResult;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return const InventoryItemAmountInputDialog(
                          title: 'Choose amount',
                          confirmLabel: 'Confirm',
                          cancelLabel: 'Cancel',
                          fieldLabel: 'Amount',
                          invalidAmountMessage: 'Invalid amount',
                          maxAmount: 5,
                          quickFillLabel: 'All',
                          suffixText: 'pcs',
                        );
                      },
                    );
                    onResult(result);
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }
}

void main() {
  testWidgets('dialog validates invalid submitted values', (tester) async {
    int? result;
    await tester.pumpWidget(
      _AmountDialogHarness(
        onResult: (value) {
          result = value;
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('inventory_item_amount_dialog_field'));
    final confirmButton = find.byKey(
      const Key('inventory_item_amount_dialog_confirm_button'),
    );

    await tester.enterText(field, 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Invalid amount'), findsOneWidget);
    expect(result, isNull);

    await tester.enterText(field, '0');
    await tester.tap(confirmButton);
    await tester.pump();
    expect(find.text('Invalid amount'), findsOneWidget);
    expect(result, isNull);

    await tester.enterText(field, '6');
    await tester.tap(confirmButton);
    await tester.pump();
    expect(find.text('Invalid amount'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('dialog returns parsed amount on keyboard submit', (
    tester,
  ) async {
    int? result;
    await tester.pumpWidget(
      _AmountDialogHarness(
        onResult: (value) {
          result = value;
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '2',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(result, 2);
  });
}
