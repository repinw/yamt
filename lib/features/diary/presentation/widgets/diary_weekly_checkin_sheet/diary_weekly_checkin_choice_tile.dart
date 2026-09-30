import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// A tappable row on the tile surface: a leading mark, a title with a
/// detail line, and an optional trailing widget.
class DiaryWeeklyCheckInChoiceTile extends StatelessWidget {
  /// Creates a choice row.
  const new({
    required this.leading,
    required this.title,
    required this.detail,
    required this.onTap,
    this.trailing,
    this.isSelected = false,
    super.key,
  });

  /// Radio mark or icon on the left.
  final Widget leading;

  /// Name of the choice.
  final String title;

  /// Line under the name.
  final String detail;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Value or chevron on the right.
  final Widget? trailing;

  /// Whether the row is the picked choice.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final theme = Theme.of(context);
    final trailing = this.trailing;
    return Semantics(
      selected: isSelected,
      button: true,
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.tile,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? colors.ink : colors.tile,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onTile,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Radio mark of a [DiaryWeeklyCheckInChoiceTile].
class DiaryWeeklyCheckInRadioMark extends StatelessWidget {
  /// Creates a radio mark.
  const new({required this.isSelected, super.key});

  /// Whether the mark is filled.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Icon(
      isSelected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_unchecked_rounded,
      color: isSelected ? colors.ink : colors.muted,
    );
  }
}

/// A number with a caption, right-aligned in a choice row.
class DiaryWeeklyCheckInChoiceValue extends StatelessWidget {
  /// Creates the value of a choice row.
  const new({required this.value, required this.caption, super.key});

  /// The number.
  final String value;

  /// Caption under the number.
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: context.graphitDisplayStyle(theme.textTheme.titleMedium),
        ),
        Text(
          caption,
          style: theme.textTheme.bodySmall?.copyWith(
            color: FoodLabelColors.of(context).muted,
          ),
        ),
      ],
    );
  }
}
