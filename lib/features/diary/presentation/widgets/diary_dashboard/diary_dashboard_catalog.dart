import 'package:collection/collection.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_budget_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_day_type_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_kcal_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macros_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_overdue_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tdee_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_weight_tile.dart';

/// Every tile the diary dashboard offers, in the order of
/// [diaryDashboardTileSpecs].
const diaryDashboardCatalog = <DiaryDashboardTile>[
  diaryBudgetTile,
  diaryKcalTile,
  diaryMacrosTile,
  diaryWeightTile,
  diaryTdeeTile,
  diaryDayTypeTile,
  diaryMealsTile,
  diaryOverdueTile,
];

/// Finds a tile of the catalog.
extension DiaryDashboardTileLookup on List<DiaryDashboardTile> {
  /// The tile with [id], or null when the catalog has none.
  DiaryDashboardTile? byId(String id) => firstWhereOrNull((t) => t.id == id);
}
