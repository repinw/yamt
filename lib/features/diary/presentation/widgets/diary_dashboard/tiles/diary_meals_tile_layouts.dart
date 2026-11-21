import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/models/diary_meal_kcal.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile_numbers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_caption.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The inside of the meals tile at [size]: bars or names under the kcal.
class DiaryMealsTileLayout extends StatelessWidget {
  /// Creates the layout of [meals].
  const new({
    required this.meals,
    required this.numberFormat,
    required this.size,
    required this.bars,
    super.key,
  });

  /// The meals in section order.
  final List<DiaryMealKcal> meals;

  /// Formats the kcal.
  final NumberFormat numberFormat;

  /// Size of the tile.
  final DiaryTileSize size;

  /// Whether the meals show bars, where the size has room for them.
  final bool bars;

  @override
  Widget build(BuildContext context) => switch (size) {
    DiaryTileSize.s4x1 => _Columns(
      meals: meals,
      numberFormat: numberFormat,
      bars: bars,
    ),
    DiaryTileSize.s2x2 || DiaryTileSize.s4x2 => _Rows(
      meals: meals,
      numberFormat: numberFormat,
      bars: bars,
      withNames: size == DiaryTileSize.s4x2,
    ),
    _ => _Grid(meals: meals, numberFormat: numberFormat),
  };
}

/// The four meals of a 2×1 tile: two by two, icon and kcal.
class _Grid extends StatelessWidget {
  const new({required this.meals, required this.numberFormat});

  /// The meals in section order.
  final List<DiaryMealKcal> meals;

  /// Formats the kcal.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final sharedWidth = diaryMealNumberWidth(context, meals, numberFormat);
    Widget cell(DiaryMealKcal meal) => Expanded(
      child: DiaryMealIconNumber(
        meal: meal,
        sharedWidth: sharedWidth,
        numberFormat: numberFormat,
        nameShown: false,
      ),
    );
    final half = (meals.length / 2).ceil();
    return Column(
      spacing: AppSpacing.xxs,
      children: [
        for (final row in [meals.take(half), meals.skip(half)])
          Expanded(
            child: Row(
              spacing: AppSpacing.xs,
              children: [for (final meal in row) cell(meal)],
            ),
          ),
      ],
    );
  }
}

/// The four meals of a 4×1 tile side by side: icon and kcal above a bar,
/// or above the meal name.
class _Columns extends StatelessWidget {
  const new({
    required this.meals,
    required this.numberFormat,
    required this.bars,
  });

  /// The meals in section order.
  final List<DiaryMealKcal> meals;

  /// Formats the kcal.
  final NumberFormat numberFormat;

  /// Whether a bar shows below each number instead of the meal name.
  final bool bars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = _dayScale(meals);
    final sharedWidth = diaryMealNumberWidth(context, meals, numberFormat);
    return LayoutBuilder(
      builder: (context, constraints) {
        final showNames =
            !bars &&
            diaryMealNamesFit(
              context,
              meals,
              (constraints.maxWidth - (meals.length - 1) * AppSpacing.xs) /
                  meals.length,
            );
        return Row(
          spacing: AppSpacing.xs,
          children: [
            for (final meal in meals)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.xxs,
                  children: [
                    Expanded(
                      child: DiaryMealIconNumber(
                        meal: meal,
                        sharedWidth: sharedWidth,
                        numberFormat: numberFormat,
                        nameShown: showNames,
                      ),
                    ),
                    if (bars)
                      _MealBar(meal: meal, scale: scale)
                    else if (showNames)
                      DiaryTileCaption(meal.mealType.localizedName(l10n)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The four meals of a 2×2 or 4×2 tile, one row each: icon, the meal name
/// when [withNames], a bar when [bars], and the kcal.
class _Rows extends StatelessWidget {
  const new({
    required this.meals,
    required this.numberFormat,
    required this.bars,
    required this.withNames,
  });

  /// The meals in section order.
  final List<DiaryMealKcal> meals;

  /// Formats the kcal.
  final NumberFormat numberFormat;

  /// Whether each row shows a bar.
  final bool bars;

  /// Whether each row names its meal.
  final bool withNames;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final scale = _dayScale(meals);
    final sharedWidth = diaryMealNumberWidth(context, meals, numberFormat);
    return LayoutBuilder(
      builder: (context, constraints) {
        // The room the flexible parts share, less the icon and the gaps.
        final shared =
            constraints.maxWidth -
            AppDashboard.captionIcon -
            (withNames ? 1 : 0) * AppSpacing.xs -
            (bars ? 1 : 0) * AppSpacing.xs -
            AppSpacing.xs;
        final flexes =
            AppDashboard.mealNameFlex +
            (bars ? AppDashboard.mealBarFlex : 0) +
            AppDashboard.mealNumberFlex;
        final showNames =
            withNames &&
            diaryMealNamesFit(
              context,
              meals,
              shared * AppDashboard.mealNameFlex / flexes,
            );
        return Column(
          spacing: AppSpacing.xxs,
          children: [
            for (final meal in meals)
              Expanded(
                child: Row(
                  spacing: AppSpacing.xs,
                  children: [
                    Icon(
                      diaryMealIcon(meal.mealType),
                      size: AppDashboard.captionIcon,
                      color: colors.muted,
                      // Where the name drops out, the icon says it.
                      semanticLabel: showNames
                          ? null
                          : meal.mealType.localizedName(l10n),
                    ),
                    if (showNames)
                      Expanded(
                        flex: AppDashboard.mealNameFlex,
                        child: DiaryTileCaption(
                          meal.mealType.localizedName(l10n),
                        ),
                      ),
                    if (bars)
                      Expanded(
                        flex: AppDashboard.mealBarFlex,
                        child: _MealBar(meal: meal, scale: scale),
                      ),
                    Expanded(
                      flex: AppDashboard.mealNumberFlex,
                      child: DiaryMealNumber(
                        meal: meal,
                        sharedWidth: sharedWidth,
                        numberFormat: numberFormat,
                        alignment: AlignmentDirectional.centerEnd,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The kcal at which a bar is full: the whole day's meals.
double _dayScale(List<DiaryMealKcal> meals) =>
    meals.fold<double>(0, (sum, meal) => sum + meal.total) /
    AppBudgetCard.lineScale;

class _MealBar extends StatelessWidget {
  const new({required this.meal, required this.scale});

  final DiaryMealKcal meal;

  final double scale;

  @override
  Widget build(BuildContext context) => DiaryBudgetLine(
    eaten: meal.eaten,
    planned: meal.planned,
    target: null,
    scaleKcal: scale,
    compact: true,
  );
}
