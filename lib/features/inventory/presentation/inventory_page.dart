import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_detail_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_page_content.dart';

enum _InventoryPageView { stock, history }

/// Defines inventory page.
class InventoryPage extends ConsumerStatefulWidget {
  /// The inventory page.
  const new({super.key, this.includeHomeShellChrome = false, this.openMealId});

  /// Whether to render the shared home shell app bar as a sliver.
  final bool includeHomeShellChrome;

  /// The Vorrat meal whose page opens once it is loaded, such as the meal
  /// just cooked ("Jetzt essen"); each id opens once.
  final String? openMealId;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  _InventoryPageView _selectedView = _InventoryPageView.stock;
  String? _openedMealId;
  ProviderSubscription<AsyncValue<List<PreparedMeal>>>? _mealWait;

  @override
  void initState() {
    super.initState();
    _openRequestedMeal();
  }

  @override
  void didUpdateWidget(InventoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _openRequestedMeal();
  }

  @override
  void dispose() {
    _mealWait?.close();
    super.dispose();
  }

  // Waits until the meals hold [InventoryPage.openMealId], then opens its
  // page after the frame. The first call may come before the subscription
  // is stored, so a flag keeps it to one opening.
  void _openRequestedMeal() {
    final id = widget.openMealId;
    if (id == null || id == _openedMealId) return;
    _openedMealId = id;
    _mealWait?.close();
    var found = false;
    late final ProviderSubscription<AsyncValue<List<PreparedMeal>>> wait;
    wait = ref.listenManual(preparedMealsControllerProvider, (_, meals) {
      final meal = meals.value?.where((meal) => meal.id == id).firstOrNull;
      if (found || meal == null) return;
      found = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Unmounted, dispose closed it already.
        if (!mounted) return;
        wait.close();
        if (identical(_mealWait, wait)) _mealWait = null;
        unawaited(
          PreparedMealDetailFlow.open(context: context, ref: ref, meal: meal),
        );
      });
    }, fireImmediately: true);
    _mealWait = wait;
  }

  @override
  Widget build(BuildContext context) {
    return InventoryPageContent(
      isShowingHistory: _selectedView == _InventoryPageView.history,
      onToggleView: _toggleView,
      includeHomeShellChrome: widget.includeHomeShellChrome,
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
