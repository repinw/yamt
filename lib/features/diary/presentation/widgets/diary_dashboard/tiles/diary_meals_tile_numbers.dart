import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/utils/text_measure.dart';
import 'package:yamt/features/diary/presentation/models/diary_meal_kcal.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_caption.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Icon of [mealType] in the meals tile.
IconData diaryMealIcon(MealType mealType) => switch (mealType) {
  MealType.breakfast => Icons.free_breakfast_outlined,
  MealType.lunch => Icons.lunch_dining_outlined,
  MealType.dinner => Icons.dinner_dining_outlined,
  MealType.snack => Icons.cookie_outlined,
};

/// Whether the tile shows the names of [meals] in [maxWidth] each: always at
/// the default text size, where a long name ends with an ellipsis; at large
/// text only when all of them fit whole, so the tile shows all of them or
/// none.
bool diaryMealNamesFit(
  BuildContext context,
  List<DiaryMealKcal> meals,
  double maxWidth,
) {
  if (!isLargeText(context)) return true;
  final l10n = AppLocalizations.of(context)!;
  return meals.every(
    (meal) => textFitsWholeWords(
      context,
      meal.mealType.localizedName(l10n),
      DiaryTileCaption.styleOf(context),
      maxWidth: maxWidth,
    ),
  );
}

/// The size that the kcal of [meals] share at large text, to give each
/// [DiaryMealNumber]; null at the default text size.
double? diaryMealNumberWidth(
  BuildContext context,
  List<DiaryMealKcal> meals,
  NumberFormat numberFormat,
) => DiaryTileNumber.sharedWidthOf(context, [
  for (final meal in meals) numberFormat.format(meal.total.round()),
]);

/// A meal's icon with its kcal beside it.
class DiaryMealIconNumber extends StatelessWidget {
  /// Creates the icon and kcal of [meal].
  const new({
    required this.meal,
    required this.sharedWidth,
    required this.numberFormat,
    required this.nameShown,
    super.key,
  });

  /// The meal.
  final DiaryMealKcal meal;

  /// Whether the tile shows the meal's name; if not, the icon says it to a
  /// screen reader.
  final bool nameShown;

  /// The shared size of the tile's kcal, from [diaryMealNumberWidth].
  final double? sharedWidth;

  /// Formats the kcal.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppDashboard.captionGap,
    children: [
      Icon(
        diaryMealIcon(meal.mealType),
        size: AppDashboard.captionIcon,
        color: FoodLabelColors.of(context).muted,
        semanticLabel: nameShown
            ? null
            : meal.mealType.localizedName(AppLocalizations.of(context)!),
      ),
      Expanded(
        child: DiaryMealNumber(
          meal: meal,
          sharedWidth: sharedWidth,
          numberFormat: numberFormat,
        ),
      ),
    ],
  );
}

/// The kcal of a meal as a tile number.
class DiaryMealNumber extends StatelessWidget {
  /// Creates the kcal of [meal].
  const new({
    required this.meal,
    required this.sharedWidth,
    required this.numberFormat,
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  /// The meal.
  final DiaryMealKcal meal;

  /// The shared size of the tile's kcal, from [diaryMealNumberWidth].
  final double? sharedWidth;

  /// Formats the kcal.
  final NumberFormat numberFormat;

  /// Where the number sits when it is smaller than its space.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final kcal = meal.total.round();
    final colors = FoodLabelColors.of(context);
    return DiaryTileNumber(
      numberFormat.format(kcal),
      sharedWidth: sharedWidth,
      alignment: alignment,
      // An empty meal stays quiet; a meal of plans only shows in the plan
      // color.
      color: kcal == 0
          ? colors.muted
          : meal.eaten.round() == 0
          ? colors.plan
          : null,
    );
  }
}
