import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_scroll_wheel.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Wheel of the eat page with the number of portions in half steps. A tap
/// opens a field for any count, such as 1,3.
class EatCountWheel extends StatelessWidget {
  /// Creates the wheel at [count], with at most [maxCount] on the wheel.
  const new({
    required this.count,
    required this.maxCount,
    required this.onChanged,
    super.key,
  });

  /// Key of the wheel.
  static const wheelKey = Key('eat_page_count_wheel');

  /// Key of the field that types a count.
  static const fieldKey = Key('eat_page_count_field');

  /// Key of the button that takes the typed count.
  static const doneKey = Key('eat_page_count_done');

  /// Current count.
  final double count;

  /// Largest count the stock allows.
  final double maxCount;

  /// Called with a new count.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final halves = math.max(
      (count * 2).ceil(),
      math.min((maxCount * 2).floor(), AppFoodLabel.countWheelMaxHalves),
    );
    final selected = math.max(0, (count * 2).round() - 1);
    return Semantics(
      label: l10n.eatPageCountLabel,
      value: formatEatCount(l10n, count),
      child: GestureDetector(
        onTap: () => _type(context),
        child: SizedBox(
          width: AppFoodLabel.countWheel,
          height: AppFoodLabel.countWheelHeight,
          child: AppScrollWheel(
            key: wheelKey,
            itemCount: math.max(1, halves),
            selectedIndex: selected,
            labelBuilder: (index) => formatEatCount(
              l10n,
              index == selected ? count : (index + 1) / 2,
            ),
            onSelected: (index) => onChanged((index + 1) / 2),
            itemExtent: AppFoodLabel.countWheelItem,
            textStyle: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: colors.ink),
          ),
        ),
      ),
    );
  }

  Future<void> _type(BuildContext context) async {
    final typed = await showDialog<double>(
      context: context,
      builder: (_) => _CountDialog(count: count),
    );
    if (typed != null && typed > 0) {
      // More than the stock holds becomes all of it.
      onChanged(math.min(typed, maxCount));
    }
  }
}

class _CountDialog extends StatefulWidget {
  const new({required this.count});

  final double count;

  @override
  State<_CountDialog> createState() => _CountDialogState();
}

class _CountDialogState extends State<_CountDialog> {
  late final _text = TextEditingController(
    text: formatEatCount(AppLocalizations.of(context)!, widget.count),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _done() {
    Navigator.of(context).pop(parsePositiveDecimalInput(_text.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.eatPageCountLabel),
      content: TextField(
        key: EatCountWheel.fieldKey,
        controller: _text,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onSubmitted: (_) => _done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          key: EatCountWheel.doneKey,
          onPressed: _done,
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}
