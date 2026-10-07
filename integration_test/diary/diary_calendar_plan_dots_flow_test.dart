import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_calendar_overview_sheet/diary_calendar_month_grid.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_calendar_overview_sheet/diary_calendar_overview_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_planned_entry_repository.dart';

const _openButtonKey = Key('diary_calendar_plan_dots_open');

final _today = DateTime(2026, 4, 27);

CalorieEntry _plan(String id, DateTime day) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Porridge',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 80,
    per100Protein: 5,
    per100Carbs: 12,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the calendar marks days with plans and follows new plans', (
    tester,
  ) async {
    final overdue = DateTime(2026, 4, 25);
    final upcoming = DateTime(2026, 4, 29);
    final later = DateTime(2026, 5, 2);
    final plans = FakePlannedEntryRepository(
      plans: [_plan('overdue', overdue), _plan('upcoming', upcoming)],
    );
    final bounds = DiaryCalendarBounds.resolve(
      today: _today,
      planStartDay: DateTime(2026, 4),
    );
    final container = ProviderContainer(
      overrides: [plannedEntryRepositoryProvider.overrideWithValue(plans)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: _openButtonKey,
                  onPressed: () => showDiaryCalendarOverviewSheet(
                    context: context,
                    selectedDay: _today,
                    today: _today,
                    bounds: bounds,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryCalendarMonthGrid.dotKey(overdue)), findsOneWidget);
    expect(find.byKey(DiaryCalendarMonthGrid.dotKey(upcoming)), findsOneWidget);

    await plans.savePlannedEntry(_plan('later', later));
    container.read(calorieOverviewRevisionProvider.notifier).markChanged();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryCalendarOverviewKeys.nextMonth));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryCalendarMonthGrid.dotKey(later)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
