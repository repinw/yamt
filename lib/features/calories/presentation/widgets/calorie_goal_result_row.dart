import 'package:material_ui/material_ui.dart';

/// One label and value line of the calorie goal calculator results.
class CalorieGoalResultRow extends StatelessWidget {
  /// Creates a result row showing [label] and [value].
  const new({required this.label, required this.value, super.key});

  /// What the value is.
  final String label;

  /// The formatted value.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
