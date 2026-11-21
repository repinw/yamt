import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/app_font_test_utils.dart';
import '../../../../../helpers/fake_accelerometer.dart';
import '../../../../../helpers/memory_app_preferences.dart';
import '../../../../calories/support/fake_calories_repositories.dart';

final _day = DateTime(2026, 4, 27);

const _metrics = DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 1000,
  eatenKcal: 1000,
  realDayLeftKcal: 1000,
  dayLeftKcal: 1000,
  targetKcal: 2000,
);

DiaryBudgetCardData _data(DiaryDayType type) => DiaryBudgetCardData(
  day: _day,
  status: DiaryDayStatus.today,
  metrics: _metrics,
  isPauseDay: type == DiaryDayType.pause,
  macros: const [
    (kind: DiaryBudgetMacroKind.protein, eaten: 80, planned: 0, target: 150),
    (kind: DiaryBudgetMacroKind.carbs, eaten: 150, planned: 0, target: 1250),
    (kind: DiaryBudgetMacroKind.fat, eaten: 20, planned: 0, target: 60),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required DiaryDayType type,
  required double cardWidth,
  required String locale,
  double textScale = 2,
  bool showDetails = false,
  bool showEaten = false,
}) async {
  FakeAccelerometer();
  final settings = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime(2026),
      trainingWeekdays: [if (type == DiaryDayType.training) _day.weekday],
      pauseDayKeys: [if (type == DiaryDayType.pause) localDayKey(_day)],
    ),
  );
  addTearDown(settings.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        clockProvider.overrideWithValue(
          () => _day.add(const Duration(hours: 12)),
        ),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, page) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: page!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: cardWidth,
                child: DiaryBudgetCard(
                  data: _data(type),
                  showDetails: showDetails,
                  showEaten: showEaten,
                  today: _day,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(loadAppFonts);

  for (final locale in ['de', 'en']) {
    for (final cardWidth in [343.0, 288.0]) {
      for (final type in DiaryDayType.values) {
        for (final showDetails in [false, true]) {
          testWidgets(
            'a ${type.name} day card${showDetails ? ' with details' : ''} '
            'takes ${cardWidth.round()} dp at text size 2 in $locale',
            (tester) async {
              await _pump(
                tester,
                type: type,
                cardWidth: cardWidth,
                locale: locale,
                showDetails: showDetails,
              );

              expect(tester.takeException(), isNull);

              final card = tester.getRect(find.byKey(DiaryBudgetCardKeys.card));
              expect(card.width, closeTo(cardWidth, 0.01));

              // The day type buttons stay inside the card, whether they sit
              // beside the view switch or wrapped below it.
              final training = tester.getRect(
                find.byKey(
                  DiaryBudgetCardKeys.dayTypeButton(DiaryDayType.training),
                ),
              );
              final pause = tester.getRect(
                find.byKey(
                  DiaryBudgetCardKeys.dayTypeButton(DiaryDayType.pause),
                ),
              );
              for (final button in [training, pause]) {
                expect(button.left, greaterThanOrEqualTo(card.left));
                expect(button.right, lessThanOrEqualTo(card.right));
              }
              expect(training.overlaps(pause), isFalse);

              if (type == DiaryDayType.pause) {
                // A pause day shows eaten only, with no switch.
                expect(
                  find.byKey(DiaryBudgetCardKeys.viewSegment(eaten: false)),
                  findsNothing,
                );
                // The buttons stay at the right edge.
                expect(pause.right, closeTo(card.right, 16));
              } else {
                final left = tester.getRect(
                  find.byKey(DiaryBudgetCardKeys.viewSegment(eaten: false)),
                );
                final eaten = tester.getRect(
                  find.byKey(DiaryBudgetCardKeys.viewSegment(eaten: true)),
                );
                expect(left.left, greaterThanOrEqualTo(card.left));
                expect(eaten.right, lessThanOrEqualTo(card.right));
                // Neither button covers a segment of the switch.
                for (final segment in [left, eaten]) {
                  expect(segment.overlaps(training), isFalse);
                  expect(segment.overlaps(pause), isFalse);
                }
              }

              // The three grams of the macro column stay inside the card.
              for (final kind in DiaryBudgetMacroKind.values) {
                final value = tester.getRect(
                  find.byKey(DiaryBudgetCardKeys.macroValue(kind)),
                );
                expect(value.right, lessThanOrEqualTo(card.right));
                expect(value.left, greaterThanOrEqualTo(card.left));
              }
            },
          );
        }
      }
    }
  }
}
