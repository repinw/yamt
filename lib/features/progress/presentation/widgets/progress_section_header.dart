import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Kicker style of the Fortschritt tab: a small, tracked, muted caption.
TextStyle? progressKickerStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    color: FoodLabelColors.of(context).muted,
    letterSpacing: AppGraphit.kickerTracking,
  );
}

/// Head of a Fortschritt section: a kicker, a large number with its unit on
/// the left, and up to three short lines on the right.
class ProgressSectionHeader extends StatelessWidget {
  /// Creates a section head.
  const new({
    required this.kicker,
    required this.value,
    required this.unit,
    this.lines = const <String>[],
    this.caption,
    this.isMain = false,
    super.key,
  });

  /// Caption above the number; shown in upper case.
  final String kicker;

  /// The large number.
  final String value;

  /// Unit after the number.
  final String unit;

  /// Short lines on the right; the first is bold, the others muted.
  final List<String> lines;

  /// Short muted text under the number.
  final String? caption;

  /// Whether this is the main number of the tab, drawn larger and in lime.
  final bool isMain;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final valueColor = isMain ? colors.accentText : colors.ink;
    final valueStyle =
        (isMain ? textTheme.displayMedium : textTheme.headlineLarge)?.copyWith(
          color: valueColor,
          fontWeight: FontWeight.w800,
          height: AppGraphit.displayLineHeight,
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kicker.toUpperCase(), style: progressKickerStyle(context)),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: value, style: valueStyle),
                      TextSpan(
                        text: ' $unit',
                        style: textTheme.bodyMedium?.copyWith(
                          color: valueColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (caption case final caption?)
                Text(
                  caption,
                  style: textTheme.labelSmall?.copyWith(color: colors.muted),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (index, line) in lines.indexed)
                Text(
                  line,
                  textAlign: TextAlign.end,
                  style: textTheme.bodySmall?.copyWith(
                    color: index == 0 ? colors.ink : colors.muted,
                    fontWeight: index == 0 ? FontWeight.w700 : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
