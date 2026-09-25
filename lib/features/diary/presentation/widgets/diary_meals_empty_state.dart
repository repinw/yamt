import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/food_label_dashed_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Short hint between dashed lines on a day without logged food. It points
/// to the quick-eat dock at the bottom.
class DiaryMealsEmptyState extends StatelessWidget {
  /// Creates the empty state.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: DiaryMealsSectionKeys.emptyState,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FoodLabelDashedLine(color: colors.rule),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            spacing: AppSpacing.xs,
            children: [
              Text(
                l10n.diaryMealsEmptyTitle,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              Text(
                l10n.diaryMealsEmptyHint,
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  fontFamily: AppFonts.mono,
                  color: colors.muted,
                ),
              ),
            ],
          ),
        ),
        FoodLabelDashedLine(color: colors.rule),
      ],
    );
  }
}
