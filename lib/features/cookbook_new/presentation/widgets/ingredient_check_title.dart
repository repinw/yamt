import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// The kicker, the question, and an optional hint of an ingredient check
/// step.
class IngredientCheckTitle extends StatelessWidget {
  /// Creates the title.
  const new({
    required this.kicker,
    required this.title,
    this.hint,
    this.onKicker,
    this.kickerKey,
    super.key,
  });

  /// The small caption above.
  final String kicker;

  /// The question.
  final String title;

  /// A hint below.
  final String? hint;

  /// Called by a tap on [kicker], which then shows a menu mark; `null`
  /// leaves the kicker plain.
  final VoidCallback? onKicker;

  /// Key of the kicker's tap target.
  final Key? kickerKey;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hint = this.hint;
    final onKicker = this.onKicker;
    final kickerText = Text(
      kicker.toUpperCase(),
      style: textTheme.labelMedium?.copyWith(
        color: colors.muted,
        letterSpacing: AppGraphit.kickerTracking,
      ),
    );
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
          if (onKicker == null)
            kickerText
          else
            AppInkWell(
              key: kickerKey,
              onTap: onKicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  spacing: AppSpacing.xs,
                  children: [
                    Flexible(child: kickerText),
                    Icon(
                      Icons.expand_more_rounded,
                      size: AppGraphit.chipIcon,
                      color: colors.muted,
                    ),
                  ],
                ),
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
