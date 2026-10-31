import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The muted dash of a tile that has no value yet, such as before the first
/// weighing.
class DiaryTileNoValue extends StatelessWidget {
  /// Creates the dash.
  const new({this.alignment = AlignmentDirectional.centerStart, super.key});

  /// Where the dash sits in its space.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return DiaryTileNumber(
      AppLocalizations.of(context)!.profileNoValue,
      color: FoodLabelColors.of(context).muted,
      alignment: alignment,
    );
  }
}
