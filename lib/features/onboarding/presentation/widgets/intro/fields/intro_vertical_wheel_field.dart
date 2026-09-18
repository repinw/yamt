import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_field_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_wheel.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_wheel_selection_band.dart';

/// Vertical scroll wheel for a numeric onboarding value.
///
/// The wheel always shows a plausible value, but it only reports one once the
/// user has scrolled, so an untouched field still fails validation.
class IntroVerticalWheelField extends StatelessWidget {
  /// Creates a vertical wheel field.
  const new({
    required this.label,
    required this.unit,
    required this.icon,
    required this.valueText,
    required this.errorText,
    required this.onChanged,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    this.step = 1,
    this.expand = false,
    super.key,
  });

  /// Field label.
  final String label;

  /// Unit shown next to every value.
  final String unit;

  /// Leading icon.
  final IconData icon;

  /// Current raw text value, empty while nothing is picked.
  final String valueText;

  /// Validation error text.
  final String? errorText;

  /// Called with the formatted value whenever the wheel settles on a new item.
  final ValueChanged<String> onChanged;

  /// Smallest selectable value.
  final double minValue;

  /// Largest selectable value.
  final double maxValue;

  /// Value the wheel starts on while [valueText] is empty.
  final double defaultValue;

  /// Distance between two wheel items.
  final double step;

  /// Whether the picker fills the height the parent gives it.
  final bool expand;

  int get _itemCount => ((maxValue - minValue) / step).round() + 1;

  double get _currentValue {
    final parsed = double.tryParse(valueText.trim().replaceAll(',', '.'));
    return (parsed ?? defaultValue).clamp(minValue, maxValue);
  }

  int get _currentIndex =>
      ((_currentValue - minValue) / step).round().clamp(0, _itemCount - 1);

  double _valueAt(int index) => minValue + index * step;

  int get _fractionDigits {
    if (step >= 1) {
      return 0;
    }
    return step >= 0.1 ? 1 : 2;
  }

  String _format(double value) {
    return _fractionDigits == 0
        ? value.round().toString()
        : value.toStringAsFixed(_fractionDigits);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = valueText.trim().isNotEmpty;

    return IntroFieldCard(
      icon: icon,
      label: label,
      valueText: hasValue
          ? '${_format(_currentValue)} $unit'
          : '$introFieldEmptyValue $unit',
      errorText: errorText,
      expand: expand,
      child: IntroWheelSelectionBand(
        child: IntroWheel(
          itemCount: _itemCount,
          selectedIndex: _currentIndex,
          labelBuilder: (index) => '${_format(_valueAt(index))} $unit',
          onSelected: (index) => onChanged(_format(_valueAt(index))),
        ),
      ),
    );
  }
}
