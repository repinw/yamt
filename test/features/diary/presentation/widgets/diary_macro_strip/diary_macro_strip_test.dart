import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_overlay.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_stage.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_trigger.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars_content.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';
import '../../../support/diary_dashboard_test_support.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  Widget app(Widget child, {bool showDetails = false}) {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 4, 27, 12)),
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(
            initialStrings: showDetails
                ? const {'diary_balance_details_v1': 'shown'}
                : null,
          ),
        ),
        diaryDayDashboardControllerProvider(selectedDay).overrideWithValue(
          diaryDashboardLoadedStateForTest(
            selectedDay: selectedDay,
            nutritionBars: const DiaryNutritionBarsData(
              protein: 41,
              carbs: 102,
              fat: 47,
              goals: DiaryMacroTargets(protein: 105, carbs: 100, fat: 49),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('quiet strip says what is left and what is over', (tester) async {
    await tester.pumpWidget(app(DiaryMacroStrip(selectedDay: selectedDay)));

    expect(find.text('64g left'), findsOneWidget);
    expect(find.text('2g left'), findsOneWidget);
    expect(find.text('2g over'), findsOneWidget);
    expect(find.text('41 / 105'), findsNothing);
    final overage = tester.widget<Text>(find.text('2g over'));
    expect(
      overage.style?.color,
      Theme.of(tester.element(find.text('2g over'))).colorScheme.error,
    );
  });

  testWidgets('detailed strip shows eaten and target with segmented bars', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(DiaryMacroStrip(selectedDay: selectedDay), showDetails: true),
    );

    expect(find.text('41 / 105'), findsOneWidget);
    expect(find.text('102 / 100'), findsOneWidget);
    expect(find.text('47 / 49'), findsOneWidget);
    final bars = tester
        .widgetList<DiarySegmentedProgressBar>(
          find.byType(DiarySegmentedProgressBar),
        )
        .toList();
    expect(bars, hasLength(3));
    expect(bars.first.progress, closeTo(41 / 105, 0.001));
  });

  testWidgets('trigger reveals kcal, then macros as card parts scroll away', (
    tester,
  ) async {
    final anchors = DiaryMacroStripAnchors();
    final stage = ValueNotifier(DiaryMacroStripStage.hidden);
    addTearDown(stage.dispose);
    await tester.pumpWidget(
      app(
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 50,
              // With the strip inset the kcal row covers 40px.
              title: SizedBox(
                key: anchors.stripKcalRow,
                height: 40 - diaryMacroStripKcalRowInset,
              ),
            ),
            DiaryMacroStripTrigger(anchors: anchors, stage: stage),
            SliverToBoxAdapter(
              child: Column(
                key: anchors.card,
                children: [
                  const SizedBox(height: 100),
                  SizedBox(key: anchors.kcalBar, height: 20),
                  const SizedBox(height: 100),
                  // Three 20px rows with two gaps.
                  SizedBox(
                    key: anchors.macroBars,
                    height: 60 + 2 * diaryMacroRowGap,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 2000)),
          ],
        ),
      ),
    );

    // The card starts right below the pinned bar, so the scroll offset is
    // the covered part of the card.
    Future<void> scrollTo(double offset) async {
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .jumpTo(offset);
      await tester.pumpAndSettle();
    }

    await scrollTo(0);
    expect(stage.value, DiaryMacroStripStage.hidden);

    // Kcal bar top is at 100.
    await scrollTo(99);
    expect(stage.value, DiaryMacroStripStage.hidden);

    await scrollTo(101);
    expect(stage.value, DiaryMacroStripStage.kcal);

    // The fat row starts at 280; the 40px kcal row reaches it at 240.
    await scrollTo(239);
    expect(stage.value, DiaryMacroStripStage.kcal);

    await scrollTo(241);
    expect(stage.value, DiaryMacroStripStage.full);

    await scrollTo(0);
    expect(stage.value, DiaryMacroStripStage.hidden);
  });

  testWidgets('overlay reveals rows per stage', (tester) async {
    final stage = ValueNotifier(DiaryMacroStripStage.hidden);
    addTearDown(stage.dispose);
    await tester.pumpWidget(
      app(DiaryMacroStripOverlay(selectedDay: selectedDay, stage: stage)),
    );
    expect(find.text('64g left'), findsNothing);

    stage.value = DiaryMacroStripStage.full;
    await tester.pumpAndSettle();
    expect(find.text('64g left'), findsOneWidget);

    stage.value = DiaryMacroStripStage.kcal;
    await tester.pumpAndSettle();
    expect(find.text('64g left'), findsNothing);
  });
}
