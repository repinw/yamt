import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/visible_value_animation_builder.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';

const Duration _progressAnimationDuration = Duration(milliseconds: 1000);
const Curve _progressAnimationCurve = Curves.easeOut;

/// Tags the eaten segment's animated value, so the next day's bar continues
/// from this one.
const Object _handoffTag = #dailyGoalProgressTrack;

/// Animated daily kcal progress track.
class DiaryDailyGoalProgressTrack extends StatelessWidget {
  /// Creates an animated progress track for daily kcal progress.
  const new({
    required this.height,
    required this.trackColor,
    required this.eatenColor,
    required this.eatenRatio,
    super.key,
  });

  /// Track height.
  final double height;

  /// Background track color.
  final Color trackColor;

  /// Main eaten progress color.
  final Color eatenColor;

  /// Eaten progress ratio from 0 to 1.
  final double eatenRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ClipRRect(
          key: DiaryBalanceCardKeys.dailyProgressTrack,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: trackColor)),
                _EatenProgressSegment(
                  width: width,
                  eatenRatio: eatenRatio,
                  color: eatenColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EatenProgressSegment extends StatelessWidget {
  const new({
    required this.width,
    required this.eatenRatio,
    required this.color,
  });

  final double width;
  final double eatenRatio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return VisibleValueAnimationBuilder(
      duration: _progressAnimationDuration,
      curve: _progressAnimationCurve,
      value: eatenRatio,
      handoffTag: (_handoffTag, #eaten),
      builder: (context, value, child) {
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: width * value,
          child: child!,
        );
      },
      child: DecoratedBox(
        key: DiaryBalanceCardKeys.dailyProgressEatenFill,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
