import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_actions.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_detail_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_weight_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/fake_prepared_meal_repository.dart';
import '../../../../../support/prepared_meal_test_data.dart';

/// The household's meals, delivered later like the Firestore stream.
class _LiveMeals extends FakePreparedMealRepository {
  new(PreparedMeal meal) : super(meals: [meal]);

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    await Future<void>.delayed(Duration.zero);
    yield meals;
  }
}

/// The detail actions. A new weight goes into [weights] and saves when
/// [weightSaves].
PreparedMealActions _actions(
  List<(String, int)> weights, {
  bool weightSaves = true,
}) {
  return PreparedMealActions(
    throwAway: (_, _, _) async => true,
    fillPendingIngredient: (_, _, _) async => true,
    fillPendingIngredientWithItem: (_, _, _, _) async => true,
    ignorePendingIngredient: (_, _) async => true,
    unignorePendingIngredient: (_, _) async => true,
    unassign: (_, _) async => true,
    unbundle: (_) async => true,
    changeWeight: (meal, grams) async {
      weights.add((meal.id, grams));
      return weightSaves;
    },
    edit: (_, _, _) async => true,
    saveTemplate: (_, _) async => true,
  );
}

Future<void> _pump(
  WidgetTester tester,
  PreparedMeal meal,
  PreparedMealActions actions,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preparedMealRepositoryProvider.overrideWithValue(_LiveMeals(meal)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [EatMealDetailSections(meal: meal, actions: actions)],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 3 portions, 2 left, cooked at 900 g.
PreparedMeal _cooked() => preparedMealTestData().copyWith(finalNetWeight: 900);

Future<void> _changeWeight(WidgetTester tester, String text) async {
  await tester.tap(find.byKey(EatMealActionsCard.weightKey));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(PreparedMealWeightDialog.fieldKey), text);
  await tester.pump();
  await tester.tap(find.byKey(PreparedMealWeightDialog.saveKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"Change weight" saves the weighed grams of the meal', (
    tester,
  ) async {
    final weights = <(String, int)>[];
    await _pump(tester, _cooked(), _actions(weights));

    expect(find.text('Change weight'), findsOneWidget);
    await _changeWeight(tester, '480');

    expect(weights, [('meal-1', 480)]);
    expect(find.byType(PreparedMealWeightDialog), findsNothing);
    expect(find.text('The weight could not be saved.'), findsNothing);
  });

  testWidgets('a failed weight says so', (tester) async {
    final weights = <(String, int)>[];
    await _pump(tester, _cooked(), _actions(weights, weightSaves: false));

    await _changeWeight(tester, '480');

    expect(weights, [('meal-1', 480)]);
    expect(find.text('The weight could not be saved.'), findsOneWidget);
  });

  testWidgets('pieces and a meal in the pot have no weight to change', (
    tester,
  ) async {
    for (final meal in [
      _cooked().copyWith(servedInPieces: true),
      _cooked().copyWith(inPot: true),
    ]) {
      await _pump(tester, meal, _actions(<(String, int)>[]));

      expect(find.byKey(EatMealActionsCard.weightKey), findsNothing);
      expect(find.byKey(const Key('eat_meal_action_edit')), findsOneWidget);
    }
  });
}
