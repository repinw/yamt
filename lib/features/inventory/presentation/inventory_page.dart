import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_edit_coordinator.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_page_content.dart';

enum _InventoryPageView { stock, history }

/// Defines inventory page.
class InventoryPage extends ConsumerStatefulWidget {
  /// The inventory page.
  const InventoryPage({
    super.key,
    this.expandedPreparedMealId,
    this.includeHomeShellChrome = false,
    this.emptyStateActionButton,
  });

  /// The expanded prepared meal id.
  final String? expandedPreparedMealId;

  /// Whether to render the shared home shell app bar as a sliver.
  final bool includeHomeShellChrome;

  /// Optional action button rendered by the embedding shell.
  final Widget? emptyStateActionButton;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _mealEditCoordinator = InventoryPreparedMealEditCoordinator();
  _InventoryPageView _selectedView = _InventoryPageView.stock;

  @override
  Widget build(BuildContext context) {
    return InventoryPageContent(
      isShowingHistory: _selectedView == _InventoryPageView.history,
      onToggleView: _toggleView,
      mealEditCoordinator: _mealEditCoordinator,
      onFocusRequested: () => setState(() {}),
      expandedPreparedMealId: widget.expandedPreparedMealId,
      includeHomeShellChrome: widget.includeHomeShellChrome,
      emptyStateActionButton: widget.emptyStateActionButton,
    );
  }

  void _toggleView() {
    setState(() {
      _selectedView = _selectedView == _InventoryPageView.stock
          ? _InventoryPageView.history
          : _InventoryPageView.stock;
    });
  }
}
