import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The steps of a recipe, numbered.
class RecipeStepList extends StatelessWidget {
  /// Creates the list of [steps].
  const new({required this.steps, super.key});

  /// The steps in order.
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: FoodLabelColors.of(context).ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, step) in steps.indexed)
          RecipeStepRow(
            number: index + 1,
            child: Text(step, style: style),
          ),
      ],
    );
  }
}

/// One step of a recipe: its [number], and [child] beside it, which shows
/// the step.
class RecipeStepRow extends StatelessWidget {
  /// Creates the row of the step [number].
  const new({required this.number, required this.child, super.key});

  /// The step's place, counted from 1.
  final int number;

  /// The step's text, or the field that edits it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          SizedBox(
            width: AppGraphit.chipHeight,
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: FoodLabelColors.of(context).ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
