import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/food_label_ruler_ticks.dart';
import 'package:yamt/core/widgets/visible_value_animation_builder.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';

const Duration _progressAnimationDuration = Duration(milliseconds: 1000);
const Curve _progressAnimationCurve = Curves.easeOut;

/// Tags the eaten share's animated value, so the next day's ruler continues
/// from this one.
const Object _handoffTag = #dailyKcalRuler;

/// Daily kcal ruler: a tick band with a notch at the eaten share, and a bar
/// of four equal quarters of the target that fill in order, each a lighter
/// step of the accent.
class DiaryKcalRuler extends StatelessWidget {
  /// Creates the ruler.
  const new({
    required this.eatenKcal,
    required this.targetKcal,
    this.scaleEndLabel,
    super.key,
  });

  /// Kcal eaten on the selected day.
  final double eatenKcal;

  /// Target kcal of the selected day.
  final double targetKcal;

  /// Label under the right end of the bar. Without it, no scale is shown.
  final String? scaleEndLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final target = math.max<double>(0, targetKcal);
    final eatenRatio = target <= 0 ? 0.0 : (eatenKcal / target).clamp(0.0, 1.0);
    final endLabel = scaleEndLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VisibleValueAnimationBuilder(
          duration: _progressAnimationDuration,
          curve: _progressAnimationCurve,
          value: eatenRatio,
          handoffTag: _handoffTag,
          builder: (context, ratio, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.ink,
                      width: AppFoodLabel.outline,
                    ),
                  ),
                ),
                child: SizedBox(
                  height: AppFoodLabel.rulerTicks,
                  child: FoodLabelRulerTicks(
                    tickColor: colors.ink,
                    markColor: colors.accentText,
                    markFractions: [ratio],
                  ),
                ),
              ),
              _QuarterBar(ratio: ratio),
            ],
          ),
        ),
        if (endLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: AppFoodLabel.outline * 2),
            child: _Scale(endLabel: endLabel),
          ),
      ],
    );
  }
}

/// Bar of four equal quarters under the ruler.
class _QuarterBar extends StatelessWidget {
  const new({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    const alphas = AppFoodLabel.kcalQuarterAlphas;
    final side = BorderSide(color: colors.ink, width: AppFoodLabel.outline);

    return DecoratedBox(
      key: DiaryBalanceCardKeys.dailyProgressTrack,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(left: side, right: side, bottom: side),
      ),
      child: SizedBox(
        height: AppFoodLabel.kcalBar,
        child: Row(
          spacing: AppFoodLabel.outline,
          children: [
            for (var i = 0; i < alphas.length; i++)
              Expanded(
                child: ColoredBox(
                  color: colors.card,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      key: i == 0
                          ? DiaryBalanceCardKeys.dailyProgressEatenFill
                          : null,
                      widthFactor: (ratio * alphas.length - i).clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(
                        color: colors.accent.withValues(alpha: alphas[i]),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "0" under the left end of the bar and [endLabel] under the right end.
class _Scale extends StatelessWidget {
  const new({required this.endLabel});

  final String endLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(fontFamily: AppFonts.mono, color: colors.muted);

    return Row(
      children: [
        Text('0', style: style),
        const Spacer(),
        Text(endLabel, style: style),
      ],
    );
  }
}
