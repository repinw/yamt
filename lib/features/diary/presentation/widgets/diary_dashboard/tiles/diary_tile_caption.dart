import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// One muted line of a tile: an optional icon and a short text that ends
/// with an ellipsis when the tile is narrow.
class DiaryTileCaption extends StatelessWidget {
  /// Creates the caption [text].
  const new(this.text, {this.icon, this.color, super.key});

  /// The text.
  final String text;

  /// Icon before the text.
  final IconData? icon;

  /// Color of icon and text; muted by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? FoodLabelColors.of(context).muted;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: AppFonts.geist, color: color);

    return Row(
      spacing: AppDashboard.captionGap,
      children: [
        if (icon case final icon?)
          Icon(icon, size: AppDashboard.captionIcon, color: color),
        Flexible(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
