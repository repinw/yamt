import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Labels under a chart, spread evenly from its left to its right edge.
class ProgressAxisLabels extends StatelessWidget {
  /// Creates the axis labels.
  const new({required this.labels, super.key});

  /// Creates up to five evenly spread date labels for [days], oldest first;
  /// the last one reads [todayLabel].
  factory forDays({
    required List<DateTime> days,
    required String todayLabel,
    required String locale,
  }) {
    final format = days.length > _daysPerYear
        ? DateFormat.yMMM(locale)
        : DateFormat.MMMd(locale);
    return ProgressAxisLabels(
      labels: [
        for (final index in _labelIndexes(days.length))
          if (index == days.length - 1)
            todayLabel
          else
            format.format(days[index]),
      ],
    );
  }

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

const _daysPerYear = 365;

/// Indexes of up to five evenly spread axis labels over [count] days.
List<int> _labelIndexes(int count) {
  if (count <= 1) return [0];
  const parts = 4;
  return {
    for (var part = 0; part <= parts; part++)
      ((count - 1) * part / parts).round(),
  }.toList();
}
