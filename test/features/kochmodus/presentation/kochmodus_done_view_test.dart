import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_done_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../support/prepared_meal_test_data.dart';
import '../../recipes/cook_run_fixtures.dart';

PreparedMeal _meal({
  String name = 'Eintopf',
  int portions = 4,
  bool? inPieces,
  double kcal = 800,
}) => preparedMealTestData(name: name, totalPortions: portions).copyWith(
  totalKcal: kcal,
  totalProtein: 40,
  totalCarbs: 80,
  totalFat: 20,
  servedInPieces: inPieces,
);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  List<PreparedMeal> meals, {
  bool inCans = false,
}) async {
  final finished = (meals: meals, inCans: inCans, inCookbook: false);
  final view = buildKochmodusView(
    run: buildCookRun(),
    saved: false,
    ended: true,
    busy: false,
    reopened: false,
    finished: finished,
    tab: null,
    items: const [],
    otherReservations: const {},
    utensils: const [],
    parser: const TemplateIngredientParser(),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: KochmodusDoneView(
            target: const KochmodusTarget.run('r'),
            view: view,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return AppLocalizations.of(tester.element(find.byType(KochmodusDoneView)))!;
}

void main() {
  testWidgets('names the kcal of one portion and the three macros', (
    tester,
  ) async {
    final l10n = await _pump(tester, [_meal()]);

    // 800 kcal in 4 portions.
    expect(find.text(l10n.kochmodusDoneKcalPerPortion(200)), findsOneWidget);
    expect(find.byType(MacroGrams), findsOneWidget);
    expect(find.text('10 g'), findsOneWidget);
    expect(find.text('20 g'), findsOneWidget);
    expect(find.text('5 g'), findsOneWidget);
  });

  testWidgets('names the kcal of one piece for a meal served in pieces', (
    tester,
  ) async {
    final l10n = await _pump(tester, [
      _meal(name: 'Kekse', portions: 8, inPieces: true),
    ]);

    expect(find.text(l10n.kochmodusDoneKcalPerPiece(100)), findsOneWidget);
    expect(find.text(l10n.kochmodusDoneKcalPerPortion(100)), findsNothing);
  });

  testWidgets('names the kcal of one container for meals in cans', (
    tester,
  ) async {
    final l10n = await _pump(tester, [_meal()], inCans: true);

    expect(find.text(l10n.kochmodusDoneKcalPerCan(200)), findsOneWidget);
    expect(find.text(l10n.kochmodusDoneKcalPerPortion(200)), findsNothing);
  });

  testWidgets('shows each meal with its own line and columns', (tester) async {
    final l10n = await _pump(tester, [
      _meal(),
      _meal(name: 'Kekse', portions: 8, inPieces: true, kcal: 400),
    ]);

    expect(find.text(l10n.kochmodusDoneKcalPerPortion(200)), findsOneWidget);
    expect(find.text(l10n.kochmodusDoneKcalPerPiece(50)), findsOneWidget);
    expect(find.byType(MacroGrams), findsNWidgets(2));
  });

  testWidgets('a meal without kcal shows only its sentence', (tester) async {
    final l10n = await _pump(tester, [_meal(kcal: 0)]);

    expect(find.text(l10n.kochmodusDonePortions(4, 'Eintopf')), findsOneWidget);
    expect(find.byType(MacroGrams), findsNothing);
    expect(find.textContaining('kcal'), findsNothing);
  });
}
