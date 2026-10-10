import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The kicker, the question, and an optional hint of an ingredient check
/// step.
class IngredientCheckTitle extends StatelessWidget {
  /// Creates the title.
  const new({required this.kicker, required this.title, this.hint, super.key});

  /// The small caption above.
  final String kicker;

  /// The question.
  final String title;

  /// A hint below.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hint = this.hint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(
            kicker.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(
              color: colors.muted,
              letterSpacing: AppGraphit.kickerTracking,
            ),
          ),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (hint != null)
            Text(
              hint,
              style: textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
        ],
      ),
    );
  }
}
