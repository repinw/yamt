import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_exclusions_repository.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_must_use_chips.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_must_use_sheet.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_pill_row.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_setup_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_sheet.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/fake_ai_chef.dart';
import '../../../../helpers/fake_ai_chef_exclusions_repository.dart';
import '../../../../helpers/fake_inventory_item_repository.dart';

const _openKey = ValueKey<String>('open-sheet');

Future<void> _pump(
  WidgetTester tester,
  FakeAiChef chef,
  void Function(AiChefRecipeIdea?) onResult, {
  FakeInventoryItemRepository? inventory,
  FakeAiChefExclusionsRepository? exclusions,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiChefRepositoryProvider.overrideWithValue(chef.repository),
        aiChefExclusionsRepositoryProvider.overrideWithValue(
          exclusions ?? FakeAiChefExclusionsRepository(),
        ),
        aiChefImageGeneratorProvider.overrideWithValue(chef.imageGenerator),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 13)),
        inventoryItemRepositoryProvider.overrideWithValue(
          inventory ?? FakeInventoryItemRepository(const []),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              key: _openKey,
              onPressed: () async => onResult(await AiChefSheet.show(context)),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
}

Future<void> _generate(WidgetTester tester) async {
  await tester.tap(find.byKey(AiChefSetupView.generateKey));
  await tester.pump();
}

