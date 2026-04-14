import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _PreparedMealSortCriterion { added, eaten, alphabetical, quantity }

class PreparedMealFilterSheet extends StatefulWidget {
  const PreparedMealFilterSheet({
    super.key,
    required this.initialCompletionFilter,
    required this.initialConsumptionFilter,
    required this.initialSortMode,
    required this.enabled,
    required this.onCompletionFilterChanged,
    required this.onConsumptionFilterChanged,
    required this.onSortModeChanged,
  });

  final PreparedMealCompletionFilter initialCompletionFilter;
  final PreparedMealConsumptionFilter initialConsumptionFilter;
  final PreparedMealSortMode initialSortMode;
  final bool enabled;
  final ValueChanged<PreparedMealCompletionFilter> onCompletionFilterChanged;
  final ValueChanged<PreparedMealConsumptionFilter> onConsumptionFilterChanged;
  final ValueChanged<PreparedMealSortMode> onSortModeChanged;

  @override
  State<PreparedMealFilterSheet> createState() =>
      _PreparedMealFilterSheetState();
}

class _PreparedMealFilterSheetState extends State<PreparedMealFilterSheet> {
  late PreparedMealCompletionFilter _completionFilter;
  late PreparedMealConsumptionFilter _consumptionFilter;
  late PreparedMealSortMode _sortMode;

