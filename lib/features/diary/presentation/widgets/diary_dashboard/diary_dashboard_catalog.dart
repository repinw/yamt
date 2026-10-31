import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_budget_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_day_type_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_overdue_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_week_tile.dart';

part 'diary_dashboard_catalog.g.dart';

/// Every tile the diary dashboard offers, in the order of the default
/// layout. A tile added later sorts itself in after the tile before it here.
const diaryDashboardCatalog = <DiaryDashboardTile>[
  diaryBudgetTile,
  diaryWeekTile,
  diaryDayTypeTile,
  diaryMealsTile,
  diaryOverdueTile,
];

/// The tiles the dashboard offers: the [diaryDashboardCatalog].
@riverpod
List<DiaryDashboardTile> diaryDashboardTiles(Ref ref) => diaryDashboardCatalog;

/// Finds a tile of the catalog.
extension DiaryDashboardTileLookup on List<DiaryDashboardTile> {
  /// The tile with [id], or null when the catalog has none.
  DiaryDashboardTile? byId(String id) => firstWhereOrNull((t) => t.id == id);
}
