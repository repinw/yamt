// The menu of the week card (#911): K1, K2 and K3 of
// lib/features/diary/CRITERIA.md.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/week_balance_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

final DateTime _monday = DateTime(2026, 11, 16);

FakeCalorieSettingsRepository _repository({double goal = 2200}) {
  final repository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: goal,
      calculatorProfile: null,
      effectiveDate: _monday,
    ),
  );
  addTearDown(repository.dispose);
  return repository;
}

Future<void> _pump(
  WidgetTester tester,
  CalorieSettingsRepository repository, {
  required Widget child,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 19, 10)),
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _option(WeekBalanceMode mode) =>
    find.byKey(WeekBalanceModeKeys.option(mode));

void main() {
  group('the menu of the week card', () {
    Widget opener() => Builder(
      builder: (context) => TextButton(
        onPressed: () => unawaited(showWeekBalanceMenu(context)),
        child: const Text('open'),
      ),
    );

    testWidgets('K1/K2: heading, the choice and where to change it later', (
      tester,
    ) async {
      await _pump(tester, _repository(), child: opener());

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final menu = find.byKey(WeekBalanceModeKeys.menu);
      expect(menu, findsOneWidget);
      expect(
        find.descendant(of: menu, matching: find.text('Wochenzielbalance')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: menu,
          matching: find.text('Später ändern: in den Einstellungen.'),
        ),
        findsOneWidget,
      );
      for (final mode in WeekBalanceMode.values) {
        expect(
          find.descendant(of: menu, matching: _option(mode)),
          findsOneWidget,
        );
      }
      // No separate switch for "Übertrag" or "anzeigen" (K2).
      expect(
        find.descendant(of: menu, matching: find.byType(Switch)),
        findsNothing,
      );
    });

    testWidgets('K3: a pick closes the menu', (tester) async {
      final repository = _repository();
      await _pump(tester, repository, child: opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(_option(WeekBalanceMode.off));
      await tester.pumpAndSettle();

      expect(find.byKey(WeekBalanceModeKeys.menu), findsNothing);
      expect(
        (await repository.readSettings()).weekBalanceMode,
        WeekBalanceMode.off,
      );
    });
  });
}
