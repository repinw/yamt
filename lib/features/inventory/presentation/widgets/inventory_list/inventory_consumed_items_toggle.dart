import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

class InventoryConsumedItemsToggle extends StatelessWidget {
  const InventoryConsumedItemsToggle({
    super.key,
    required this.value,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: enabled
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}
