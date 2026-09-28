import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_quick_entry_controller.dart';
import 'package:yamt/features/diary/presentation/diary_quick_entry_page.dart';
import 'package:yamt/features/diary/presentation/models/'
    'diary_quick_entry_result.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_quick_entry_label.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_calories_repositories.dart';
import '../support/diary_quick_entry_test_support.dart';

const _openKey = Key('open_quick_entry');
const _confirmHintKey = Key('eat_page_confirm_hint');
final _loggedAt = DateTime(2026, 9, 26, 8, 15);

void main() {
  late FakeCalorieLogRepository calorieLog;
  late List<DiaryQuickEntryResult?> results;

  setUp(() {
    calorieLog = FakeCalorieLogRepository();
    results = [];
  });
  tearDown(() => calorieLog.dispose());

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: quickEntryOverrides(calorieLog),
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: _openKey,
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<DiaryQuickEntryResult>(
                        MaterialPageRoute(
                          builder: (_) => DiaryQuickEntryPage(
                            initialLoggedAt: _loggedAt,
                            initialMealType: MealType.breakfast,
                          ),
                        ),
                      );
                  results.add(result);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();
  }

  Finder valueField(DiaryQuickEntryValue value) {
    return find.byKey(DiaryQuickEntryLabel.valueKey(value));
  }

  Future<void> type(
    WidgetTester tester,
    DiaryQuickEntryValue value,
    String text,
  ) async {
    await tester.enterText(valueField(value), text);
    await tester.pump();
  }

  VoidCallback? confirmAction(WidgetTester tester) {
    return tester
        .widget<FilledButton>(find.byKey(DiaryQuickEntryPage.confirmKey))
        .onPressed;
  }

  Color kcalFrameColor(WidgetTester tester) {
    final field = tester.widget<TextField>(
      valueField(DiaryQuickEntryValue.kcal),
    );
    return field.decoration!.enabledBorder!.borderSide.color;
  }

  testWidgets('needs the calories before it can log', (tester) async {
    await openPage(tester);
    final colors = FoodLabelColors.of(
      tester.element(find.byType(DiaryQuickEntryPage)),
    );

    expect(confirmAction(tester), isNull);
    expect(find.byKey(_confirmHintKey), findsOneWidget);
    expect(find.text('Still missing: calories'), findsOneWidget);
    expect(kcalFrameColor(tester), colors.accent);

    await type(tester, DiaryQuickEntryValue.protein, '20');
    expect(confirmAction(tester), isNull);

    await type(tester, DiaryQuickEntryValue.kcal, '350');

    expect(confirmAction(tester), isNotNull);
    expect(find.byKey(_confirmHintKey), findsNothing);
    expect(kcalFrameColor(tester), isNot(colors.accent));
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('350 kcal'), findsOneWidget);
  });

  testWidgets('points to the AI estimate while a macro is missing', (
    tester,
  ) async {
    await openPage(tester);

    expect(find.byKey(DiaryQuickEntryPage.aiHintKey), findsOneWidget);

    await type(tester, DiaryQuickEntryValue.kcal, '350');
    await type(tester, DiaryQuickEntryValue.fat, '10');
    await type(tester, DiaryQuickEntryValue.carbs, '40');
    expect(find.byKey(DiaryQuickEntryPage.aiHintKey), findsOneWidget);

    await type(tester, DiaryQuickEntryValue.protein, '20');
    expect(find.byKey(DiaryQuickEntryPage.aiHintKey), findsNothing);

    await type(tester, DiaryQuickEntryValue.protein, '');
    await tester.tap(find.byKey(DiaryQuickEntryPage.aiButtonKey));
    await tester.pumpAndSettle();

    final result = results.single! as DiaryQuickEntryAiRequested;
    expect(result.loggedAt, _loggedAt);
    expect(result.mealType, MealType.breakfast);
    expect(calorieLog.entries, isEmpty);
  });

  testWidgets('logs a quick entry with the typed totals, day, and meal', (
    tester,
  ) async {
    await openPage(tester);

    await tester.tap(find.byKey(EatWhenMenu.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<Object>, 'Dinner'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EatWhenMenu.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EatWhenMenu.pickDayKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('27'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(DiaryQuickEntryPage.nameKey), 'Kantine');
    await type(tester, DiaryQuickEntryValue.kcal, '650');
    await type(tester, DiaryQuickEntryValue.protein, '30,5');
    await type(tester, DiaryQuickEntryValue.carbs, '70');
    await tester.tap(find.byKey(DiaryQuickEntryPage.confirmKey));
    await tester.pumpAndSettle();

    final entry = calorieLog.entries.single;
    expect(entry.isQuickEntry, isTrue);
    expect(entry.name, 'Kantine');
    expect(entry.userId, 'user-1');
    expect(entry.mealType, MealType.dinner);
    // The picked day keeps the time of day of now.
    expect(entry.loggedAt, DateTime(2026, 9, 27, 12, 30));
    expect(entry.createdAt, quickEntryNow);
    expect(entry.totalKcal, 650);
    expect(entry.totalProtein, 30.5);
    expect(entry.totalCarbs, 70);
    expect(entry.totalFat, 0);
    expect(entry.sourceInventoryItemId, isNull);
    expect(entry.isValid, isTrue);
    final result = results.single! as DiaryQuickEntrySaved;
    expect(result.entry.id, entry.id);
    expect(find.byType(DiaryQuickEntryPage), findsNothing);
  });

  testWidgets('names an entry without a name "Quick entry"', (tester) async {
    await openPage(tester);

    await type(tester, DiaryQuickEntryValue.kcal, '120');
    await tester.tap(find.byKey(DiaryQuickEntryPage.confirmKey));
    await tester.pumpAndSettle();

    expect(calorieLog.entries.single.name, 'Quick entry');
    expect(calorieLog.entries.single.mealType, MealType.breakfast);
  });

  testWidgets('stays open with a message when saving fails', (tester) async {
    calorieLog.saveShouldFail = true;
    await openPage(tester);

    await type(tester, DiaryQuickEntryValue.kcal, '120');
    await tester.tap(find.byKey(DiaryQuickEntryPage.confirmKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryQuickEntryPage), findsOneWidget);
    expect(find.text('Could not save entry.'), findsOneWidget);
    expect(results, isEmpty);
    expect(confirmAction(tester), isNotNull);
  });
}
