import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_sorter.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_mode_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_segmented_button_frame.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_segmented_button_style.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Active section inside the unified inventory filter sheet.
enum InventoryUnifiedFilterSection {
  /// Prepared meals.
  preparedMeals,

  /// Individual inventory foods.
  foods,
}

enum _InventoryUnifiedViewMode { list, tiles }

enum _InventoryItemSortCriterion { added, eaten, alphabetical, quantity }

/// Unified inventory filter sheet for meals and foods.
class InventoryUnifiedFilterSheet extends StatefulWidget {
  /// Creates unified inventory filter sheet.
  const InventoryUnifiedFilterSheet({
    required this.initialSection,
    required this.initialListMode,
    required this.initialInventoryItemSortMode,
    required this.initialHideFullyConsumedItems,
    required this.initialPreparedMealCompletionFilter,
    required this.initialPreparedMealConsumptionFilter,
    required this.initialPreparedMealSortMode,
    required this.enabled,
    required this.onListModeChanged,
    required this.onInventoryItemSortModeChanged,
    required this.onHideFullyConsumedItemsChanged,
    required this.onPreparedMealCompletionFilterChanged,
    required this.onPreparedMealConsumptionFilterChanged,
    required this.onPreparedMealSortModeChanged,
    super.key,
  });

  /// Initially selected sheet section.
  final InventoryUnifiedFilterSection initialSection;

  /// Initial list grouping mode.
  final InventoryListMode initialListMode;

  /// Initial food sort mode.
  final InventoryItemSortMode initialInventoryItemSortMode;

  /// Initial food consumed filter.
  final bool initialHideFullyConsumedItems;

  /// Initial meal completion filter.
  final PreparedMealCompletionFilter initialPreparedMealCompletionFilter;

  /// Initial meal consumption filter.
  final PreparedMealConsumptionFilter initialPreparedMealConsumptionFilter;

  /// Initial meal sort mode.
  final PreparedMealSortMode initialPreparedMealSortMode;

  /// Whether controls are enabled.
  final bool enabled;

  /// Called when list grouping mode changes.
  final ValueChanged<InventoryListMode> onListModeChanged;

  /// Called when food sort mode changes.
  final ValueChanged<InventoryItemSortMode> onInventoryItemSortModeChanged;

  /// Called when food consumed filter changes.
  final ValueChanged<bool> onHideFullyConsumedItemsChanged;

  /// Called when meal completion filter changes.
  final ValueChanged<PreparedMealCompletionFilter>
  onPreparedMealCompletionFilterChanged;

  /// Called when meal consumption filter changes.
  final ValueChanged<PreparedMealConsumptionFilter>
  onPreparedMealConsumptionFilterChanged;

  /// Called when meal sort mode changes.
  final ValueChanged<PreparedMealSortMode> onPreparedMealSortModeChanged;

  @override
  State<InventoryUnifiedFilterSheet> createState() =>
      _InventoryUnifiedFilterSheetState();
}

