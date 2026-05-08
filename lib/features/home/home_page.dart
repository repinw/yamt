import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_date_utils.dart';
import 'package:yamt/features/diary/provider/diary_calendar_controller.dart';
import 'package:yamt/features/home/widgets/home_heart_counter_button.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensils_button.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_import_button.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryBranchIndex = 0;
const _diaryBranchIndex = 1;
const _cookbookBranchIndex = 2;
const _statisticsBranchIndex = 3;
const _settingsBranchIndex = 4;

/// Shell page that hosts the main app tabs and shared home chrome.
@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
class HomePage extends ConsumerWidget {
  /// The home page.
  const HomePage({required this.navigationShell, super.key});

  /// The navigation shell.
  final StatefulNavigationShell navigationShell;

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  HomeTabType _currentTab() {
    return switch (navigationShell.currentIndex) {
      _inventoryBranchIndex => HomeTabType.inventory,
      _diaryBranchIndex => HomeTabType.diary,
      _cookbookBranchIndex => HomeTabType.cookbook,
      _statisticsBranchIndex => HomeTabType.statistics,
      _settingsBranchIndex => HomeTabType.settings,
      _ => HomeTabType.inventory, // coverage:ignore-line
    };
  }

  String _titleForTab(
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
    DiaryCalendarState? diaryCalendarState,
    String localeName,
  ) {
    if (_currentTab() == HomeTabType.inventory &&
        selectionState.isSelectionMode) {
      return l10n.preparedMealSelectionCount(selectionState.selectedCount);
    }

    switch (_currentTab()) {
      case HomeTabType.inventory:
        return l10n.inventoryPageTitle;
      case HomeTabType.diary:
        return diaryCalendarState?.isSelectedToday ?? true
            ? l10n.diaryTodayTitle
            : diaryWeekdayFullLabel(
                diaryCalendarState!.selectedDay,
                localeName,
              );
      case HomeTabType.cookbook:
        return l10n.homeCookbook;
      case HomeTabType.statistics:
        return l10n.homeStatistics;
      case HomeTabType.settings:
        return l10n.homeSettings;
    }
  }

  String? _subtitleForTab(
    DiaryCalendarState? diaryCalendarState,
    String localeName,
  ) {
    if (diaryCalendarState == null) {
      return null;
    }

    return formatDiaryHeaderDate(diaryCalendarState.selectedDay, localeName);
  }

