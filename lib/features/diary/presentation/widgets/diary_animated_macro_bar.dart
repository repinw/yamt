import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/visible_value_animation_builder.dart';
import 'package:yamt/features/diary/domain/diary_macro_overage.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';

/// Segmented macro bar that fills up to [current] like the kcal bar.
///
/// Stripes for the overage appear once the filling passes [target]. Changes
/// made while the diary is covered play once it is visible again.
class DiaryAnimatedMacroBar extends StatelessWidget {
  /// Creates the animated macro bar.
  const new({
    required this.current,
    required this.target,
    required this.color,
    required this.trackColor,
    required this.isDark,
    required this.handoffTag,
    this.height = 6.0,
    super.key,
  });

  /// Amount eaten.
  final double current;

  /// Target amount.
  final double target;

  /// Accent color of the macro.
  final Color color;

  /// Track background color.
  final Color trackColor;

  /// Whether the current theme is dark mode.
  final bool isDark;

  /// Height of each segment.
  final double height;

  /// Identifies this macro's bar, so the next day's bar continues from it.
  final Object handoffTag;

  @override
  Widget build(BuildContext context) {
    return VisibleValueAnimationBuilder(
      duration: diaryBalanceProgressAnimationDuration,
      curve: diaryBalanceProgressAnimationCurve,
      value: current,
      handoffTag: handoffTag,
      builder: (context, animatedCurrent, _) => DiarySegmentedProgressBar(
        progress: target <= 0 ? 0 : animatedCurrent / target,
        overflow: diaryMacroOverageShare(
          current: animatedCurrent,
          target: target,
        ),
        color: color,
        trackColor: trackColor,
        isDark: isDark,
        height: height,
      ),
    );
  }
}
