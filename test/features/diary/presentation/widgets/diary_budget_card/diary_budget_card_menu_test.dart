import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_menu.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_meal_shares_editor.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';
import '../../../../../helpers/system_back_test_utils.dart';

const _markerKey = 'diary_pace_marker_v1';
const _openKey = ValueKey<String>('open-menu');

/// A page with a button that opens the menu of a day with 2,000 kcal.
Future<MemoryAppPreferences> _pump(
  WidgetTester tester, {
  bool markerOn = false,
}) async {
  final preferences = MemoryAppPreferences(
    initialInts: {if (markerOn) _markerKey: 1},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                key: _openKey,
                onPressed: () =>
                    showDiaryBudgetCardMenu(context, targetKcal: 2000),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return preferences;
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
}

Future<void> _toggle(WidgetTester tester) async {
  await tester.tap(find.byKey(DiaryBudgetCardKeys.paceSwitch));
  await tester.pumpAndSettle();
}

bool _switchOn(WidgetTester tester) => tester
    .widget<AppSwitchListTile>(find.byKey(DiaryBudgetCardKeys.paceSwitch))
    .value;

final Finder _editor = find.byType(DiaryMealSharesEditor);

/// The words of the open menu, in the language it shows.
AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byKey(DiaryBudgetCardKeys.menu)))!;

/// The label above the parts of the day, which shows in capitals.
Finder _kicker(WidgetTester tester) =>
    find.text(_l10n(tester).diaryMealSharesTitle.toUpperCase());

void main() {
  testWidgets('opens with its heading and the pace marker switch, off', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(DiaryBudgetCardKeys.menu), findsNothing);

    await _open(tester);

    expect(find.byKey(DiaryBudgetCardKeys.menu), findsOneWidget);
    final l10n = _l10n(tester);
    expect(find.text(l10n.diaryBudgetMenuTitle), findsOneWidget);
    expect(find.text(l10n.diaryBudgetMenuPace), findsOneWidget);
    expect(find.text(l10n.diaryBudgetMenuPaceHint), findsOneWidget);
    expect(_switchOn(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with the marker off it offers no parts of the day', (
    tester,
  ) async {
    await _pump(tester);

    await _open(tester);

    expect(_editor, findsNothing);
    expect(_kicker(tester), findsNothing);
    expect(find.byKey(DiaryMealSharesEditor.blocksKey), findsNothing);
  });

  testWidgets('turning the marker on saves it and shows the parts of the day '
      "for the day's target", (tester) async {
    final preferences = await _pump(tester);
    await _open(tester);

    await _toggle(tester);

    expect(_switchOn(tester), isTrue);
    expect(preferences.getIntSync(_markerKey), 1);
    expect(_kicker(tester), findsOneWidget);
    expect(_editor, findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(DiaryMealSharesEditor.partKey(MealType.breakfast)),
          )
          .data,
      '25 % · 500 kcal',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('turning it off again hides the parts of the day and forgets '
      'the choice', (tester) async {
    final preferences = await _pump(tester);
    await _open(tester);
    await _toggle(tester);

    await _toggle(tester);

    expect(_switchOn(tester), isFalse);
    expect(preferences.getIntSync(_markerKey), isNull);
    expect(_editor, findsNothing);
    expect(_kicker(tester), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens with the parts of the day when the marker is on', (
    tester,
  ) async {
    await _pump(tester, markerOn: true);

    await _open(tester);

    expect(_switchOn(tester), isTrue);
    expect(_kicker(tester), findsOneWidget);
    expect(_editor, findsOneWidget);
  });

  testWidgets('keeps the choice when the sheet is closed and opened again', (
    tester,
  ) async {
    await _pump(tester);
    await _open(tester);
    await _toggle(tester);

    await pressSystemBack(tester);
    expect(find.byKey(DiaryBudgetCardKeys.menu), findsNothing);

    await _open(tester);
    expect(_switchOn(tester), isTrue);
    expect(_editor, findsOneWidget);

    await _toggle(tester);
    await pressSystemBack(tester);
    await _open(tester);

    expect(_switchOn(tester), isFalse);
    expect(_editor, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes with the parts of the day open without an error', (
    tester,
  ) async {
    await _pump(tester, markerOn: true);
    await _open(tester);

    await pressSystemBack(tester);

    expect(find.byKey(DiaryBudgetCardKeys.menu), findsNothing);
    expect(_editor, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
