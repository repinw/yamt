import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/horizontal_dial_wheel.dart';

/// Interactive card using horizontal dial wheel for numeric input.
class PersonalInfoSliderCard extends StatelessWidget {
  /// Creates personal info dial card.
  const PersonalInfoSliderCard({
    required this.label,
    required this.unit,
    required this.icon,
    required this.valueText,
    required this.errorText,
    required this.onChanged,
    this.minValue = 16,
    this.maxValue = 100,
    this.defaultValue = 25,
    this.majorInterval = 5,
    super.key,
  });

  /// Field label.
  final String label;

  /// Displayed unit (e.g. 'Jahre', 'cm').
  final String unit;

  /// Leading icon.
  final IconData icon;

  /// Current raw text value.
  final String valueText;

  /// Validation error text.
  final String? errorText;

  /// Callback when value changes.
  final ValueChanged<String> onChanged;

  /// Minimum value.
  final double minValue;

  /// Maximum value.
  final double maxValue;

  /// Fallback default value when valueText is empty.
  final double defaultValue;

  /// Interval between major labeled ticks.
  final int majorInterval;

  double get _currentValue {
    final parsed = double.tryParse(valueText.trim());
    if (parsed == null) {
      return defaultValue.clamp(minValue, maxValue);
    }
    return parsed.clamp(minValue, maxValue);
  }

  void _handleDialChange(int next) {
    onChanged(next.toString());
  }

  void _decrement() {
    final next = (_currentValue - 1).clamp(minValue, maxValue);
    onChanged(next.round().toString());
  }

  void _increment() {
    final next = (_currentValue + 1).clamp(minValue, maxValue);
    onChanged(next.round().toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasError = errorText != null;

    final borderColor = hasError
        ? colorScheme.error
        : colorScheme.outlineVariant;

    final currentInt = _currentValue.round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderHeader(
            icon: icon,
            label: label,
            unit: unit,
            displayValue: valueText.trim().isEmpty ? null : currentInt,
            hasError: hasError,
          ),
          const SizedBox(height: AppSpacing.md),
          _DialControls(
            value: currentInt,
            minValue: minValue.round(),
            maxValue: maxValue.round(),
            majorInterval: majorInterval,
            canDecrement: _currentValue > minValue,
            canIncrement: _currentValue < maxValue,
            onDialChanged: _handleDialChange,
            onDecrement: _decrement,
            onIncrement: _increment,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SliderRangeFooter(
            minValue: minValue.round(),
            maxValue: maxValue.round(),
            unit: unit,
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              errorText!,
              style: TextStyle(
                fontSize: AppFontSizes.bodySmall,
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SliderHeader extends StatelessWidget {
  const _SliderHeader({
    required this.icon,
    required this.label,
    required this.unit,
    required this.displayValue,
    required this.hasError,
  });

  final IconData icon;
  final String label;
  final String unit;
  final int? displayValue;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final valueString = displayValue != null
        ? '$displayValue $unit'
        : '-- $unit';

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: hasError
              ? colorScheme.error
              : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.bodyMedium,
              fontWeight: FontWeight.w600,
              color: hasError ? colorScheme.error : colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            valueString,
            style: TextStyle(
              fontSize: AppFontSizes.titleMedium,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialControls extends StatelessWidget {
  const _DialControls({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.majorInterval,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDialChanged,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int value;
  final int minValue;
  final int maxValue;
  final int majorInterval;
  final bool canDecrement;
  final bool canIncrement;
  final ValueChanged<int> onDialChanged;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.remove),
          onPressed: canDecrement ? onDecrement : null,
          tooltip: 'Minus',
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: HorizontalDialWheel(
            value: value,
            minValue: minValue,
            maxValue: maxValue,
            majorInterval: majorInterval,
            onChanged: onDialChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          onPressed: canIncrement ? onIncrement : null,
          tooltip: 'Plus',
        ),
      ],
    );
  }
}

class _SliderRangeFooter extends StatelessWidget {
  const _SliderRangeFooter({
    required this.minValue,
    required this.maxValue,
    required this.unit,
  });

  final int minValue;
  final int maxValue;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: AppFontSizes.bodySmall,
      color: colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$minValue $unit', style: style),
          Text('$maxValue $unit', style: style),
        ],
      ),
    );
  }
}