class _InventoryUnifiedFilterSheetState
    extends State<InventoryUnifiedFilterSheet> {
  late InventoryUnifiedFilterSection _section;
  late InventoryListMode _listMode;
  late InventoryItemSortMode _inventoryItemSortMode;
  late bool _hideFullyConsumedItems;
  late PreparedMealCompletionFilter _preparedMealCompletionFilter;
  late PreparedMealConsumptionFilter _preparedMealConsumptionFilter;
  late PreparedMealSortMode _preparedMealSortMode;
  _InventoryUnifiedViewMode _viewMode = _InventoryUnifiedViewMode.list;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _listMode = widget.initialListMode;
    _inventoryItemSortMode = widget.initialInventoryItemSortMode;
    _hideFullyConsumedItems = widget.initialHideFullyConsumedItems;
    _preparedMealCompletionFilter = widget.initialPreparedMealCompletionFilter;
    _preparedMealConsumptionFilter =
        widget.initialPreparedMealConsumptionFilter;
    _preparedMealSortMode = widget.initialPreparedMealSortMode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InventoryFiltersSheet(
      title: l10n.inventoryFiltersTitle,
      subtitle: _section == InventoryUnifiedFilterSection.preparedMeals
          ? l10n.preparedMealFiltersSubtitle
          : l10n.inventoryFiltersSubtitle,
      actionLabel: l10n.inventoryFiltersShowResultsAction,
      children: [
        _InventoryViewModeSection(
          viewMode: _viewMode,
          listMode: _listMode,
          enabled: widget.enabled,
          onViewModeChanged: (value) {
            setState(() {
              _viewMode = value;
            });
          },
          onListModeChanged: _onListModeChanged,
        ),
        const _InventoryFilterDivider(),
        _InventoryFilterSectionTabs(
          section: _section,
          enabled: widget.enabled,
          onChanged: (section) {
            setState(() {
              _section = section;
            });
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (_section == InventoryUnifiedFilterSection.preparedMeals)
          _PreparedMealFilterContent(
            initialCompletionFilter: _preparedMealCompletionFilter,
            initialConsumptionFilter: _preparedMealConsumptionFilter,
            initialSortMode: _preparedMealSortMode,
            enabled: widget.enabled,
            onCompletionFilterChanged: _onPreparedMealCompletionFilterChanged,
            onConsumptionFilterChanged: _onPreparedMealConsumptionFilterChanged,
            onSortModeChanged: _onPreparedMealSortModeChanged,
          )
        else
          _InventoryItemFilterContent(
            initialSortMode: _inventoryItemSortMode,
            initialHideFullyConsumedItems: _hideFullyConsumedItems,
            enabled: widget.enabled,
            onSortModeChanged: _onInventoryItemSortModeChanged,
            onHideFullyConsumedItemsChanged: _onHideFullyConsumedItemsChanged,
          ),
      ],
    );
  }

  void _onListModeChanged(InventoryListMode value) {
    setState(() {
      _listMode = value;
    });
    widget.onListModeChanged(value);
  }

  void _onInventoryItemSortModeChanged(InventoryItemSortMode value) {
    setState(() {
      _inventoryItemSortMode = value;
    });
    widget.onInventoryItemSortModeChanged(value);
  }

  void _onHideFullyConsumedItemsChanged(bool value) {
    setState(() {
      _hideFullyConsumedItems = value;
    });
    widget.onHideFullyConsumedItemsChanged(value);
  }

  void _onPreparedMealCompletionFilterChanged(
    PreparedMealCompletionFilter value,
  ) {
    setState(() {
      _preparedMealCompletionFilter = value;
    });
    widget.onPreparedMealCompletionFilterChanged(value);
  }

  void _onPreparedMealConsumptionFilterChanged(
    PreparedMealConsumptionFilter value,
  ) {
    setState(() {
      _preparedMealConsumptionFilter = value;
    });
    widget.onPreparedMealConsumptionFilterChanged(value);
  }

  void _onPreparedMealSortModeChanged(PreparedMealSortMode value) {
    setState(() {
      _preparedMealSortMode = value;
    });
    widget.onPreparedMealSortModeChanged(value);
  }
}

class _InventoryItemFilterContent extends StatefulWidget {
  const _InventoryItemFilterContent({
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
  State<_InventoryItemFilterContent> createState() =>
      _InventoryItemFilterContentState();
}

class _InventoryItemFilterContentState
    extends State<_InventoryItemFilterContent> {
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
        for (final config in _inventorySortOptions(l10n)) ...[
          _buildSortOptionCard(
            l10n: l10n,
            config: config,
            selectedCriterion: selectedCriterion,
            sortAscending: sortAscending,
          ),
          if (config.criterion != _InventoryItemSortCriterion.quantity)
            const SizedBox(height: AppSpacing.xs),
        ],
        const _InventoryFilterDivider(),
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

  List<_InventoryItemSortOptionConfig> _inventorySortOptions(
    AppLocalizations l10n,
  ) {
    return [
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
  }

  void _updateSortMode(InventoryItemSortMode value) {
    setState(() {
      _sortMode = value;
    });
    widget.onSortModeChanged(value);
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

class _PreparedMealFilterContent extends StatefulWidget {
  const _PreparedMealFilterContent({
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
  State<_PreparedMealFilterContent> createState() =>
      _PreparedMealFilterContentState();
}

class _PreparedMealFilterContentState
    extends State<_PreparedMealFilterContent> {
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
        const _InventoryFilterDivider(),
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

class _InventoryViewModeSection extends StatelessWidget {
  const _InventoryViewModeSection({
    required this.viewMode,
    required this.listMode,
    required this.enabled,
    required this.onViewModeChanged,
    required this.onListModeChanged,
  });

  final _InventoryUnifiedViewMode viewMode;
  final InventoryListMode listMode;
  final bool enabled;
  final ValueChanged<_InventoryUnifiedViewMode> onViewModeChanged;
  final ValueChanged<InventoryListMode> onListModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryFiltersSectionLabel(label: l10n.inventoryViewSectionTitle),
        const SizedBox(height: AppSpacing.md),
        InventorySegmentedButtonFrame(
          child: SegmentedButton<_InventoryUnifiedViewMode>(
            expandedInsets: AppInsets.zero,
            showSelectedIcon: false,
            style: inventorySegmentedButtonStyle(context),
            selected: {viewMode},
            segments: [
              ButtonSegment(
                value: _InventoryUnifiedViewMode.list,
                icon: const Icon(Icons.list_rounded, size: 16),
                label: Text(l10n.inventoryViewListAction),
              ),
              ButtonSegment(
                value: _InventoryUnifiedViewMode.tiles,
                icon: const Icon(Icons.grid_view_rounded, size: 16),
                label: Text(l10n.inventoryViewTilesAction),
              ),
            ],
            onSelectionChanged: enabled
                ? (selection) {
                    if (selection.isNotEmpty) {
                      onViewModeChanged(selection.first);
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InventorySegmentedButtonFrame(
          child: SegmentedButton<InventoryListMode>(
            expandedInsets: AppInsets.zero,
            showSelectedIcon: false,
            style: inventorySegmentedButtonStyle(context),
            selected: {listMode},
            segments: [
              ButtonSegment(
                value: InventoryListMode.allItems,
                label: Text(l10n.inventoryListModeAllItems),
              ),
              ButtonSegment(
                value: InventoryListMode.byReceipt,
                label: Text(l10n.inventoryListModeByReceipt),
              ),
            ],
            onSelectionChanged: enabled
                ? (selection) {
                    if (selection.isNotEmpty) {
                      onListModeChanged(selection.first);
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _InventoryFilterSectionTabs extends StatelessWidget {
  const _InventoryFilterSectionTabs({
    required this.section,
    required this.enabled,
    required this.onChanged,
  });

  final InventoryUnifiedFilterSection section;
  final bool enabled;
  final ValueChanged<InventoryUnifiedFilterSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InventorySegmentedButtonFrame(
      child: SegmentedButton<InventoryUnifiedFilterSection>(
        expandedInsets: AppInsets.zero,
        showSelectedIcon: false,
        style: inventorySegmentedButtonStyle(context),
        selected: {section},
        segments: [
          ButtonSegment(
            value: InventoryUnifiedFilterSection.preparedMeals,
            label: Text(l10n.preparedMealSectionTitle),
          ),
          ButtonSegment(
            value: InventoryUnifiedFilterSection.foods,
            label: Text(l10n.inventoryRecentSectionTitle),
          ),
        ],
        onSelectionChanged: enabled
            ? (selection) {
                if (selection.isNotEmpty) {
                  onChanged(selection.first);
                }
              }
            : null,
      ),
    );
  }
}

class _InventoryFilterDivider extends StatelessWidget {
  const _InventoryFilterDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Divider(
        height: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
    );
  }
}
