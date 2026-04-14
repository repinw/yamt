import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _InventoryItemSortCriterion { added, eaten, alphabetical, quantity }

class InventoryItemFilterSheet extends StatefulWidget {
  const InventoryItemFilterSheet({
    super.key,
    required this.initialSortMode,
    required this.initialHideFullyConsumedItems,
    required this.enabled,
    required this.onSortModeChanged,
    required this.onHideFullyConsumedItemsChanged,
  });

  final InventoryItemSortMode initialSortMode;
  final bool initialHideFullyConsumedItems;
  final bool enabled;
  final ValueChanged<InventoryItemSortMode> onSortModeChanged;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryFiltersSectionLabel(label: l10n.inventorySortSectionTitle),
        const SizedBox(height: AppSpacing.md),
        InventorySortOptionCard(
          key: const Key('inventory_items_sort_added_option'),
          title: l10n.inventorySortAdded,
          icon: Icons.access_time_rounded,
          isSelected: selectedCriterion == _InventoryItemSortCriterion.added,
          enabled: widget.enabled,
          directionLabel: selectedCriterion == _InventoryItemSortCriterion.added
              ? _sortDirectionLabel(
                  l10n,
                  criterion: _InventoryItemSortCriterion.added,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'inventory_items_sort_added_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sortModeFor(
                _InventoryItemSortCriterion.added,
                ascending: _defaultAscendingForCriterion(
                  _InventoryItemSortCriterion.added,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == _InventoryItemSortCriterion.added
              ? () {
                  _updateSortMode(
                    _sortModeFor(
                      _InventoryItemSortCriterion.added,
                      ascending: !sortAscending,
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        InventorySortOptionCard(
          key: const Key('inventory_items_sort_eaten_option'),
          title: l10n.inventorySortEaten,
          icon: Icons.restaurant_rounded,
          isSelected: selectedCriterion == _InventoryItemSortCriterion.eaten,
          enabled: widget.enabled,
          directionLabel: selectedCriterion == _InventoryItemSortCriterion.eaten
              ? _sortDirectionLabel(
                  l10n,
                  criterion: _InventoryItemSortCriterion.eaten,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'inventory_items_sort_eaten_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sortModeFor(
                _InventoryItemSortCriterion.eaten,
                ascending: _defaultAscendingForCriterion(
                  _InventoryItemSortCriterion.eaten,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == _InventoryItemSortCriterion.eaten
              ? () {
                  _updateSortMode(
                    _sortModeFor(
                      _InventoryItemSortCriterion.eaten,
                      ascending: !sortAscending,
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        InventorySortOptionCard(
          key: const Key('inventory_items_sort_alphabetical_option'),
          title: l10n.inventorySortAlphabetical,
          icon: Icons.sort_by_alpha_rounded,
          isSelected:
              selectedCriterion == _InventoryItemSortCriterion.alphabetical,
          enabled: widget.enabled,
          directionLabel:
              selectedCriterion == _InventoryItemSortCriterion.alphabetical
              ? _sortDirectionLabel(
                  l10n,
                  criterion: _InventoryItemSortCriterion.alphabetical,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'inventory_items_sort_alphabetical_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sortModeFor(
                _InventoryItemSortCriterion.alphabetical,
                ascending: _defaultAscendingForCriterion(
                  _InventoryItemSortCriterion.alphabetical,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == _InventoryItemSortCriterion.alphabetical
              ? () {
                  _updateSortMode(
                    _sortModeFor(
                      _InventoryItemSortCriterion.alphabetical,
                      ascending: !sortAscending,
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        InventorySortOptionCard(
          key: const Key('inventory_items_sort_quantity_option'),
          title: l10n.inventorySortQuantity,
          icon: Icons.inventory_2_rounded,
          isSelected: selectedCriterion == _InventoryItemSortCriterion.quantity,
          enabled: widget.enabled,
          directionLabel:
              selectedCriterion == _InventoryItemSortCriterion.quantity
              ? _sortDirectionLabel(
                  l10n,
                  criterion: _InventoryItemSortCriterion.quantity,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'inventory_items_sort_quantity_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sortModeFor(
                _InventoryItemSortCriterion.quantity,
                ascending: _defaultAscendingForCriterion(
                  _InventoryItemSortCriterion.quantity,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == _InventoryItemSortCriterion.quantity
              ? () {
                  _updateSortMode(
                    _sortModeFor(
                      _InventoryItemSortCriterion.quantity,
                      ascending: !sortAscending,
                    ),
                  );
                }
              : null,
        ),
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
