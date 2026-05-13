import 'package:flutter/material.dart';

/// Label shown under the Burn Week progress scale.
class DiaryBalanceScaleLabel extends StatelessWidget {
  /// Creates a scale label.
  const DiaryBalanceScaleLabel(this.label, {super.key});

  /// Label text.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
