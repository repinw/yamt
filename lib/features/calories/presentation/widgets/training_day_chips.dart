import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// One day in [TrainingDayChips]. A day that is not `isEnabled` keeps its
/// type: it shows faded and ignores taps.
typedef TrainingDayChip = ({
  Key key,
  String label,
  String? caption,
  bool isTraining,
  bool isEnabled,
});

/// A row of seven day chips; a selected chip marks a training day.
class TrainingDayChips extends StatelessWidget {
  /// Creates a row of training day chips.
  const new({required this.days, required this.onToggle, super.key});

  /// The days, in the order they are shown.
  final List<TrainingDayChip> days;

  /// Called with the index of the tapped day.
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, day) in days.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: _DayChip(
                key: day.key,
                label: day.label,
                caption: day.caption,
                isSelected: day.isTraining,
                onTap: day.isEnabled ? () => onToggle(index) : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const new({
    required this.label,
    required this.caption,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String? caption;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = isSelected ? colors.onPrimary : colors.onSurface;
    final caption = this.caption;

    final isEnabled = onTap != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      child: Opacity(
        opacity: isEnabled ? 1 : AppGraphit.disabledOpacity,
        child: AppInkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary
                  : colors.surfaceContainerHighest.withValues(
                      alpha: AppIntroLayout.weekdayIdleOpacity,
                    ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            // Large text shrinks to the chip instead of drawing over its
            // neighbours.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground.withValues(
                          alpha: AppIntroLayout.weekdayCaptionOpacity,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
