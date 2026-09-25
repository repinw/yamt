import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/food_label_ruler_ticks.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_chip.dart';

/// One mark on the amount ruler.
class EatRulerMark {
  /// Creates a mark at [value].
  const new({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onPressed,
  });

  /// Text of the mark.
  final String label;

  /// Position on the ruler, between 0 and the ruler's maximum.
  final double value;

  /// Whether the entered amount matches this mark.
  final bool isSelected;

  /// Called when the mark is tapped.
  final VoidCallback onPressed;
}

/// Ruler slider of the eat page with tick marks, and a row of tappable
/// marks under it.
///
/// The slider snaps to [step]. Near [max] it snaps to [max], so everything
/// in stock can be picked even when [max] is not a multiple of [step].
class EatRuler extends StatelessWidget {
  /// Creates the ruler.
  const new({
    required this.value,
    required this.max,
    required this.step,
    required this.marks,
    required this.onChanged,
    super.key,
  });

  /// Key of the slider.
  static const sliderKey = Key('eat_page_amount_slider');

  /// Slider position.
  final double value;

  /// Slider maximum.
  final double max;

  /// Step the slider snaps to.
  final double step;

  /// Marks under the ruler, shown from the smallest value up.
  final List<EatRulerMark> marks;

  /// Called with the snapped value when the slider moves.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final sorted = [...marks]..sort((a, b) => a.value.compareTo(b.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppFoodLabel.rulerTicks * 2,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: AppFoodLabel.rulerTicks,
                child: FoodLabelRulerTicks(
                  tickColor: colors.ink,
                  markColor: colors.accentText,
                  markFractions: [
                    if (max > 0)
                      for (final mark in sorted) mark.value / max,
                  ],
                ),
              ),
              Positioned.fill(
                child: SliderTheme(
                  data: SliderThemeData(
                    padding: EdgeInsets.zero,
                    trackHeight: AppFoodLabel.outline,
                    activeTrackColor: colors.accent,
                    inactiveTrackColor: colors.rule,
                    thumbColor: colors.accent,
                    overlayColor: colors.accent.withValues(
                      alpha: AppFoodLabel.sliderOverlayAlpha,
                    ),
                  ),
                  child: Slider(
                    key: sliderKey,
                    value: max <= 0 ? 0 : value.clamp(0, max),
                    max: max <= 0 ? 1 : max,
                    onChanged: max <= 0 ? null : (raw) => onChanged(_snap(raw)),
                  ),
                ),
              ),
            ],
          ),
        ),
        // The marks sit in a row under the ruler, so long portion names
        // never overlap. A notch on the ruler shows where each one lies.
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final mark in sorted)
              EatChip(
                label: mark.label,
                isSelected: mark.isSelected,
                onPressed: mark.onPressed,
              ),
          ],
        ),
      ],
    );
  }

  double _snap(double raw) {
    if (max - raw < step / 2) {
      return max;
    }
    return ((raw / step).round() * step).clamp(0, max);
  }
}
