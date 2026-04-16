import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_sorter.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal filter sheet.
class PreparedMealFilterSheet extends StatefulWidget {
  /// The prepared meal filter sheet.
  const PreparedMealFilterSheet({
    required this.initialCompletionFilter,
    required this.initialConsumptionFilter,
    required this.initialSortMode,
    required this.enabled,
    required this.onCompletionFilterChanged,
    required this.onConsumptionFilterChanged,
    required this.onSortModeChanged,
    super.key,
  });

  /// The initial completion filter.
  final PreparedMealCompletionFilter initialCompletionFilter;

  /// The initial consumption filter.
  final PreparedMealConsumptionFilter initialConsumptionFilter;

  /// The initial sort mode.
  final PreparedMealSortMode initialSortMode;

  /// The enabled.
  final bool enabled;

  /// The on completion filter changed.
  final ValueChanged<PreparedMealCompletionFilter> onCompletionFilterChanged;

  /// The on consumption filter changed.
  final ValueChanged<PreparedMealConsumptionFilter> onConsumptionFilterChanged;

  /// The on sort mode changed.
  final ValueChanged<PreparedMealSortMode> onSortModeChanged;

  @override
  State<PreparedMealFilterSheet> createState() =>
      _PreparedMealFilterSheetState();
}

class _PreparedMealFilterSheetState extends State<PreparedMealFilterSheet> {
  static const _sorter = PreparedMealSorter();
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
    final selectedCriterion = _sorter.criterionFor(_sortMode);
    final sortAscending = _sorter.isAscending(_sortMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryFiltersSectionLabel(label: l10n.inventorySortSectionTitle),
        const SizedBox(height: AppSpacing.md),
        InventorySortOptionCard(
          key: const Key('prepared_meals_sort_added_option'),
          title: l10n.inventorySortAdded,
          icon: Icons.access_time_rounded,
          isSelected: selectedCriterion == PreparedMealSortCriterion.added,
          enabled: widget.enabled,
          directionLabel: selectedCriterion == PreparedMealSortCriterion.added
              ? _sortDirectionLabel(
                  l10n,
                  criterion: PreparedMealSortCriterion.added,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'prepared_meals_sort_added_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sorter.modeFor(
                PreparedMealSortCriterion.added,
                ascending: _sorter.defaultAscendingForCriterion(
                  PreparedMealSortCriterion.added,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == PreparedMealSortCriterion.added
              ? () {
                  _updateSortMode(
                    _sorter.modeFor(
                      PreparedMealSortCriterion.added,
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
          isSelected: selectedCriterion == PreparedMealSortCriterion.eaten,
          enabled: widget.enabled,
          directionLabel: selectedCriterion == PreparedMealSortCriterion.eaten
              ? _sortDirectionLabel(
                  l10n,
                  criterion: PreparedMealSortCriterion.eaten,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'prepared_meals_sort_eaten_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sorter.modeFor(
                PreparedMealSortCriterion.eaten,
                ascending: _sorter.defaultAscendingForCriterion(
                  PreparedMealSortCriterion.eaten,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == PreparedMealSortCriterion.eaten
              ? () {
                  _updateSortMode(
                    _sorter.modeFor(
                      PreparedMealSortCriterion.eaten,
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
              selectedCriterion == PreparedMealSortCriterion.alphabetical,
          enabled: widget.enabled,
          directionLabel:
              selectedCriterion == PreparedMealSortCriterion.alphabetical
              ? _sortDirectionLabel(
                  l10n,
                  criterion: PreparedMealSortCriterion.alphabetical,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'prepared_meals_sort_alphabetical_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sorter.modeFor(
                PreparedMealSortCriterion.alphabetical,
                ascending: _sorter.defaultAscendingForCriterion(
                  PreparedMealSortCriterion.alphabetical,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == PreparedMealSortCriterion.alphabetical
              ? () {
                  _updateSortMode(
                    _sorter.modeFor(
                      PreparedMealSortCriterion.alphabetical,
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
          isSelected: selectedCriterion == PreparedMealSortCriterion.quantity,
          enabled: widget.enabled,
          directionLabel:
              selectedCriterion == PreparedMealSortCriterion.quantity
              ? _sortDirectionLabel(
                  l10n,
                  criterion: PreparedMealSortCriterion.quantity,
                  ascending: sortAscending,
                )
              : null,
          directionButtonKey: const Key(
            'prepared_meals_sort_quantity_direction_button',
          ),
          sortDirectionAscending: sortAscending,
          onSelect: () {
            _updateSortMode(
              _sorter.modeFor(
                PreparedMealSortCriterion.quantity,
                ascending: _sorter.defaultAscendingForCriterion(
                  PreparedMealSortCriterion.quantity,
                ),
              ),
            );
          },
          onToggleDirection:
              selectedCriterion == PreparedMealSortCriterion.quantity
              ? () {
                  _updateSortMode(
                    _sorter.modeFor(
                      PreparedMealSortCriterion.quantity,
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

  String _sortDirectionLabel(
    AppLocalizations l10n, {
    required PreparedMealSortCriterion criterion,
    required bool ascending,
  }) {
    if (criterion == PreparedMealSortCriterion.alphabetical) {
      return ascending
          ? l10n.inventorySortDirectionAlphaAscending
          : l10n.inventorySortDirectionAlphaDescending;
    }

    return ascending
        ? l10n.inventorySortDirectionAscending
        : l10n.inventorySortDirectionDescending;
  }
}
