import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// One entry of a [ProgressLegend]: a swatch and its word.
class ProgressLegendItem {
  /// Creates a legend entry.
  const new({required this.swatch, required this.label});

  /// Square swatch in one color.
  factory color(Color color, String label) {
    return ProgressLegendItem(
      swatch: SizedBox.square(
        dimension: AppProgress.legendSwatch,
        child: ColoredBox(color: color),
      ),
      label: label,
    );
  }

  /// The mark drawn before the word.
  final Widget swatch;

  /// The word.
  final String label;
}

/// A row of legend entries under a chart, with an optional note at the end.
class ProgressLegend extends StatelessWidget {
  /// Creates a legend.
  const new({required this.items, this.note, super.key});

  /// The entries.
  final List<ProgressLegendItem> items;

  /// Short note after the entries.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: FoodLabelColors.of(context).muted);
    final note = this.note;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              item.swatch,
              const SizedBox(width: AppSpacing.xs),
              Text(item.label, style: style),
            ],
          ),
        if (note != null) Text(note, style: style),
      ],
    );
  }
}
