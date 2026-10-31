import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';

/// The visible tile: the card frame around a tile of fixed size, or a wide
/// tile as it builds itself.
class DiaryDashboardTileBody extends StatelessWidget {
  /// Creates the body of [tile] at [placement].
  const new({
    required this.tile,
    required this.placement,
    required this.day,
    super.key,
  });

  /// The tile.
  final DiaryDashboardTile tile;

  /// Its size and mode.
  final DiaryTilePlacement placement;

  /// Normalized diary day.
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final content = tile.builder(
      DiaryTileArgs(day: day, size: placement.size, mode: placement.mode),
    );
    if (placement.size.isWide) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FoodLabelColors.of(context).card,
        borderRadius: BorderRadius.circular(AppDashboard.tileRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDashboard.tilePadding),
        child: SizedBox.expand(child: content),
      ),
    );
  }
}
