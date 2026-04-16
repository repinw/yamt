import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_meta.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_balance_summary_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  final numberFormat = NumberFormat.decimalPattern('en');

  testWidgets('balance summary hero shows localized error fallback', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        calorieBalanceSummaryProvider.overrideWith(
          (ref) async => throw StateError('boom'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _buildHarness(
          child: BalanceSummaryHeroContent(
            numberFormat: numberFormat,
            kcalUnit: 'kcal',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Balance view is unavailable right now.'),
      findsOneWidget,
    );
  });

  testWidgets('classic meta toggles show bootstrap workout hint text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: ClassicSummaryMetaToggles(
          data: _balanceData(activityDeltaKcal: 140),
          numberFormat: numberFormat,
          kcalUnit: 'kcal',
          includeActivityDelta: true,
          includeCarryover: false,
          onToggleActivityDelta: (_) {},
          onToggleCarryover: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Workout bonus: +140 kcal'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.summaryActivityHint), findsOneWidget);
    expect(
      find.text('We are still learning your activity pattern.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'classic meta toggles can render carryover without activity row',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(
          child: ClassicSummaryMetaToggles(
            data: _balanceData(carryoverKcal: 180),
            numberFormat: numberFormat,
            kcalUnit: 'kcal',
            includeActivityDelta: true,
            includeCarryover: true,
            onToggleActivityDelta: (_) {},
            onToggleCarryover: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle),
        findsNothing,
      );
      expect(
        find.byKey(CaloriesPageKeys.summaryCarryoverToggle),
        findsOneWidget,
      );
      expect(find.text('Carryover: +180 kcal'), findsOneWidget);
    },
  );

  testWidgets('summary meta toggle row toggles when row text is tapped', (
    tester,
  ) async {
    var value = false;

    await tester.pumpWidget(
      _buildHarness(
        child: StatefulBuilder(
          builder: (context, setState) {
            return SummaryMetaToggleRow(
              value: value,
              onChanged: (nextValue) {
                setState(() {
                  value = nextValue;
                });
              },
              label: 'Workout bonus: +140 kcal',
              supportingText: 'Learning hint',
              toggleKey: CaloriesPageKeys.summaryActivityDeltaToggle,
              textKey: CaloriesPageKeys.summaryActivityDeltaNote,
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(CaloriesPageKeys.summaryActivityDeltaNote));
    await tester.pump();

    final checkbox = tester.widget<Checkbox>(
      find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle),
    );
    expect(value, isTrue);
    expect(checkbox.value, isTrue);
    expect(find.text('Learning hint'), findsOneWidget);
  });
}

Widget _buildHarness({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

CalorieBalanceSummaryData _balanceData({
  double activityDeltaKcal = 0,
  double carryoverKcal = 0,
  bool usedLearnedTdee = false,
}) {
  final now = DateTime(2026, 4, 10, 14);
  return CalorieBalanceSummaryData(
    selectedDay: DateTime(2026, 4, 10),
    referenceNow: now,
    windowStartDate: now.subtract(const Duration(days: 6)),
    balanceStartDate: now.subtract(const Duration(days: 6)),
    paceWindowStart: DateTime(2026, 4, 10, 6),
    paceWindowEnd: DateTime(2026, 4, 10, 22),
    baseGoalKcal: 2000,
    carryoverKcal: carryoverKcal,
    goalMode: CalorieGoalMode.maintain,
    flexibleGoalKcal: 2000 + carryoverKcal,
    pacedGoalKcal: 1000 + carryoverKcal,
    consumedKcal: 1000,
    deltaKcal: 0,
    paceRatio: 0.5,
    deadZoneKcal: 60,
    rangeKcal: 600,
    activityDeltaKcal: activityDeltaKcal,
    usedLearnedTdee: usedLearnedTdee,
  );
}
