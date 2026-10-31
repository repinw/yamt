import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_after_plan_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_tile_parts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile_layouts.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The kcal of each meal of the day, as bars or as a list.
const diaryMealsTile = DiaryDashboardTile(
  id: 'meals',
  icon: Icons.restaurant_outlined,
  label: _label,
  sizes: [
    DiaryTileSize.s2x1,
    DiaryTileSize.s2x2,
    DiaryTileSize.s4x1,
    DiaryTileSize.s4x2,
  ],
  defaultSize: DiaryTileSize.s4x1,
  modes: [
    DiaryTileMode(id: 'bars', icon: Icons.bar_chart_rounded, label: _bars),
    DiaryTileMode(id: 'list', icon: Icons.list_rounded, label: _list),
  ],
  builder: _build,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileMeals;

String _bars(AppLocalizations l10n) => l10n.diaryDashboardMealsModeBars;

String _list(AppLocalizations l10n) => l10n.diaryDashboardMealsModeList;

Widget _build(DiaryTileArgs args) => _DiaryMealsTileBody(args: args);

class _DiaryMealsTileBody extends ConsumerWidget {
  const new({required this.args});

  final DiaryTileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(
      diaryDayDashboardControllerProvider(args.day)
          .select((state) => state.data?.mealSections),
    );
    if (sections == null) {
      return DiaryTileNumber('–', color: FoodLabelColors.of(context).muted);
    }
    // The same kcal as the meal headings below the dashboard.
    final withOpenPlans = ref.watch(
      diaryOpenPlansProvider(args.day)
          .select((plans) => plans?.counted ?? false),
    );
    final meals = [
      for (final section in sections)
        _mealOf(section, withOpenPlans: withOpenPlans),
    ];
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final bars = args.mode != 'list';
    return switch (args.size) {
      DiaryTileSize.s4x1 => DiaryMealsColumns(
        meals: meals,
        numberFormat: numberFormat,
        bars: bars,
      ),
      DiaryTileSize.s2x2 || DiaryTileSize.s4x2 => DiaryMealsRows(
        meals: meals,
        numberFormat: numberFormat,
        bars: bars,
        withNames: args.size == DiaryTileSize.s4x2,
      ),
      _ => DiaryMealsGrid(meals: meals, numberFormat: numberFormat),
    };
  }

  static DiaryMealKcal _mealOf(
    DiaryMealSection section, {
    required bool withOpenPlans,
  }) {
    final eaten = section.entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    final total = section.headingTotal(withOpenPlans: withOpenPlans).kcal;
    return DiaryMealKcal(
      mealType: section.mealType,
      eaten: eaten,
      planned: total > eaten ? total - eaten : 0,
    );
  }
}