void main() {
  testWidgets('shows the setup first', (tester) async {
    await _pump(tester, FakeAiChef(), (_) {});

    expect(find.byKey(AiChefSetupView.inventoryKey), findsOneWidget);
    expect(find.byKey(AiChefSetupView.generateKey), findsOneWidget);
    expect(find.text('Worauf hast du Lust?'), findsNothing);
  });

  testWidgets('shows the loading view while the idea comes', (tester) async {
    final chef = FakeAiChef();
    await _pump(tester, chef, (_) {});

    await _generate(tester);

    expect(find.text('Wir stellen ein Rezept zusammen …'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(AiChefSetupView.generateKey), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('pops with the idea as soon as its text is there', (
    tester,
  ) async {
    final chef = FakeAiChef();
    AiChefRecipeIdea? result;
    var closed = false;
    await _pump(tester, chef, (idea) {
      closed = true;
      result = idea;
    });

    await _generate(tester);
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result!.recipe.name, 'Tomatenpasta');
    expect(result!.imagePrompt, 'a plate of pasta');
    expect(chef.pictureCalls, 0);
    expect(find.byType(AiChefSheet), findsNothing);
  });

  testWidgets('a failed idea shows the message and retry', (tester) async {
    final chef = FakeAiChef()..templateFails = true;
    var closed = false;
    await _pump(tester, chef, (_) => closed = true);

    await _generate(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Wir konnten gerade kein Rezept zusammenstellen.'),
      findsOneWidget,
    );
    expect(find.byKey(AiChefSheet.retryKey), findsOneWidget);
    expect(closed, isFalse);
  });

  testWidgets('retry asks again and pops with the idea', (tester) async {
    final chef = FakeAiChef()..templateFails = true;
    AiChefRecipeIdea? result;
    await _pump(tester, chef, (idea) => result = idea);
    await _generate(tester);
    await tester.pumpAndSettle();

    chef.templateFails = false;
    await tester.tap(find.byKey(AiChefSheet.retryKey));
    await tester.pumpAndSettle();

    expect(chef.templateCalls, 2);
    expect(result!.recipe.name, 'Tomatenpasta');
  });

  testWidgets('an unusable answer shows the failure too', (tester) async {
    final chef = FakeAiChef(answer: '{"name": "x"}');
    await _pump(tester, chef, (_) {});

    await _generate(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(AiChefSheet.retryKey), findsOneWidget);
  });

  testWidgets('closing the sheet gives null', (tester) async {
    var closed = false;
    AiChefRecipeIdea? result;
    await _pump(tester, FakeAiChef(), (idea) {
      closed = true;
      result = idea;
    });

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  group('Unbedingt rein, wishes and Bloß nicht', () {
    Future<void> pick(WidgetTester tester, List<String> ids) async {
      await tester.tap(find.byKey(AiChefMustUseChips.pickKey));
      await tester.pumpAndSettle();
      for (final id in ids) {
        await tester.tap(find.byKey(AiChefMustUseSheet.rowKey(id)));
        await tester.pump();
      }
      await tester.tap(find.byKey(AiChefMustUseSheet.applyKey));
      await tester.pumpAndSettle();
    }

    Future<void> add(WidgetTester tester, String prefix, String text) async {
      await tester.tap(find.byKey(AiChefPillRow.addKey(prefix)));
      await tester.pump();
      await tester.enterText(find.byKey(AiChefPillRow.inputKey(prefix)), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    testWidgets('the picks, wishes and the stored list go with the request', (
      tester,
    ) async {
      final chef = FakeAiChef();
      final exclusions = FakeAiChefExclusionsRepository(const ['Rosinen']);
      await _pump(
        tester,
        chef,
        (_) {},
        inventory: FakeInventoryItemRepository([
          _stock('spinach', 'Spinat'),
          _stock('quark', 'Quark'),
        ]),
        exclusions: exclusions,
      );

      await pick(tester, ['spinach']);
      expect(find.byKey(AiChefMustUseChips.chipKey('spinach')), findsOneWidget);
      await add(tester, AiChefSetupView.wishKeys, 'Lachs');
      await add(tester, AiChefSetupView.exclusionKeys, 'Koriander');
      await _generate(tester);
      await tester.pumpAndSettle();

      final inputs = chef.lastInputs!;
      expect(inputs['must_use_ingredients'], 'Spinat (available: 200 g)');
      expect(inputs['excluded_ingredients'], 'Rosinen\nKoriander');
      expect(inputs['seed'], contains('Wünsche: Lachs'));
      expect(exclusions.stored.ingredients, ['Rosinen', 'Koriander']);
    });

    testWidgets('no pick goes out with the Vorrat switched off', (
      tester,
    ) async {
      final chef = FakeAiChef();
      await _pump(
        tester,
        chef,
        (_) {},
        inventory: FakeInventoryItemRepository([_stock('spinach', 'Spinat')]),
      );

      await pick(tester, ['spinach']);
      await tester.tap(find.byKey(AiChefSetupView.inventoryKey));
      await tester.pump();
      expect(find.byKey(AiChefMustUseChips.pickKey), findsNothing);
      await _generate(tester);
      await tester.pumpAndSettle();

      expect(chef.lastInputs!.containsKey('must_use_ingredients'), isFalse);
    });

    testWidgets('a pick eaten since then is left out', (tester) async {
      final chef = FakeAiChef();
      final inventory = FakeInventoryItemRepository([
        _stock('spinach', 'Spinat'),
        _stock('quark', 'Quark'),
      ]);
      await _pump(tester, chef, (_) {}, inventory: inventory);

      await pick(tester, ['spinach', 'quark']);
      inventory.items = [_stock('quark', 'Quark', grams: 150)];
      await _generate(tester);
      await tester.pumpAndSettle();

      expect(
        chef.lastInputs!['must_use_ingredients'],
        'Quark (available: 150 g)',
      );
    });

    testWidgets('an entry typed but not added goes with a direct tap', (
      tester,
    ) async {
      final chef = FakeAiChef();
      await _pump(tester, chef, (_) {});
      const never = AiChefSetupView.exclusionKeys;

      await tester.tap(find.byKey(AiChefPillRow.addKey(never)));
      await tester.pump();
      await tester.enterText(
        find.byKey(AiChefPillRow.inputKey(never)),
        'Pilze',
      );
      await _generate(tester);
      await tester.pumpAndSettle();

      expect(chef.lastInputs!['excluded_ingredients'], 'Pilze');
    });

    testWidgets('a failed save stops the request and says so', (tester) async {
      final chef = FakeAiChef();
      final exclusions = FakeAiChefExclusionsRepository()..saveFails = true;
      await _pump(tester, chef, (_) {}, exclusions: exclusions);
      const never = AiChefSetupView.exclusionKeys;

      await tester.tap(find.byKey(AiChefPillRow.addKey(never)));
      await tester.pump();
      await tester.enterText(
        find.byKey(AiChefPillRow.inputKey(never)),
        'Pilze',
      );
      await _generate(tester);
      await tester.pumpAndSettle();

      expect(chef.templateCalls, 0);
      expect(
        find.text('Wir konnten deine Liste nicht speichern.'),
        findsOneWidget,
      );

      // The cook saw it; the next tap goes on without the entry.
      await _generate(tester);
      await tester.pumpAndSettle();
      expect(chef.templateCalls, 1);
    });

    testWidgets('a double tap asks once', (tester) async {
      final chef = FakeAiChef();
      await _pump(tester, chef, (_) {});

      await tester.tap(find.byKey(AiChefSetupView.generateKey));
      await tester.tap(find.byKey(AiChefSetupView.generateKey));
      await tester.pumpAndSettle();

      expect(chef.templateCalls, 1);
    });

    testWidgets('retry sends the stored list again', (tester) async {
      final chef = FakeAiChef()..templateFails = true;
      await _pump(
        tester,
        chef,
        (_) {},
        exclusions: FakeAiChefExclusionsRepository(const ['Koriander']),
      );
      await _generate(tester);
      await tester.pumpAndSettle();

      chef
        ..templateFails = false
        ..lastInputs = null;
      await tester.tap(find.byKey(AiChefSheet.retryKey));
      await tester.pumpAndSettle();

      expect(chef.lastInputs!['excluded_ingredients'], 'Koriander');
    });

    testWidgets('a Vorrat that does not load says so in the sheet', (
      tester,
    ) async {
      await _pump(tester, FakeAiChef(), (_) {}, inventory: _BrokenInventory());

      await tester.tap(find.byKey(AiChefMustUseChips.pickKey));
      await tester.pumpAndSettle();

      expect(
        find.text('Wir konnten deinen Vorrat nicht laden.'),
        findsOneWidget,
      );
      expect(find.byKey(AiChefMustUseSheet.applyKey), findsNothing);
    });
  });
}

class _BrokenInventory extends FakeInventoryItemRepository {
  new() : super(const []);

  @override
  Future<List<InventoryItem>> readAll() async => throw StateError('offline');
}

InventoryItem _stock(String id, String name, {int grams = 200}) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 11, 3),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 200,
      currentAmount: grams,
      amountUnit: InventoryAmountUnit.gram,
    );
