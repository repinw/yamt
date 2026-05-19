import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_divider.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_filter_content.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_mode_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'prepared_meal_filter_content.dart';
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

/// Unified inventory filter sheet for meals and foods.
class InventoryUnifiedFilterSheet extends StatefulWidget {
  /// Creates unified inventory filter sheet.
  const InventoryUnifiedFilterSheet({
    required this.initialSection,
    required this.initialViewMode,
    required this.initialListMode,
    required this.initialInventoryItemSortMode,
    required this.initialHideFullyConsumedItems,
    required this.initialPreparedMealCompletionFilter,
    required this.initialPreparedMealConsumptionFilter,
    required this.initialPreparedMealSortMode,
    required this.enabled,
    required this.onViewModeChanged,
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

  /// Initial card layout mode.
  final InventoryListViewMode initialViewMode;

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

  /// Called when card layout mode changes.
  final ValueChanged<InventoryListViewMode> onViewModeChanged;

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
  late InventoryListViewMode _viewMode;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _viewMode = widget.initialViewMode;
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
          onViewModeChanged: _onViewModeChanged,
          onListModeChanged: _onListModeChanged,
        ),
        const InventoryFilterDivider(),
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
          PreparedMealFilterContent(
            initialCompletionFilter: _preparedMealCompletionFilter,
            initialConsumptionFilter: _preparedMealConsumptionFilter,
            initialSortMode: _preparedMealSortMode,
            enabled: widget.enabled,
            onCompletionFilterChanged: _onPreparedMealCompletionFilterChanged,
            onConsumptionFilterChanged: _onPreparedMealConsumptionFilterChanged,
            onSortModeChanged: _onPreparedMealSortModeChanged,
          )
        else
          InventoryItemFilterContent(
            initialSortMode: _inventoryItemSortMode,
            initialHideFullyConsumedItems: _hideFullyConsumedItems,
            enabled: widget.enabled,
            onSortModeChanged: _onInventoryItemSortModeChanged,
            onHideFullyConsumedItemsChanged: _onHideFullyConsumedItemsChanged,
          ),
      ],
    );
  }

  void _onViewModeChanged(InventoryListViewMode value) {
    setState(() {
      _viewMode = value;
    });
    widget.onViewModeChanged(value);
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

class _InventoryViewModeSection extends StatelessWidget {
  const _InventoryViewModeSection({
    required this.viewMode,
    required this.listMode,
    required this.enabled,
    required this.onViewModeChanged,
    required this.onListModeChanged,
  });

  final InventoryListViewMode viewMode;
  final InventoryListMode listMode;
  final bool enabled;
  final ValueChanged<InventoryListViewMode> onViewModeChanged;
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
          child: SegmentedButton<InventoryListViewMode>(
            expandedInsets: AppInsets.zero,
            showSelectedIcon: false,
            style: inventorySegmentedButtonStyle(context),
            selected: {viewMode},
            segments: [
              ButtonSegment(
                value: InventoryListViewMode.list,
                icon: const Icon(Icons.list_rounded, size: 16),
                label: Text(l10n.inventoryViewListAction),
              ),
              ButtonSegment(
                value: InventoryListViewMode.tiles,
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
