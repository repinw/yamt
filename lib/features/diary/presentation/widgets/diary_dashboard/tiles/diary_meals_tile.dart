import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_kcals_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile_layouts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_load_error.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_no_value.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The kcal of each meal of the day, as bars or as a list.
const diaryMealsTile = DiaryDashboardTile(
  spec: diaryMealsTileSpec,
  icon: Icons.restaurant_outlined,
  label: _label,
  modes: [
    DiaryTileMode(
      id: DiaryTileModes.bars,
      icon: Icons.bar_chart_rounded,
      label: _bars,
    ),
    DiaryTileMode(
      id: DiaryTileModes.list,
      icon: Icons.list_rounded,
      label: _list,
    ),
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
    if (DiaryTileLoadError.watchFailed(ref, args.day)) {
      return DiaryTileLoadError(size: args.size);
    }
    final meals = ref.watch(diaryMealKcalsProvider(args.day));
    if (meals == null) {
      return const DiaryTileNoValue();
    }
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return DiaryMealsTileLayout(
      meals: meals,
      numberFormat: numberFormat,
      size: args.size,
      bars: args.mode != DiaryTileModes.list,
    );
  }
}
