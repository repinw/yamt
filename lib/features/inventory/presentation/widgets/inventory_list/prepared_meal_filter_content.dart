import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_sorter.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_divider.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Meal-specific content for the unified inventory filter sheet.
class PreparedMealFilterContent extends StatefulWidget {
  /// Creates prepared meal filter content.
  const PreparedMealFilterContent({
    required this.initialCompletionFilter,
    required this.initialConsumptionFilter,
    required this.initialSortMode,
    required this.enabled,
    required this.onCompletionFilterChanged,
    required this.onConsumptionFilterChanged,
    required this.onSortModeChanged,
    super.key,
  });

  /// Initial completion filter.
  final PreparedMealCompletionFilter initialCompletionFilter;

  /// Initial consumption filter.
  final PreparedMealConsumptionFilter initialConsumptionFilter;

  /// Initial meal sort mode.
  final PreparedMealSortMode initialSortMode;

  /// Whether controls are enabled.
  final bool enabled;

  /// Called when completion filter changes.
  final ValueChanged<PreparedMealCompletionFilter> onCompletionFilterChanged;

  /// Called when consumption filter changes.
  final ValueChanged<PreparedMealConsumptionFilter> onConsumptionFilterChanged;

  /// Called when sort mode changes.
  final ValueChanged<PreparedMealSortMode> onSortModeChanged;

  @override
  State<PreparedMealFilterContent> createState() =>
      _PreparedMealFilterContentState();
}

class _PreparedMealFilterContentState extends State<PreparedMealFilterContent> {
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
        for (final config in _preparedMealSortOptions(l10n)) ...[
          _buildSortOptionCard(
            l10n: l10n,
            config: config,
            selectedCriterion: selectedCriterion,
            sortAscending: sortAscending,
          ),
          if (config.criterion != PreparedMealSortCriterion.quantity)
            const SizedBox(height: AppSpacing.xs),
        ],
        const InventoryFilterDivider(),
        InventoryFiltersSectionLabel(label: l10n.inventoryFilterSectionTitle),
        const SizedBox(height: AppSpacing.md),
        InventoryFilterToggle(
          key: const Key('prepared_meals_ready_only_toggle'),
          value: _completionFilter == PreparedMealCompletionFilter.readyOnly,
          enabled: widget.enabled,
          label: l10n.preparedMealShowReadyOnlyToggle,
          icon: Icons.check_circle_outline_rounded,
          onChanged: (value) {
            _updateCompletionFilter(
              value
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
          onChanged: (value) {
            _updateCompletionFilter(
              value
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
          onChanged: (value) {
            _updateConsumptionFilter(
              value
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
          onChanged: (value) {
            _updateConsumptionFilter(
              value
                  ? PreparedMealConsumptionFilter.hideConsumed
                  : PreparedMealConsumptionFilter.all,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSortOptionCard({
    required AppLocalizations l10n,
    required _PreparedMealSortOptionConfig config,
    required PreparedMealSortCriterion selectedCriterion,
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
          _sorter.modeFor(
            config.criterion,
            ascending: _sorter.defaultAscendingForCriterion(config.criterion),
          ),
        );
      },
      onToggleDirection: isSelected
          ? () {
              _updateSortMode(
                _sorter.modeFor(config.criterion, ascending: !sortAscending),
              );
            }
          : null,
    );
  }

  List<_PreparedMealSortOptionConfig> _preparedMealSortOptions(
    AppLocalizations l10n,
  ) {
    return [
      _PreparedMealSortOptionConfig(
        criterion: PreparedMealSortCriterion.added,
        optionKey: const Key('prepared_meals_sort_added_option'),
        directionButtonKey: const Key(
          'prepared_meals_sort_added_direction_button',
        ),
        title: l10n.inventorySortAdded,
        icon: Icons.access_time_rounded,
      ),
      _PreparedMealSortOptionConfig(
        criterion: PreparedMealSortCriterion.eaten,
        optionKey: const Key('prepared_meals_sort_eaten_option'),
        directionButtonKey: const Key(
          'prepared_meals_sort_eaten_direction_button',
        ),
        title: l10n.inventorySortEaten,
        icon: Icons.restaurant_rounded,
      ),
      _PreparedMealSortOptionConfig(
        criterion: PreparedMealSortCriterion.alphabetical,
        optionKey: const Key('prepared_meals_sort_alphabetical_option'),
        directionButtonKey: const Key(
          'prepared_meals_sort_alphabetical_direction_button',
        ),
        title: l10n.inventorySortAlphabetical,
        icon: Icons.sort_by_alpha_rounded,
      ),
      _PreparedMealSortOptionConfig(
        criterion: PreparedMealSortCriterion.quantity,
        optionKey: const Key('prepared_meals_sort_quantity_option'),
        directionButtonKey: const Key(
          'prepared_meals_sort_quantity_direction_button',
        ),
        title: l10n.inventorySortQuantity,
        icon: Icons.inventory_2_rounded,
      ),
    ];
  }

  void _updateCompletionFilter(PreparedMealCompletionFilter value) {
    setState(() {
      _completionFilter = value;
    });
    widget.onCompletionFilterChanged(value);
  }

  void _updateConsumptionFilter(PreparedMealConsumptionFilter value) {
    setState(() {
      _consumptionFilter = value;
    });
    widget.onConsumptionFilterChanged(value);
  }

  void _updateSortMode(PreparedMealSortMode value) {
    setState(() {
      _sortMode = value;
    });
    widget.onSortModeChanged(value);
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

class _PreparedMealSortOptionConfig {
  const _PreparedMealSortOptionConfig({
    required this.criterion,
    required this.optionKey,
    required this.directionButtonKey,
    required this.title,
    required this.icon,
  });

  final PreparedMealSortCriterion criterion;
  final Key optionKey;
  final Key directionButtonKey;
  final String title;
  final IconData icon;
}
