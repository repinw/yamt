import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Minus, the count, and plus; the count never goes below one.
class PortionStepper extends StatelessWidget {
  /// Creates the stepper for [count].
  const new({
    required this.count,
    required this.onChanged,
    required this.lessTooltip,
    required this.moreTooltip,
    this.countKey,
    this.moreKey,
    super.key,
  });

  /// The current count.
  final int count;

  /// Called with the new count.
  final ValueChanged<int> onChanged;

  /// Tooltip of the minus button.
  final String lessTooltip;

  /// Tooltip of the plus button.
  final String moreTooltip;

  /// Key of the count text.
  final Key? countKey;

  /// Key of the plus button.
  final Key? moreKey;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: lessTooltip,
          onPressed: count > 1 ? () => onChanged(count - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppGraphit.badge),
          child: Text(
            '$count',
            key: countKey,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton.filledTonal(
          key: moreKey,
          tooltip: moreTooltip,
          onPressed: () => onChanged(count + 1),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
