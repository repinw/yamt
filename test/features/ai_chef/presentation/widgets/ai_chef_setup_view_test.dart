import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_must_use_chips.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_pill_row.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_setup_view.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

const String _wish = AiChefSetupView.wishKeys;
const String _never = AiChefSetupView.exclusionKeys;

class _Calls {
  bool? includeInventory;
  final List<String> wishes = [];
  final List<String> removedWishes = [];
  final List<String> added = [];
  final List<String> removed = [];
  final List<String> removedMustUse = [];
  int picks = 0;
  int generated = 0;
  int retried = 0;
}

InventoryItem _item(String id, String name) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: DateTime.utc(2026, 11),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 200,
  currentAmount: 200,
  amountUnit: InventoryAmountUnit.gram,
);

Future<_Calls> _pump(
  WidgetTester tester, {
  List<String>? excludedIngredients = const [],
  bool includeInventory = true,
  List<InventoryItem> mustUseItems = const [],
  List<String> wishes = const [],
  String? exclusionsError,
  String? mustUseError,
  bool canRetry = false,
}) async {
  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AiChefSetupView(
          includeInventory: includeInventory,
          onIncludeInventoryChanged: (value) => calls.includeInventory = value,
          mustUseItems: mustUseItems,
          onPickMustUse: () => calls.picks++,
          onRemoveMustUse: calls.removedMustUse.add,
          wishes: wishes,
          onAddWish: calls.wishes.add,
          onRemoveWish: calls.removedWishes.add,
          mustUseError: mustUseError,
          excludedIngredients: excludedIngredients,
          exclusionsError: exclusionsError,
          onAddExclusion: calls.added.add,
          onRemoveExclusion: calls.removed.add,
          onRetryExclusions: canRetry ? () => calls.retried++ : null,
          onGenerate: () => calls.generated++,
        ),
      ),
    ),
  );
  return calls;
}

void main() {
  testWidgets('shows the rows without a title', (tester) async {
    await _pump(tester, excludedIngredients: const ['Koriander']);

    expect(find.text('Vorrat zuerst'), findsOneWidget);
    expect(find.text('Rezept vorschlagen'), findsOneWidget);
    expect(find.text('Worauf hast du Lust?'), findsNothing);
    expect(find.text('Schließen'), findsNothing);
    expect(find.text('Wünsche'), findsOneWidget);
    expect(find.text('Bloß nicht'), findsOneWidget);
    expect(
      find.byKey(AiChefPillRow.chipKey(_never, 'Koriander')),
      findsOneWidget,
    );
    expect(find.text('Was soll die KI kochen?'), findsNothing);
  });

  testWidgets('forwards inventory and generate', (tester) async {
    final calls = await _pump(tester);

    await tester.tap(find.byKey(AiChefSetupView.inventoryKey));
    await tester.tap(find.byKey(AiChefSetupView.generateKey));

    expect(calls.includeInventory, isFalse);
    expect(calls.generated, 1);
  });

  testWidgets('adds a wish as a pill and removes one', (tester) async {
    final calls = await _pump(tester, wishes: const ['schnell']);

    await tester.tap(find.byKey(AiChefPillRow.addKey(_wish)));
    await tester.pump();
    await tester.enterText(find.byKey(AiChefPillRow.inputKey(_wish)), 'Lachs');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byTooltip('schnell entfernen'));

    expect(calls.wishes, ['Lachs']);
    expect(calls.removedWishes, ['schnell']);
  });

  testWidgets('adds a Bloß nicht entry and removes a pill', (tester) async {
    final calls = await _pump(tester, excludedIngredients: const ['Rosinen']);

    await tester.tap(find.byKey(AiChefPillRow.addKey(_never)));
    await tester.pump();
    await tester.enterText(
      find.byKey(AiChefPillRow.inputKey(_never)),
      'Koriander',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byTooltip('Rosinen entfernen'));

    expect(calls.added, ['Koriander']);
    expect(calls.removed, ['Rosinen']);
  });

  testWidgets('shows Unbedingt rein picks only with the Vorrat', (
    tester,
  ) async {
    final spinach = _item('spinach', 'Spinat');
    final calls = await _pump(tester, mustUseItems: [spinach]);

    await tester.tap(find.byKey(AiChefMustUseChips.pickKey));
    await tester.tap(find.byTooltip('Spinat entfernen'));

    expect(calls.picks, 1);
    expect(calls.removedMustUse, ['spinach']);

    await _pump(tester, includeInventory: false, mustUseItems: [spinach]);

    expect(find.byKey(AiChefMustUseChips.pickKey), findsNothing);
    expect(find.byKey(AiChefMustUseChips.chipKey('spinach')), findsNothing);
  });

  testWidgets('waits for the stored list before it suggests', (tester) async {
    final calls = await _pump(tester, excludedIngredients: null);

    await tester.tap(find.byKey(AiChefSetupView.generateKey));
    await tester.tap(find.byKey(AiChefPillRow.addKey(_never)));
    await tester.pump();

    expect(calls.generated, 0);
    expect(find.byKey(AiChefPillRow.inputKey(_never)), findsNothing);
  });

  testWidgets('shows a failed list with a retry', (tester) async {
    final calls = await _pump(
      tester,
      excludedIngredients: null,
      exclusionsError: 'Wir konnten deine Liste nicht laden.',
      canRetry: true,
    );

    expect(find.text('Wir konnten deine Liste nicht laden.'), findsOneWidget);
    await tester.tap(find.byKey(AiChefPillRow.retryKey(_never)));

    expect(calls.retried, 1);
  });

  testWidgets('shows a failed save without a retry', (tester) async {
    await _pump(
      tester,
      excludedIngredients: const ['Koriander'],
      exclusionsError: 'Wir konnten deine Liste nicht speichern.',
    );

    expect(
      find.text('Wir konnten deine Liste nicht speichern.'),
      findsOneWidget,
    );
    expect(find.byKey(AiChefPillRow.retryKey(_never)), findsNothing);
  });

  testWidgets('shows a Vorrat that did not load under the picks', (
    tester,
  ) async {
    await _pump(tester, mustUseError: 'Wir konnten deinen Vorrat nicht laden.');

    expect(find.text('Wir konnten deinen Vorrat nicht laden.'), findsOneWidget);
  });

  testWidgets('leaving the input keeps what was typed', (tester) async {
    final calls = await _pump(tester);

    await tester.tap(find.byKey(AiChefPillRow.addKey(_never)));
    await tester.pump();
    await tester.enterText(find.byKey(AiChefPillRow.inputKey(_never)), 'Pilze');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(calls.added, ['Pilze']);
    expect(find.byKey(AiChefPillRow.inputKey(_never)), findsNothing);
  });
}
