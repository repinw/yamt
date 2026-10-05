import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_quick_entry_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/diary_quick_entry_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_meals_section_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_quick_eat_actions.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_quick_entry_label.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/features/diary/support/diary_quick_entry_test_support.dart';
import '../../test/helpers/sheet_launcher.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quick entry logs typed calories from the diary dock', (
    tester,
  ) async {
    final calorieLog = FakeCalorieLogRepository();
    addTearDown(calorieLog.dispose);
    await _openQuickEntry(tester, quickEntryOverrides(calorieLog));

    expect(find.byType(DiaryQuickEntryPage), findsOneWidget);
    expect(find.byKey(EatWhenMenu.buttonKey), findsOneWidget);
    expect(find.byKey(DiaryQuickEntryPage.aiHintKey), findsOneWidget);

    await tester.enterText(find.byKey(DiaryQuickEntryPage.nameKey), 'Kantine');
    for (final (value, text) in [
      (DiaryQuickEntryValue.kcal, '650'),
      (DiaryQuickEntryValue.fat, '22'),
      (DiaryQuickEntryValue.carbs, '70'),
      (DiaryQuickEntryValue.protein, '30'),
    ]) {
      await tester.enterText(
        find.byKey(DiaryQuickEntryLabel.valueKey(value)),
        text,
      );
      await tester.pump();
    }
    expect(find.byKey(DiaryQuickEntryPage.aiHintKey), findsNothing);

    await tester.tap(find.byKey(DiaryQuickEntryPage.confirmKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryQuickEntryPage), findsNothing);
    final entry = calorieLog.entries.single;
    expect(entry.isQuickEntry, isTrue);
    expect(entry.name, 'Kantine');
    expect(entry.totalKcal, 650);
    expect(entry.totalFat, 22);
    expect(entry.totalCarbs, 70);
    expect(entry.totalProtein, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick entry on a future day saves a plan', (tester) async {
    final calorieLog = FakeCalorieLogRepository();
    addTearDown(calorieLog.dispose);
    final plans = FakePlannedEntryRepository();
    await _openQuickEntry(
      tester,
      quickEntryOverrides(calorieLog, plans: plans),
      day: quickEntryNow.add(const Duration(days: 1)),
    );

    // The product search saves no plans yet.
    expect(find.byKey(DiaryQuickEntryPage.aiHintKey), findsNothing);
    await tester.enterText(
      find.byKey(DiaryQuickEntryLabel.valueKey(DiaryQuickEntryValue.kcal)),
      '700',
    );
    await tester.pump();
    await tester.tap(find.byKey(DiaryQuickEntryPage.confirmKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryQuickEntryPage), findsNothing);
    expect(plans.plans.single.totalKcal, 700);
    expect(calorieLog.entries, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

/// Opens the quick entry page from the Eat sheet, on [day] when given.
Future<void> _openQuickEntry(
  WidgetTester tester,
  List<Override> overrides, {
  DateTime? day,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: SheetLauncher(actions: diaryQuickEatActions)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (day != null) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SheetLauncher)),
    );
    // The calendar controller disposes without a listener, which would drop
    // the picked day before the sheet opens.
    final calendar = container.listen(
      diaryCalendarControllerProvider,
      (_, _) {},
    );
    addTearDown(calendar.close);
    container.read(diaryCalendarControllerProvider.notifier).selectDay(day);
    await tester.pumpAndSettle();
  }

  await tester.tap(find.byKey(SheetLauncher.buttonKey));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(
      DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.quickEntry),
    ),
  );
  await tester.pumpAndSettle();
}
