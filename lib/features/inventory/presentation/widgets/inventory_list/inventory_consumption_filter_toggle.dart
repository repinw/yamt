import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _InventoryConsumptionFilter { consumed, notConsumed }

class InventoryConsumptionFilterToggle extends StatelessWidget {
  const InventoryConsumptionFilterToggle({
    super.key,
    required this.showConsumed,
    required this.showNotConsumed,
    required this.l10n,
    required this.onShowConsumedChanged,
    required this.onShowNotConsumedChanged,
  });

  final bool showConsumed;
  final bool showNotConsumed;
  final AppLocalizations l10n;
  final ValueChanged<bool> onShowConsumedChanged;
  final ValueChanged<bool> onShowNotConsumedChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_InventoryConsumptionFilter>(
      expandedInsets: AppInsets.zero,
      multiSelectionEnabled: true,
      emptySelectionAllowed: false,
      showSelectedIcon: false,
      selected: <_InventoryConsumptionFilter>{
        if (showConsumed) _InventoryConsumptionFilter.consumed,
        if (showNotConsumed) _InventoryConsumptionFilter.notConsumed,
      },
      onSelectionChanged: (selection) {
        final nextShowConsumed = selection.contains(
          _InventoryConsumptionFilter.consumed,
        );
        final nextShowNotConsumed = selection.contains(
          _InventoryConsumptionFilter.notConsumed,
        );

        if (showConsumed != nextShowConsumed) {
          onShowConsumedChanged(nextShowConsumed);
        }
        if (showNotConsumed != nextShowNotConsumed) {
          onShowNotConsumedChanged(nextShowNotConsumed);
        }
      },
      segments: [
        ButtonSegment<_InventoryConsumptionFilter>(
          value: _InventoryConsumptionFilter.consumed,
          label: Text(l10n.inventoryFilterConsumed),
        ),
        ButtonSegment<_InventoryConsumptionFilter>(
          value: _InventoryConsumptionFilter.notConsumed,
          label: Text(l10n.inventoryFilterNotConsumed),
        ),
      ],
    );
  }
}