  @override
  void initState() {
    super.initState();
    _completionFilter = widget.initialCompletionFilter;
    _consumptionFilter = widget.initialConsumptionFilter;
    _sortMode = widget.initialSortMode;
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
          key: const Key('prepared_meals_sort_added_option'),
          title: l10n.inventorySortAdded,
          icon: Icons.access_time_rounded,
          isSelected: selectedCriterion == _PreparedMealSortCriterion.added,
          enabled: widget.enabled,
          directionLabel: selectedCriterion == _PreparedMealSortCriterion.added
              ? _sortDirectionLabel(
                  l10n,
                  criterion: _PreparedMealSortCriterion.added,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'prepared_meals_sort_added_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sortModeFor(
                _PreparedMealSortCriterion.added,
                ascending: _defaultAscendingForCriterion(
                  _PreparedMealSortCriterion.added,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == _PreparedMealSortCriterion.added
              ? () {
                  _updateSortMode(
                    _sortModeFor(
                      _PreparedMealSortCriterion.added,
                      ascending: !sortAscending,
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        InventorySortOptionCard(
          key: const Key('prepared_meals_sort_eaten_option'),
          title: l10n.inventorySortEaten,
          icon: Icons.restaurant_rounded,
          isSelected: selectedCriterion == _PreparedMealSortCriterion.eaten,
          enabled: widget.enabled,
          directionLabel: selectedCriterion == _PreparedMealSortCriterion.eaten
              ? _sortDirectionLabel(
                  l10n,
                  criterion: _PreparedMealSortCriterion.eaten,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'prepared_meals_sort_eaten_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sortModeFor(
                _PreparedMealSortCriterion.eaten,
                ascending: _defaultAscendingForCriterion(
                  _PreparedMealSortCriterion.eaten,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == _PreparedMealSortCriterion.eaten
              ? () {
                  _updateSortMode(
                    _sortModeFor(
                      _PreparedMealSortCriterion.eaten,
                      ascending: !sortAscending,
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        InventorySortOptionCard(
          key: const Key('prepared_meals_sort_alphabetical_option'),
          title: l10n.inventorySortAlphabetical,
          icon: Icons.sort_by_alpha_rounded,
          isSelected:
              selectedCriterion == _PreparedMealSortCriterion.alphabetical,
          enabled: widget.enabled,
          directionLabel:
              selectedCriterion == _PreparedMealSortCriterion.alphabetical
              ? _sortDirectionLabel(
                  l10n,
                  criterion: _PreparedMealSortCriterion.alphabetical,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'prepared_meals_sort_alphabetical_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sortModeFor(
                _PreparedMealSortCriterion.alphabetical,
                ascending: _defaultAscendingForCriterion(
                  _PreparedMealSortCriterion.alphabetical,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == _PreparedMealSortCriterion.alphabetical
              ? () {
                  _updateSortMode(
                    _sortModeFor(
                      _PreparedMealSortCriterion.alphabetical,
                      ascending: !sortAscending,
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        InventorySortOptionCard(
          key: const Key('prepared_meals_sort_quantity_option'),
          title: l10n.inventorySortQuantity,
          icon: Icons.inventory_2_rounded,
          isSelected: selectedCriterion == _PreparedMealSortCriterion.quantity,
          enabled: widget.enabled,
          directionLabel:
              selectedCriterion == _PreparedMealSortCriterion.quantity
              ? _sortDirectionLabel(
                  l10n,
                  criterion: _PreparedMealSortCriterion.quantity,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'prepared_meals_sort_quantity_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sortModeFor(
                _PreparedMealSortCriterion.quantity,
                ascending: _defaultAscendingForCriterion(
                  _PreparedMealSortCriterion.quantity,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == _PreparedMealSortCriterion.quantity
              ? () {
                  _updateSortMode(
                    _sortModeFor(
                      _PreparedMealSortCriterion.quantity,
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
          key: const Key('prepared_meals_ready_only_toggle'),
          value: _completionFilter == PreparedMealCompletionFilter.readyOnly,
          enabled: widget.enabled,
          label: l10n.preparedMealShowReadyOnlyToggle,
          icon: Icons.check_circle_outline_rounded,
          onChanged: (isEnabled) {
            _updateCompletionFilter(
              isEnabled
                  ? PreparedMealCompletionFilter.readyOnly
                  : PreparedMealCompletionFilter.all,
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        InventoryFilterToggle(
          key: const Key('prepared_meals_incomplete_only_toggle'),
          value:
              _completionFilter == PreparedMealCompletionFilter.incompleteOnly,
          enabled: widget.enabled,
          label: l10n.preparedMealShowIncompleteOnlyToggle,
          icon: Icons.rule_folder_outlined,
          onChanged: (isEnabled) {
            _updateCompletionFilter(
              isEnabled
                  ? PreparedMealCompletionFilter.incompleteOnly
                  : PreparedMealCompletionFilter.all,
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        InventoryFilterToggle(
          key: const Key('prepared_meals_depleted_only_toggle'),
          value:
              _consumptionFilter == PreparedMealConsumptionFilter.depletedOnly,
          enabled: widget.enabled,
          label: l10n.preparedMealShowDepletedOnlyToggle,
          icon: Icons.remove_circle_outline_rounded,
          onChanged: (isEnabled) {
            _updateConsumptionFilter(
              isEnabled
                  ? PreparedMealConsumptionFilter.depletedOnly
                  : PreparedMealConsumptionFilter.all,
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        InventoryFilterToggle(
          key: const Key('prepared_meals_hide_consumed_toggle'),
          value:
              _consumptionFilter == PreparedMealConsumptionFilter.hideConsumed,
          enabled: widget.enabled,
          label: l10n.preparedMealHideFullyConsumedItemsToggle,
          icon: Icons.visibility_off_rounded,
          onChanged: (isEnabled) {
            _updateConsumptionFilter(
              isEnabled
                  ? PreparedMealConsumptionFilter.hideConsumed
                  : PreparedMealConsumptionFilter.all,
            );
          },
        ),
      ],
    );
  }

  void _updateCompletionFilter(PreparedMealCompletionFilter nextFilter) {
    setState(() {
      _completionFilter = nextFilter;
    });
    widget.onCompletionFilterChanged(nextFilter);
  }

  void _updateConsumptionFilter(PreparedMealConsumptionFilter nextFilter) {
    setState(() {
      _consumptionFilter = nextFilter;
    });
    widget.onConsumptionFilterChanged(nextFilter);
  }

  void _updateSortMode(PreparedMealSortMode nextSortMode) {
    setState(() {
      _sortMode = nextSortMode;
    });
    widget.onSortModeChanged(nextSortMode);
  }

  _PreparedMealSortCriterion _sortCriterionFor(PreparedMealSortMode sortMode) {
    return switch (sortMode) {
      PreparedMealSortMode.addedDescending ||
      PreparedMealSortMode.addedAscending => _PreparedMealSortCriterion.added,
      PreparedMealSortMode.eatenDescending ||
      PreparedMealSortMode.eatenAscending => _PreparedMealSortCriterion.eaten,
      PreparedMealSortMode.alphabeticalAscending ||
      PreparedMealSortMode.alphabeticalDescending =>
        _PreparedMealSortCriterion.alphabetical,
      PreparedMealSortMode.quantityAscending ||
      PreparedMealSortMode.quantityDescending =>
        _PreparedMealSortCriterion.quantity,
    };
  }

  bool _isSortAscending(PreparedMealSortMode sortMode) {
    return switch (sortMode) {
      PreparedMealSortMode.addedAscending ||
      PreparedMealSortMode.eatenAscending ||
      PreparedMealSortMode.alphabeticalAscending ||
      PreparedMealSortMode.quantityAscending => true,
      PreparedMealSortMode.addedDescending ||
      PreparedMealSortMode.eatenDescending ||
      PreparedMealSortMode.alphabeticalDescending ||
      PreparedMealSortMode.quantityDescending => false,
    };
  }

  bool _defaultAscendingForCriterion(_PreparedMealSortCriterion criterion) {
    return switch (criterion) {
      _PreparedMealSortCriterion.added ||
      _PreparedMealSortCriterion.eaten => false,
      _PreparedMealSortCriterion.alphabetical ||
      _PreparedMealSortCriterion.quantity => true,
    };
  }

  PreparedMealSortMode _sortModeFor(
    _PreparedMealSortCriterion criterion, {
    required bool ascending,
  }) {
    return switch ((criterion, ascending)) {
      (_PreparedMealSortCriterion.added, true) =>
        PreparedMealSortMode.addedAscending,
      (_PreparedMealSortCriterion.added, false) =>
        PreparedMealSortMode.addedDescending,
      (_PreparedMealSortCriterion.eaten, true) =>
        PreparedMealSortMode.eatenAscending,
      (_PreparedMealSortCriterion.eaten, false) =>
        PreparedMealSortMode.eatenDescending,
      (_PreparedMealSortCriterion.alphabetical, true) =>
        PreparedMealSortMode.alphabeticalAscending,
      (_PreparedMealSortCriterion.alphabetical, false) =>
        PreparedMealSortMode.alphabeticalDescending,
      (_PreparedMealSortCriterion.quantity, true) =>
        PreparedMealSortMode.quantityAscending,
      (_PreparedMealSortCriterion.quantity, false) =>
        PreparedMealSortMode.quantityDescending,
    };
  }

  String _sortDirectionLabel(
    AppLocalizations l10n, {
    required _PreparedMealSortCriterion criterion,
    required bool ascending,
  }) {
    if (criterion == _PreparedMealSortCriterion.alphabetical) {
      return ascending
          ? l10n.inventorySortDirectionAlphaAscending
          : l10n.inventorySortDirectionAlphaDescending;
    }

    return ascending
        ? l10n.inventorySortDirectionAscending
        : l10n.inventorySortDirectionDescending;
  }
}
