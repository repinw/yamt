import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Small tracked caption above a Kochbuch section, with an optional caption
/// on the right.
class CookbookSectionTitle extends StatelessWidget {
  /// Creates the title with [title] and an optional [caption].
  const new({required this.title, this.caption, super.key});

  /// Name of the section; shown in upper case.
  final String title;

  /// Short hint on the right; shown in upper case.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: FoodLabelColors.of(context).muted,
      fontWeight: FontWeight.w700,
      letterSpacing: AppGraphit.kickerTracking,
    );
    return Row(
      children: [
        Expanded(child: Text(title.toUpperCase(), style: style)),
        if (caption case final caption?)
          Flexible(
            child: Text(
              caption.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
      ],
    );
  }
}
