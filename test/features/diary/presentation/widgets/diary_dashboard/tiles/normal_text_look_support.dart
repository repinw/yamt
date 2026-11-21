import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_macro_tile_view.dart';
import 'package:yamt/features/diary/presentation/models/diary_meal_kcal.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
import 'package:yamt/l10n/app_localizations.dart';

const FoodLabelColors _colors = FoodLabelColors.light;

/// Grams of three different lengths, so that a size that follows each text
/// alone differs from one that all three share.
const normalTextGrams = ['128 g', '1.234 g', '40 g'];

/// The three macros of a tile in [l10n].
List<DiaryMacroTileView> normalTextMacros(AppLocalizations l10n) {
  DiaryMacroTileView macro(
    DiaryBudgetMacroKind kind,
    String letter,
    String value,
  ) => (
    letter: letter,
    label: diaryBudgetMacroLabel(l10n, kind),
    value: value,
    total: l10n.diaryMacroEatenOfTarget('88', '128'),
    labelColor: _colors.ink,
    valueColor: _colors.ink,
    eaten: 88,
    planned: 0,
    target: 128,
    scale: 128,
    eatenColor: _colors.accent,
  );
  return [
    macro(
      DiaryBudgetMacroKind.protein,
      l10n.diaryDashboardMacroProteinShort,
      normalTextGrams[0],
    ),
    macro(
      DiaryBudgetMacroKind.carbs,
      l10n.diaryDashboardMacroCarbsShort,
      normalTextGrams[1],
    ),
    macro(
      DiaryBudgetMacroKind.fat,
      l10n.diaryDashboardMacroFatShort,
      normalTextGrams[2],
    ),
  ];
}

/// The four meals of a day, with kcal of different lengths.
List<DiaryMealKcal> normalTextMeals() => [
  const DiaryMealKcal(mealType: MealType.breakfast, eaten: 1250, planned: 0),
  const DiaryMealKcal(mealType: MealType.lunch, eaten: 820, planned: 0),
  const DiaryMealKcal(mealType: MealType.dinner, eaten: 45, planned: 0),
  const DiaryMealKcal(mealType: MealType.snack, eaten: 310, planned: 0),
];

/// Number format of [locale].
NumberFormat normalTextFormat(String locale) =>
    NumberFormat.decimalPattern(locale);

/// The day of the budget card scenarios.
final normalTextDay = DateTime(2026, 4, 27);

const _metrics = DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 1000,
  eatenKcal: 1000,
  realDayLeftKcal: 1000,
  dayLeftKcal: 1000,
  targetKcal: 2000,
);

/// Card data with grams of three different lengths (1.170 g, 200 g, 60 g).
DiaryBudgetCardData normalTextCardData({bool pause = false}) =>
    DiaryBudgetCardData(
      day: normalTextDay,
      status: DiaryDayStatus.today,
      metrics: _metrics,
      isPauseDay: pause,
      macros: const [
        (
          kind: DiaryBudgetMacroKind.protein,
          eaten: 80,
          planned: 20,
          target: 1170,
        ),
        (kind: DiaryBudgetMacroKind.carbs, eaten: 150, planned: 0, target: 200),
        (kind: DiaryBudgetMacroKind.fat, eaten: 55, planned: 0, target: 60),
      ],
    );

/// Every text and every leaf box under [root] with its place on the screen,
/// one line each, rounded to a hundredth of a dp.
List<String> renderedLook(WidgetTester tester, Finder root) {
  final rows = <String>[];
  void walk(RenderObject object) {
    if (object is RenderBox && object.hasSize) {
      final origin = object.localToGlobal(Offset.zero);
      var leaf = true;
      object.visitChildren((_) => leaf = false);
      // An empty positioning box takes no room and draws nothing.
      final empty = object is RenderPositionedBox && object.size.height == 0;
      if (object is RenderParagraph || (leaf && !empty)) {
        final text = object is RenderParagraph
            ? ' "${object.text.toPlainText()}"'
            : '';
        rows.add(
          '${object.runtimeType}$text '
          '${origin.dx.toStringAsFixed(2)},${origin.dy.toStringAsFixed(2)},'
          '${object.size.width.toStringAsFixed(2)},'
          '${object.size.height.toStringAsFixed(2)}',
        );
      }
    }
    object.visitChildren(walk);
  }

  walk(tester.renderObject(root));
  return rows;
}

/// A short hash of [rows], for a pin that stays small.
String lookHash(List<String> rows) {
  var hash = 0x811c9dc5;
  for (final unit in rows.join('\n').codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
