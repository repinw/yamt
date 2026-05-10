import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _InventoryItemSortCriterion { added, eaten, alphabetical, quantity }

/// Defines inventory item filter sheet.
class InventoryItemFilterSheet extends StatefulWidget {
  /// The inventory item filter sheet.
  const InventoryItemFilterSheet({
    required this.initialSortMode,
    required this.initialHideFullyConsumedItems,
    required this.enabled,
    required this.onSortModeChanged,
    required this.onHideFullyConsumedItemsChanged,
    super.key,
  });

  /// The initial sort mode.
  final InventoryItemSortMode initialSortMode;

  /// The initial hide fully consumed items.
  final bool initialHideFullyConsumedItems;

  /// The enabled.
  final bool enabled;

  /// The on sort mode changed.
  final ValueChanged<InventoryItemSortMode> onSortModeChanged;

  /// The on hide fully consumed items changed.
  final ValueChanged<bool> onHideFullyConsumedItemsChanged;

  @override
  State<InventoryItemFilterSheet> createState() =>
      _InventoryItemFilterSheetState();
}

class _InventoryItemFilterSheetState extends State<InventoryItemFilterSheet> {
  late InventoryItemSortMode _sortMode;
  late bool _hideFullyConsumedItems;

  @override
  void initState() {
    super.initState();
    _sortMode = widget.initialSortMode;
    _hideFullyConsumedItems = widget.initialHideFullyConsumedItems;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCriterion = _sortCriterionFor(_sortMode);
    final sortAscending = _isSortAscending(_sortMode);
    final sortOptions = <_InventoryItemSortOptionConfig>[
      _InventoryItemSortOptionConfig(
        criterion: _InventoryItemSortCriterion.added,
        optionKey: const Key('inventory_items_sort_added_option'),
        directionButtonKey: const Key(
          'inventory_items_sort_added_direction_button',
        ),
        title: l10n.inventorySortAdded,
        icon: Icons.access_time_rounded,
      ),
      _InventoryItemSortOptionConfig(
        criterion: _InventoryItemSortCriterion.eaten,
        optionKey: const Key('inventory_items_sort_eaten_option'),
        directionButtonKey: const Key(
          'inventory_items_sort_eaten_direction_button',
        ),
        title: l10n.inventorySortEaten,
        icon: Icons.restaurant_rounded,
      ),
      _InventoryItemSortOptionConfig(
        criterion: _InventoryItemSortCriterion.alphabetical,
        optionKey: const Key('inventory_items_sort_alphabetical_option'),
        directionButtonKey: const Key(
          'inventory_items_sort_alphabetical_direction_button',
        ),
        title: l10n.inventorySortAlphabetical,
        icon: Icons.sort_by_alpha_rounded,
      ),
      _InventoryItemSortOptionConfig(
        criterion: _InventoryItemSortCriterion.quantity,
        optionKey: const Key('inventory_items_sort_quantity_option'),
        directionButtonKey: const Key(
          'inventory_items_sort_quantity_direction_button',
        ),
        title: l10n.inventorySortQuantity,
        icon: Icons.inventory_2_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryFiltersSectionLabel(label: l10n.inventorySortSectionTitle),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < sortOptions.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _buildSortOptionCard(
            l10n: l10n,
            config: sortOptions[index],
            selectedCriterion: selectedCriterion,
            sortAscending: sortAscending,
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        InventoryFiltersSectionLabel(label: l10n.inventoryFilterSectionTitle),
        const SizedBox(height: AppSpacing.md),
        InventoryFilterToggle(
          key: const Key('inventory_items_hide_consumed_toggle'),
          value: _hideFullyConsumedItems,
          enabled: widget.enabled,
          label: l10n.inventoryHideConsumedFilterTitle,
          description: l10n.inventoryHideConsumedFilterSubtitle,
          icon: _hideFullyConsumedItems
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          onChanged: _updateHideFullyConsumedItems,
        ),
      ],
    );
  }

  Widget _buildSortOptionCard({
    required AppLocalizations l10n,
    required _InventoryItemSortOptionConfig config,
    required _InventoryItemSortCriterion selectedCriterion,
    required bool sortAscending,
  }) {
    final isSelected = selectedCriterion == config.criterion;

    return InventorySortOptionCard(
      key: config.optionKey,
      title: config.title,
      icon: config.icon,
      isSelected: isSelected,
      enabled: widget.enabled,
      directionLabel: isSelected
          ? _sortDirectionLabel(
              l10n,
              criterion: config.criterion,
              ascending: sortAscending,
            )
          : null,
      directionButtonKey: config.directionButtonKey,
      sortDirectionAscending: sortAscending,
      onSelect: () {
        _updateSortMode(
          _sortModeFor(
            config.criterion,
            ascending: _defaultAscendingForCriterion(config.criterion),
          ),
        );
      },
      onToggleDirection: isSelected
          ? () {
              _updateSortMode(
                _sortModeFor(config.criterion, ascending: !sortAscending),
              );
            }
          : null,
    );
  }

  void _updateSortMode(InventoryItemSortMode nextSortMode) {
    setState(() {
      _sortMode = nextSortMode;
    });
    widget.onSortModeChanged(nextSortMode);
  }

  void _updateHideFullyConsumedItems(bool value) {
    setState(() {
      _hideFullyConsumedItems = value;
    });
    widget.onHideFullyConsumedItemsChanged(value);
  }

  _InventoryItemSortCriterion _sortCriterionFor(
    InventoryItemSortMode sortMode,
  ) {
    return switch (sortMode) {
      InventoryItemSortMode.recentlyAddedDescending ||
      InventoryItemSortMode.recentlyAddedAscending =>
        _InventoryItemSortCriterion.added,
      InventoryItemSortMode.recentlyEatenDescending ||
      InventoryItemSortMode.recentlyEatenAscending =>
        _InventoryItemSortCriterion.eaten,
      InventoryItemSortMode.alphabeticalAscending ||
      InventoryItemSortMode.alphabeticalDescending =>
        _InventoryItemSortCriterion.alphabetical,
      InventoryItemSortMode.availableAmountAscending ||
      InventoryItemSortMode.availableAmountDescending =>
        _InventoryItemSortCriterion.quantity,
    };
  }

  bool _isSortAscending(InventoryItemSortMode sortMode) {
    return switch (sortMode) {
      InventoryItemSortMode.recentlyAddedAscending ||
      InventoryItemSortMode.recentlyEatenAscending ||
      InventoryItemSortMode.alphabeticalAscending ||
      InventoryItemSortMode.availableAmountAscending => true,
      InventoryItemSortMode.recentlyAddedDescending ||
      InventoryItemSortMode.recentlyEatenDescending ||
      InventoryItemSortMode.alphabeticalDescending ||
      InventoryItemSortMode.availableAmountDescending => false,
    };
  }

  bool _defaultAscendingForCriterion(_InventoryItemSortCriterion criterion) {
    return switch (criterion) {
      _InventoryItemSortCriterion.added ||
      _InventoryItemSortCriterion.eaten => false,
      _InventoryItemSortCriterion.alphabetical ||
      _InventoryItemSortCriterion.quantity => true,
    };
  }

  InventoryItemSortMode _sortModeFor(
    _InventoryItemSortCriterion criterion, {
    required bool ascending,
  }) {
    return switch ((criterion, ascending)) {
      (_InventoryItemSortCriterion.added, true) =>
        InventoryItemSortMode.recentlyAddedAscending,
      (_InventoryItemSortCriterion.added, false) =>
        InventoryItemSortMode.recentlyAddedDescending,
      (_InventoryItemSortCriterion.eaten, true) =>
        InventoryItemSortMode.recentlyEatenAscending,
      (_InventoryItemSortCriterion.eaten, false) =>
        InventoryItemSortMode.recentlyEatenDescending,
      (_InventoryItemSortCriterion.alphabetical, true) =>
        InventoryItemSortMode.alphabeticalAscending,
      (_InventoryItemSortCriterion.alphabetical, false) =>
        InventoryItemSortMode.alphabeticalDescending,
      (_InventoryItemSortCriterion.quantity, true) =>
        InventoryItemSortMode.availableAmountAscending,
      (_InventoryItemSortCriterion.quantity, false) =>
        InventoryItemSortMode.availableAmountDescending,
    };
  }

  String _sortDirectionLabel(
    AppLocalizations l10n, {
    required _InventoryItemSortCriterion criterion,
    required bool ascending,
  }) {
    if (criterion == _InventoryItemSortCriterion.alphabetical) {
      return ascending
          ? l10n.inventorySortDirectionAlphaAscending
          : l10n.inventorySortDirectionAlphaDescending;
    }

    return ascending
        ? l10n.inventorySortDirectionAscending
        : l10n.inventorySortDirectionDescending;
  }
}

class _InventoryItemSortOptionConfig {
  const _InventoryItemSortOptionConfig({
    required this.criterion,
    required this.optionKey,
    required this.directionButtonKey,
    required this.title,
    required this.icon,
  });

  final _InventoryItemSortCriterion criterion;
  final Key optionKey;
  final Key directionButtonKey;
  final String title;
  final IconData icon;
}
