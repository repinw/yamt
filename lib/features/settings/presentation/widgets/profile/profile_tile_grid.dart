import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Lays [tiles] out in rows of two with equal heights.
class ProfileTileGrid extends StatelessWidget {
  /// Creates the grid.
  const new({required this.tiles, super.key});

  /// The tiles, left to right and top to bottom.
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AppSpacing.sm,
      children: [
        for (var index = 0; index < tiles.length; index += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                Expanded(child: tiles[index]),
                Expanded(
                  child: index + 1 < tiles.length
                      ? tiles[index + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