  List<HomeNavEntry> _navEntries(BuildContext context, AppLocalizations l10n) {
    final currentTab = _currentTab();
    final isMoreSelected =
        currentTab == HomeTabType.statistics ||
        currentTab == HomeTabType.settings;

    return [
      HomeNavEntry(
        item: HomeNavItem(
          icon: Icons.menu_book_rounded,
          label: l10n.homeCalories,
        ),
        isSelected: currentTab == HomeTabType.diary,
        onTap: () => _onTabTapped(_diaryBranchIndex),
      ),
      HomeNavEntry(
        item: HomeNavItem(
          icon: Icons.inventory_2_rounded,
          label: l10n.homeInventory,
        ),
        isSelected: currentTab == HomeTabType.inventory,
        onTap: () => _onTabTapped(_inventoryBranchIndex),
      ),
      HomeNavEntry(
        item: HomeNavItem(
          icon: Icons.auto_stories_rounded,
          label: l10n.homeCookbook,
        ),
        isSelected: currentTab == HomeTabType.cookbook,
        onTap: () => _onTabTapped(_cookbookBranchIndex),
      ),
      HomeNavEntry(
        item: HomeNavItem(
          icon: Icons.more_horiz_rounded,
          label: l10n.homeMore,
        ),
        isSelected: isMoreSelected,
        showTopIndicator: isMoreSelected,
        onTap: () => _showMoreMenu(context, l10n),
      ),
    ];
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
    bool useCompactSelectionActions,
    DiaryCalendarState? diaryCalendarState,
  ) {
    if (_currentTab() == HomeTabType.inventory &&
        selectionState.isSelectionMode) {
      final isAddingIngredients = selectionState.isAddingIngredientsToMeal;
      final selectionActionLabel = isAddingIngredients
          ? l10n.preparedMealAddIngredientAction
          : l10n.preparedMealBindAction;
      final selectionActionIcon = isAddingIngredients
          ? Icons.add_rounded
          : Icons.restaurant_menu_rounded;
      final canConfirmSelection =
          selectionState.selectedCount >= (isAddingIngredients ? 1 : 2);
      if (useCompactSelectionActions) {
        return [
          IconButton(
            tooltip: l10n.inventoryReceiptReviewCancelAction,
            onPressed: () {
              ref
                  .read(preparedMealSelectionControllerProvider.notifier)
                  .clearSelection();
            },
            icon: const Icon(Icons.close_rounded),
          ),
          IconButton.filledTonal(
            tooltip: selectionActionLabel,
            onPressed: canConfirmSelection
                ? () {
                    ref
                        .read(preparedMealSelectionControllerProvider.notifier)
                        .confirmSelection();
                  }
                : null,
            icon: Icon(selectionActionIcon),
          ),
        ];
      }

      return [
        TextButton(
          onPressed: () {
            ref
                .read(preparedMealSelectionControllerProvider.notifier)
                .clearSelection();
          },
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton.tonalIcon(
          onPressed: canConfirmSelection
              ? () {
                  ref
                      .read(preparedMealSelectionControllerProvider.notifier)
                      .confirmSelection();
                }
              : null,
          icon: Icon(selectionActionIcon),
          label: Text(selectionActionLabel),
        ),
      ];
    }

    switch (_currentTab()) {
      case HomeTabType.inventory:
        return [
          IconButton(
            tooltip: l10n.commonNotImplementedYet,
            onPressed: () =>
                _showSnackBar(context, l10n.commonNotImplementedYet),
            icon: const Icon(Icons.assignment_outlined),
          ),
          IconButton(
            tooltip: l10n.homeShopping,
            onPressed: () => context.push(AppRoutes.homeShopping),
            icon: const Icon(Icons.shopping_cart_rounded),
          ),
        ];
      case HomeTabType.diary:
        if (diaryCalendarState == null || diaryCalendarState.isSelectedToday) {
          return const <Widget>[];
        }

        return [
          TextButton(
            onPressed: () {
              ref.read(diaryCalendarControllerProvider.notifier).selectToday();
            },
            child: Text(l10n.diaryTodayTitle),
          ),
        ];
      case HomeTabType.cookbook:
        return const [
          KitchenUtensilsButton(),
          MealTemplateRecipeImportButton(),
        ];
      case HomeTabType.statistics:
        return const <Widget>[];
      case HomeTabType.settings:
        return const <Widget>[];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final colors = Theme.of(context).colorScheme;
    final currentTab = _currentTab();
    final compactHomeChrome = shouldUseCompactHomeChrome(context);
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);
    final diaryCalendarState = currentTab == HomeTabType.diary
        ? ref.watch(diaryCalendarControllerProvider)
        : null;
    final burnWeekRunState = ref
        .watch(burnWeekRunControllerProvider)
        .asData
        ?.value;
    final topBarTitle = _titleForTab(
      l10n,
      selectionState,
      diaryCalendarState,
      localeName,
    );
    final topBarSubtitle = _subtitleForTab(diaryCalendarState, localeName);
    final floatingActionButton = switch (currentTab) {
      HomeTabType.inventory => _buildInventoryFab(ref),
      HomeTabType.diary ||
      HomeTabType.cookbook ||
      HomeTabType.statistics ||
      HomeTabType.settings => null,
    };

    final theme = Theme.of(context);
    final homeTheme = theme.copyWith(
      snackBarTheme: theme.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.fixed,
      ),
    );

    return Theme(
      data: homeTheme,
      child: Scaffold(
        extendBody: currentTab != HomeTabType.settings,
        appBar: HomeTopBar(
          title: topBarTitle,
          subtitle: topBarSubtitle,
          middle: _buildMiddle(currentTab, burnWeekRunState),
          titleColor: colors.primary,
          compact: compactHomeChrome,
          preferredHeight: HomeTopBar.preferredHeightFor(
            context,
            compact: compactHomeChrome,
            hasSubtitle: topBarSubtitle != null,
          ),
          actions: _buildActions(
            context,
            ref,
            l10n,
            selectionState,
            compactHomeChrome,
            diaryCalendarState,
          ),
        ),
        body: navigationShell,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        floatingActionButton: floatingActionButton ?? const SizedBox.shrink(),
        bottomNavigationBar: HomeBottomNavBar(
          entries: _navEntries(context, l10n),
        ),
      ),
    );
  }

  Widget? _buildInventoryFab(WidgetRef ref) {
    final items = ref.watch(inventoryItemsControllerProvider).asData?.value;
    final meals = ref.watch(preparedMealsControllerProvider).asData?.value;
    if (items == null || meals == null) {
      return null;
    }
    if (items.isEmpty && meals.isEmpty) {
      return null;
    }
    return const InventoryActionFab();
  }

  Widget? _buildMiddle(HomeTabType currentTab, BurnWeekRunState? runState) {
    if (currentTab != HomeTabType.diary) {
      return null;
    }
    if (runState == null ||
        runState.runWeekNumber <= burnWeekLearningRunWeekNumber) {
      return null;
    }
    return HomeHeartCounterButton(runState: runState);
  }

  void _showMoreMenu(BuildContext context, AppLocalizations l10n) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HomeMoreMenuTile(
                    icon: Icons.insights_rounded,
                    label: l10n.homeStatistics,
                    onTap: () {
                      sheetContext.pop();
                      _onTabTapped(_statisticsBranchIndex);
                    },
                  ),
                  _HomeMoreMenuTile(
                    icon: Icons.settings_rounded,
                    label: l10n.homeSettings,
                    onTap: () {
                      sheetContext.pop();
                      _onTabTapped(_settingsBranchIndex);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HomeMoreMenuTile extends StatelessWidget {
  const _HomeMoreMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
