import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_budget_tile.dart';

/// Every tile the diary dashboard offers, in the order of the default
/// layout. A tile added later sorts itself in after the tile before it here.
const diaryDashboardCatalog = <DiaryDashboardTile>[diaryBudgetTile];

/// The catalog tile with [id].
DiaryDashboardTile? diaryDashboardTileById(String id) {
  for (final tile in diaryDashboardCatalog) {
    if (tile.id == id) return tile;
  }
  return null;
}
