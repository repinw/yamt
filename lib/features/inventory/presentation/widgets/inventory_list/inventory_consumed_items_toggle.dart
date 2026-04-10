import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryConsumedItemsToggle extends StatelessWidget {
  const InventoryConsumedItemsToggle({
    super.key,
    required this.value,
    required this.enabled,
    required this.l10n,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final AppLocalizations l10n;
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
              l10n.inventoryHideFullyConsumedItemsToggle,
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
