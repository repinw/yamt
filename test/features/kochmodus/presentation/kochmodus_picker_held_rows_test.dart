import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_picker_offers.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_sheet_pump.dart';

KochmodusView _view(
  CookRun run,
  List<InventoryItem> items, {
  Map<String, int> others = const {},
}) => buildKochmodusView(
  run: run,
  saved: true,
  ended: false,
  busy: false,
  reopened: false,
  finished: null,
  tab: null,
  items: items,
  otherReservations: others,
  utensils: const [],
  parser: const TemplateIngredientParser(),
);

InventoryItem _food(String id, String name) =>
    stockItem(id, 500).copyWith(name: name);

void main() {
  Future<List<List<String>?>> open(
    WidgetTester tester,
    KochmodusView view, {
    Map<String, String> holders = const {},
  }) async {
    final results = <List<String>?>[];
    final line = view.lines.single;
    await pumpSheet<List<String>>(
      tester,
      (context) => KochmodusItemPickerSheet.show(
        context,
        title: line.line.text,
        need: line.need,
        offers: kochmodusPickerOffers(view, line.id, localeCode: 'de'),
        picked: const [],
        holders: holders,
      ).then((result) => result?.ids),
      results,
    );
    return results;
  }

  testWidgets('a food that another cooking holds all of says "verplant" for '
      'a line with a need', (tester) async {
    final view = _view(
      buildCookRun(lines: [textLine('a', '300 g Reis')]),
      [_food('i1', 'Reis')],
      others: const {'i1': 500},
    );

    await open(tester, view);

    final l10n = sheetL10n(tester);
    expect(find.text(l10n.kochmodusPickerHeld), findsOneWidget);
  });

  testWidgets('names the cooking that holds it when the run has a name', (
    tester,
  ) async {
    final view = _view(
      buildCookRun(lines: [textLine('a', '300 g Reis')]),
      [_food('i1', 'Reis')],
      others: const {'i1': 500},
    );

    await open(tester, view, holders: const {'i1': 'Pfannkuchen'});

    expect(
      find.text(sheetL10n(tester).kochmodusPickerHeldFor('Pfannkuchen')),
      findsOneWidget,
    );
    expect(find.text(sheetL10n(tester).kochmodusPickerHeld), findsNothing);
  });

  testWidgets('a line without a need does not say "verplant" while another '
      'cooking holds all of the item, and the cook can choose it', (
    tester,
  ) async {
    final view = _view(
      buildCookRun(lines: [textLine('a', 'Pfeffer')]),
      [_food('i1', 'Pfeffer')],
      others: const {'i1': 500},
    );

    final results = await open(tester, view);

    final l10n = sheetL10n(tester);
    expect(find.text(l10n.kochmodusPickerHeld), findsNothing);
    // The item covers a line without a need, so the picker closes with it.
    await tapKey(tester, KochmodusItemPickerSheet.rowKey('i1'));
    expect(results, [
      ['i1'],
    ]);
  });
}
