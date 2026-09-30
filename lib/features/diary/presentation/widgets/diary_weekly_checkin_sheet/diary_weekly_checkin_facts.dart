import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';

/// One number in [DiaryWeeklyCheckInFacts].
typedef DiaryWeeklyCheckInFact = ({
  String kicker,
  String value,
  String? unit,
  String caption,
});

/// Key numbers side by side, between two rules.
class DiaryWeeklyCheckInFacts extends StatelessWidget {
  /// Creates the row of key numbers.
  const new({required this.facts, super.key});

  /// The numbers, left to right.
  final List<DiaryWeeklyCheckInFact> facts;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final fact in facts)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fact.kicker.toUpperCase(),
                      style: context.graphitKickerStyle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text.rich(
                      TextSpan(
                        text: fact.value,
                        children: [
                          if (fact.unit case final unit?)
                            TextSpan(
                              text: ' $unit',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.muted,
                              ),
                            ),
                        ],
                      ),
                      style: context.graphitDisplayStyle(
                        theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      fact.caption,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
