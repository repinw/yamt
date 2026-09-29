import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Labels under a chart, spread evenly from its left to its right edge.
class ProgressAxisLabels extends StatelessWidget {
  /// Creates the axis labels.
  const new({required this.labels, super.key});

  /// The labels, from left to right.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: FoodLabelColors.of(context).muted);
    final last = labels.length - 1;
    return Row(
      children: [
        for (final (index, label) in labels.indexed)
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
              textAlign: index == 0
                  ? TextAlign.start
                  : index == last
                  ? TextAlign.end
                  : TextAlign.center,
            ),
          ),
      ],
    );
  }
}
