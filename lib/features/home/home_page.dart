import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/home/widgets/home_context_fab.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryBranchIndex = 0;
const _diaryBranchIndex = 1;
const _statisticsBranchIndex = 2;
const _settingsBranchIndex = 3;

enum _DiaryAppBarAction { setGoal, shiftGoalStart, calculator }

/// Shell page that hosts the main app tabs and shared home chrome.
class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.navigationShell});

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
      _statisticsBranchIndex => HomeTabType.statistics,
      _settingsBranchIndex => HomeTabType.settings,
      _ => HomeTabType.inventory, // coverage:ignore-line
    };
  }

  String _titleForTab(
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
  ) {
    if (_currentTab() == HomeTabType.inventory &&
        selectionState.isSelectionMode) {
      return l10n.preparedMealSelectionCount(selectionState.selectedCount);
    }

    switch (_currentTab()) {
      case HomeTabType.inventory:
        return l10n.inventoryPageTitle;
      case HomeTabType.diary:
        return l10n.homeCalories;
      case HomeTabType.statistics:
        return l10n.homeStatistics;
      case HomeTabType.settings:
        return l10n.homeSettings;
    }
  }

  List<HomeNavEntry> _navEntries(BuildContext context, AppLocalizations l10n) {
    final currentTab = _currentTab();

    return [
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
          icon: Icons.bar_chart_rounded,
          label: l10n.homeCalories,
        ),
        isSelected: currentTab == HomeTabType.diary,
        onTap: () => _onTabTapped(_diaryBranchIndex),
      ),
      HomeNavEntry(
        item: HomeNavItem(
          icon: Icons.insights_rounded,
          label: l10n.homeStatistics,
        ),
        isSelected: currentTab == HomeTabType.statistics,
        onTap: () => _onTabTapped(_statisticsBranchIndex),
      ),
      HomeNavEntry(
        item: HomeNavItem(icon: Icons.person_rounded, label: l10n.homeSettings),
        isSelected: currentTab == HomeTabType.settings,
        onTap: () => _onTabTapped(_settingsBranchIndex),
      ),
    ];
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
    CalorieGoalSettings? currentCalorieSettings,
  ) {
    if (_currentTab() == HomeTabType.inventory &&
        selectionState.isSelectionMode) {
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
          onPressed: selectionState.selectedCount >= 2
              ? () {
                  ref
                      .read(preparedMealSelectionControllerProvider.notifier)
                      .requestCreateMeal();
                }
              : null,
          icon: const Icon(Icons.restaurant_menu_rounded),
          label: Text(l10n.preparedMealBindAction),
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
          IconButton.filledTonal(
            tooltip: l10n.preparedMealTemplatesPageTitle,
            onPressed: () => context.push(AppRoutes.homeInventoryTemplates),
            icon: const Icon(Icons.bookmarks_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppInventoryEditorial.primary.withValues(
                alpha: 0.12,
              ),
              foregroundColor: AppInventoryEditorial.primary,
            ),
          ),
          IconButton(
            tooltip: l10n.homeShopping,
            onPressed: () => context.push(AppRoutes.homeShopping),
            icon: const Icon(Icons.shopping_cart_rounded),
          ),
        ];
      case HomeTabType.diary:
        return [
          PopupMenuButton<_DiaryAppBarAction>(
            key: CaloriesPageKeys.appBarMenuButton,
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: (action) => _onDiaryActionSelected(
              action: action,
              context: context,
              ref: ref,
              l10n: l10n,
            ),
            itemBuilder: (context) {
              return <PopupMenuEntry<_DiaryAppBarAction>>[
                PopupMenuItem<_DiaryAppBarAction>(
                  value: _DiaryAppBarAction.setGoal,
                  child: Text(l10n.caloriesSetGoalAction),
                ),
                PopupMenuItem<_DiaryAppBarAction>(
                  key: CaloriesPageKeys.appBarMenuShiftGoalStartAction,
                  value: _DiaryAppBarAction.shiftGoalStart,
                  enabled: currentCalorieSettings?.hasGoal == true,
                  child: Text(l10n.caloriesShiftGoalStartAction),
                ),
                PopupMenuItem<_DiaryAppBarAction>(
                  key: CaloriesPageKeys.appBarMenuCalculatorAction,
                  value: _DiaryAppBarAction.calculator,
                  child: Text(l10n.caloriesCalculatorAction),
                ),
              ];
            },
          ),
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
    final currentTab = _currentTab();
    final currentCalorieSettings = ref
        .watch(calorieGoalControllerProvider)
        .asData
        ?.value;
    final floatingActionButton = switch (currentTab) {
      HomeTabType.inventory => _buildInventoryFab(ref),
      HomeTabType.diary || HomeTabType.statistics => null,
      HomeTabType.settings => const HomeContextFab(),
    };
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);

    return Scaffold(
      extendBody: true,
      appBar: HomeTopBar(
        title: _titleForTab(l10n, selectionState),
        titleColor:
            currentTab == HomeTabType.inventory ||
                currentTab == HomeTabType.diary ||
                currentTab == HomeTabType.statistics
            ? AppInventoryEditorial.primary
            : null,
        actions: _buildActions(
          context,
          ref,
          l10n,
          selectionState,
          currentCalorieSettings,
        ),
      ),
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: HomeBottomNavBar(
        entries: _navEntries(context, l10n),
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

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onDiaryActionSelected({
    required _DiaryAppBarAction action,
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) async {
    switch (action) {
      case _DiaryAppBarAction.setGoal:
        final currentGoal =
            ref
                .read(calorieGoalControllerProvider)
                .asData
                ?.value
                .dailyKcalGoal ??
            defaultDailyCalorieGoalKcal;
        await showCalorieGoalDialog(
          context: context,
          currentGoal: currentGoal,
          onSaveGoal: ref.read(calorieGoalControllerProvider.notifier).setGoal,
          onClearGoal: ref
              .read(calorieGoalControllerProvider.notifier)
              .clearGoal,
        );
        return;
      case _DiaryAppBarAction.shiftGoalStart:
        final currentSettings = ref
            .read(calorieGoalControllerProvider)
            .asData
            ?.value;
        if (currentSettings == null || !currentSettings.hasGoal) {
          return;
        }
        final currentGoalEntry = currentSettings.sortedGoalHistory.lastWhere(
          (entry) => entry.hasGoal,
        );
        await showCalorieGoalStartDialog(
          context: context,
          initialGoalStartAt: currentGoalEntry.effectiveChangedAt,
          onSaveGoalStart: (goalStartAt) {
            return ref
                .read(calorieGoalControllerProvider.notifier)
                .shiftGoalStart(goalStartAt: goalStartAt);
          },
        );
        return;
      case _DiaryAppBarAction.calculator:
        final currentSettings =
            ref.read(calorieGoalControllerProvider).asData?.value ??
            const CalorieGoalSettings.empty();
        await showCalorieGoalCalculatorSheet(
          context,
          initialSettings: currentSettings,
        );
        return;
    }
  }
}
