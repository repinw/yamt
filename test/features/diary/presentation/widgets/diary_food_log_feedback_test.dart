import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_food_log_feedback_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_nutrition.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_food_log_feedback/diary_food_log_feedback_host.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_macro_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

const goals = DiaryMacroTargets(protein: 100, carbs: 200, fat: 70);

void main() {
  Widget app(
    Widget child, {
    bool accessible = false,
    bool reduced = false,
    double scale = 1,
    bool dark = false,
  }) => MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: dark
        ? AppTheme.dark(seedColor: Colors.green)
        : AppTheme.light(seedColor: Colors.green),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        accessibleNavigation: accessible,
        disableAnimations: reduced,
        textScaler: TextScaler.linear(scale),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
  final food = CalorieEntry.create(
    id: 'food',
    userId: 'user',
    name: 'Skyr mit Haferflocken',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 184,
    per100Protein: 25,
    per100Carbs: 12,
    per100Fat: 4,
    loggedAt: DateTime(2026, 9, 5),
  );
  DiaryFoodLogFeedback feedback({bool dailyContext = true}) =>
      DiaryFoodLogFeedback(
        entries: [food],
        startedAt: DateTime.now(),
        before: dailyContext
            ? const DiaryNutritionBarsData(
                protein: 50,
                carbs: 80,
                fat: 30,
                goals: goals,
              )
            : null,
        after: dailyContext
            ? const DiaryNutritionBarsData(
                protein: 75,
                carbs: 92,
                fat: 34,
                goals: goals,
              )
            : null,
      );

  testWidgets(
    'shows all macros, daily context and an accessible close action',
    (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        app(
          DiaryFoodLogFeedbackCard(
            feedback: feedback(),
            onDismiss: () => closed++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.text('Eiweiß'), findsOneWidget);
      expect(find.text('Kohlenhydrate'), findsOneWidget);
      expect(find.text('Fett'), findsOneWidget);
      expect(find.text('75 von 100 g'), findsOneWidget);
      expect(find.text('+25 g'), findsOneWidget);
      expect(find.text('Noch 25 g'), findsOneWidget);
      expect(find.byTooltip('Nährwertrückmeldung schließen'), findsOneWidget);
      await tester.tap(find.byTooltip('Nährwertrückmeldung schließen'));
      expect(closed, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'feedback and the compact daily row share the booking transition',
    (tester) async {
      final booking = feedback();
      await tester.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiaryNutritionMacroRow(
                label: 'Eiweiß',
                current: 75,
                previous: 50,
                startedAt: booking.startedAt,
                target: 100,
                color: Colors.green,
                numberFormat: NumberFormat.decimalPattern('de'),
                unit: 'g',
              ),
              DiaryFoodLogFeedbackCard(
                feedback: booking,
                onDismiss: () {},
              ),
            ],
          ),
          accessible: true,
        ),
      );

      List<DiarySegmentedProgressBar> bars() => tester
          .widgetList<DiarySegmentedProgressBar>(
            find.byType(DiarySegmentedProgressBar),
          )
          .toList();

      expect(bars().first.progress, greaterThanOrEqualTo(0.5));
      expect(bars().first.progress, lessThan(0.75));
      await tester.pump(const Duration(milliseconds: 350));
      expect(bars().first.progress, greaterThan(0.5));
      expect(bars().first.progress, lessThan(0.75));
      expect(bars()[1].progress, closeTo(bars().first.progress, 0.01));
      expect(bars().first.highlightStart, 0.5);
      expect(bars().first.highlightOpacity, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 350));
      expect(bars().first.progress, 0.75);
      expect(bars()[1].progress, 0.75);
      expect(find.text('75 von 100 g'), findsOneWidget);
      expect(
        find.textContaining('75 / 100g', findRichText: true),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(bars().first.highlightOpacity, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('goal overflow preserves the confirmed amount and new total', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        DiaryFoodLogFeedbackCard(
          feedback: DiaryFoodLogFeedback(
            entries: [food],
            startedAt: DateTime.now(),
            before: const DiaryNutritionBarsData(
              protein: 100,
              carbs: 80,
              fat: 30,
              goals: goals,
            ),
            after: const DiaryNutritionBarsData(
              protein: 125,
              carbs: 92,
              fat: 34,
              goals: goals,
            ),
          ),
          onDismiss: () {},
        ),
        accessible: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('125 von 100 g'), findsOneWidget);
    expect(find.text('+25 g'), findsOneWidget);
    expect(find.text('25 g über dem Ziel'), findsOneWidget);
    expect(
      tester
          .widgetList<DiarySegmentedProgressBar>(
            find.byType(DiarySegmentedProgressBar),
          )
          .first
          .progress,
      1,
    );
  });

  testWidgets(
    'auto-dismisses after five seconds and stays with accessibility enabled',
    (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        app(
          DiaryFoodLogFeedbackCard(
            feedback: feedback(),
            onDismiss: () => closed++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(closed, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        app(
          DiaryFoodLogFeedbackCard(
            feedback: feedback(),
            onDismiss: () => closed++,
          ),
          accessible: true,
        ),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(closed, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'missing daily context shows committed amounts without progress bars',
    (tester) async {
      await tester.pumpWidget(
        app(
          DiaryFoodLogFeedbackCard(
            feedback: feedback(dailyContext: false),
            onDismiss: () {},
          ),
          accessible: true,
        ),
      );
      expect(find.text('+25 g'), findsOneWidget);
      expect(find.byType(DiarySegmentedProgressBar), findsNothing);
      expect(find.textContaining('von 100'), findsNothing);
    },
  );

  testWidgets('large German text remains usable in both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        app(
          DiaryFoodLogFeedbackCard(
            feedback: feedback(),
            onDismiss: () {},
          ),
          accessible: true,
          reduced: true,
          scale: 2,
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Nährwertrückmeldung schließen'), findsOneWidget);
    }
  });

  testWidgets(
    'entry spells out macros, explains emphasis and daily contribution',
    (tester) async {
      const entry = DiaryMealEntry(
        id: 'food',
        mealType: MealType.lunch,
        name: 'Food',
        totalKcal: 184,
        totalProtein: 25,
        totalCarbs: 12,
        totalFat: 4,
      );
      await tester.pumpWidget(
        app(const DiaryEntryNutrition(entry: entry, targets: goals)),
      );
      expect(find.text('P 25g'), findsOneWidget);
      expect(find.text('K 12g'), findsOneWidget);
      expect(find.text('F 4g'), findsOneWidget);
      expect(find.text('25 % deines Tagesziels'), findsOneWidget);
      expect(find.text('6 % deines Tagesziels'), findsOneWidget);
      expect(find.text('Eiweißbetont'), findsOneWidget);
      await tester.tap(find.text('Eiweißbetont'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('keine gesundheitliche Bewertung'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'collapsed entry renders single line with letters and no chip',
    (tester) async {
      const entry = DiaryMealEntry(
        id: 'food',
        mealType: MealType.lunch,
        name: 'Food',
        totalKcal: 184,
        totalProtein: 25,
        totalCarbs: 12,
        totalFat: 4,
      );
      await tester.pumpWidget(app(const DiaryEntryNutrition(entry: entry)));
      expect(
        find.textContaining('P 25g', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('K 12g', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('F 4g', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(ActionChip), findsNothing);
    },
  );
}
