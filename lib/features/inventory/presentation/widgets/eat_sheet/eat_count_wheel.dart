import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_scroll_wheel.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Wheel of the eat page with the number of portions or pieces in half
/// steps, or in whole steps for whole pieces. A tap opens a field for any
/// count, such as 1,3.
class EatCountWheel extends StatelessWidget {
  /// Creates the wheel at [count], with at most [maxCount] on the wheel.
  const new({
    required this.count,
    required this.maxCount,
    required this.onChanged,
    this.label,
    this.wholeOnly = false,
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

  /// What is counted, for the screen reader and the typing field; the
  /// number of portions when null.
  final String? label;

  /// Whether the wheel counts whole pieces only, as for a stock that keeps
  /// no part of a piece. A typed count is rounded to a whole one.
  final bool wholeOnly;

  double get _step => wholeOnly ? 1 : 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final step = _step;
    final steps = math.max(
      (count / step).ceil(),
      math.min((maxCount / step).floor(), AppFoodLabel.countWheelMaxSteps),
    );
    final selected = math.max(0, (count / step).round() - 1);
    return Semantics(
      label: label ?? l10n.eatPageCountLabel,
      value: formatEatCount(l10n, count),
      child: GestureDetector(
        onTap: () => _type(context),
        child: SizedBox(
          width: AppFoodLabel.countWheel,
          height: AppFoodLabel.countWheelHeight,
          child: AppScrollWheel(
            key: wheelKey,
            itemCount: math.max(1, steps),
            selectedIndex: selected,
            labelBuilder: (index) => formatEatCount(
              l10n,
              index == selected ? count : (index + 1) * step,
            ),
            onSelected: (index) => onChanged((index + 1) * step),
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
      builder: (_) =>
          _CountDialog(count: count, label: label, wholeOnly: wholeOnly),
    );
    // A typed part of a whole piece is one piece, never none.
    final picked = wholeOnly && typed != null && typed > 0
        ? math.max(1, typed.roundToDouble()).toDouble()
        : typed;
    if (picked != null && picked > 0) {
      // More than the stock holds becomes all of it.
      onChanged(math.min(picked, maxCount));
    }
  }
}

class _CountDialog extends StatefulWidget {
  const new({
    required this.count,
    required this.label,
    required this.wholeOnly,
  });

  final double count;

  final String? label;

  final bool wholeOnly;

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
      title: Text(widget.label ?? l10n.eatPageCountLabel),
      content: TextField(
        key: EatCountWheel.fieldKey,
        controller: _text,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(
          decimal: !widget.wholeOnly,
        ),
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
