import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/application/diary_home_widget_summary.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/home_widget/application/home_widget_snapshot_mapper.dart';

DiaryHomeWidgetSummary _summary() {
  return const DiaryHomeWidgetSummary(
    eatenKcal: 1200,
    targetKcal: 2000,
    macros: DiaryNutritionBarsData(
      carbs: 100,
      protein: 80,
      fat: 40,
      goals: DiaryMacroTargets(carbs: 200, protein: 150, fat: 70),
    ),
  );
}

void main() {
  final now = DateTime(2026, 9, 22, 12);

  test('returns null when no diary summary is loaded yet', () {
    expect(
      buildHomeWidgetSnapshot(summary: null, verbose: true, now: now),
      isNull,
    );
  });

  test('maps a loaded summary field by field', () {
    final snapshot = buildHomeWidgetSnapshot(
      summary: _summary(),
      verbose: true,
      now: now,
    )!;

    expect(snapshot.verbose, isTrue);
    expect(snapshot.eatenKcal, 1200);
    expect(snapshot.targetKcal, 2000);
    expect(snapshot.proteinGrams, 80);
    expect(snapshot.carbsGrams, 100);
    expect(snapshot.fatGrams, 40);
    expect(snapshot.proteinGoalGrams, 150);
    expect(snapshot.carbsGoalGrams, 200);
    expect(snapshot.fatGoalGrams, 70);
    expect(snapshot.updatedAt, now);
  });

  test('passes the verbose flag through as given', () {
    final snapshot = buildHomeWidgetSnapshot(
      summary: _summary(),
      verbose: false,
      now: now,
    )!;

    expect(snapshot.verbose, isFalse);
  });

  test('toJson produces the flat map native widget code reads', () {
    final json = buildHomeWidgetSnapshot(
      summary: _summary(),
      verbose: true,
      now: now,
    )!.toJson();

    expect(json['verbose'], isTrue);
    expect(json['eaten_kcal'], 1200);
    expect(json['target_kcal'], 2000);
    expect(json['protein_goal_grams'], 150);
    expect(json['updated_at'], now.toIso8601String());
  });
}
