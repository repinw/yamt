import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The title above a group of lines of "Zuweisen", in capitals.
class KochmodusGroupTitle extends StatelessWidget {
  /// Creates the title [title].
  const new({required this.title, super.key});

  /// The title, such as "Offen · 2".
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: FoodLabelColors.of(context).muted,
        letterSpacing: AppGraphit.kickerTracking,
      ),
    ),
  );
}
