import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_date_utils.dart';
import 'package:yamt/features/diary/provider/diary_calendar_controller.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryBranchIndex = 0;
const _diaryBranchIndex = 1;
const _statisticsBranchIndex = 2;
const _settingsBranchIndex = 3;

/// Shell page that hosts the main app tabs and shared home chrome.
@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
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
      _statisticsBranchIndex => HomeTabType.statistics,
      _settingsBranchIndex => HomeTabType.settings,
      _ => HomeTabType.inventory, // coverage:ignore-line
    };
  }

  String _titleForTab(
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
    DiaryCalendarState? diaryCalendarState,
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
            ? 'Heute'
            : diaryWeekdayFullLabel(diaryCalendarState!.selectedDay);
      case HomeTabType.statistics:
        return l10n.homeStatistics;
      case HomeTabType.settings:
        return l10n.homeSettings;
    }
  }

  String? _subtitleForTab(DiaryCalendarState? diaryCalendarState) {
    if (diaryCalendarState == null) {
      return null;
    }

    return formatDiaryHeaderDate(diaryCalendarState.selectedDay);
  }

  String? _diaryWeekDayLabel(
    DiaryCalendarState? diaryCalendarState,
    CalorieWeekOverview? weekOverview,
  ) {
    if (diaryCalendarState == null || weekOverview == null) {
      return null;
    }

    final elapsedDays = normalizeDiaryDay(
      diaryCalendarState.selectedDay,
    ).difference(normalizeDiaryDay(weekOverview.balanceStartDate)).inDays;
    final cycleDay = elapsedDays < 0 ? 1 : elapsedDays + 1;
    final weekNumber = ((cycleDay - 1) ~/ 7) + 1;
    final dayNumber = ((cycleDay - 1) % 7) + 1;
    return 'Woche $weekNumber Tag $dayNumber';
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
          icon: Icons.menu_book_rounded,
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
        item: HomeNavItem(
          icon: Icons.settings_rounded,
          label: l10n.homeSettings,
        ),
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
    bool useCompactSelectionActions,
    DiaryCalendarState? diaryCalendarState,
    String? diaryWeekDayLabel,
  ) {
    final colors = Theme.of(context).colorScheme;
    if (_currentTab() == HomeTabType.inventory &&
        selectionState.isSelectionMode) {
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
            tooltip: l10n.preparedMealBindAction,
            onPressed: selectionState.selectedCount >= 2
                ? () {
                    ref
                        .read(preparedMealSelectionControllerProvider.notifier)
                        .requestCreateMeal();
                  }
                : null,
            icon: const Icon(Icons.restaurant_menu_rounded),
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
              backgroundColor: colors.primary.withValues(alpha: 0.12),
              foregroundColor: colors.primary,
            ),
          ),
          IconButton(
            tooltip: l10n.homeShopping,
            onPressed: () => context.push(AppRoutes.homeShopping),
            icon: const Icon(Icons.shopping_cart_rounded),
          ),
        ];
      case HomeTabType.diary:
        final actions = <Widget>[
          if (diaryWeekDayLabel != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  diaryWeekDayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ];

        if (diaryCalendarState == null || diaryCalendarState.isSelectedToday) {
          return actions;
        }

        actions.add(
          TextButton(
            onPressed: () {
              ref.read(diaryCalendarControllerProvider.notifier).selectToday();
            },
            child: const Text('Heute'),
          ),
        );

        if (actions.isEmpty) {
          return const <Widget>[];
        }

        return actions;
      case HomeTabType.statistics:
        return const <Widget>[];
      case HomeTabType.settings:
        return const <Widget>[];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final currentTab = _currentTab();
    final compactHomeChrome = shouldUseCompactHomeChrome(context);
    final diaryCalendarState = currentTab == HomeTabType.diary
        ? ref.watch(diaryCalendarControllerProvider)
        : null;
    final diaryWeekOverview = diaryCalendarState == null
        ? null
        : ref
              .watch(
                calorieWeekOverviewForWindowProvider(
                  diaryCalendarState.selectedDay,
                ),
              )
              .asData
              ?.value;
    final diaryWeekDayLabel = _diaryWeekDayLabel(
      diaryCalendarState,
      diaryWeekOverview,
    );
    final floatingActionButton = switch (currentTab) {
      HomeTabType.inventory => _buildInventoryFab(ref),
      HomeTabType.diary || HomeTabType.statistics => null,
      HomeTabType.settings => null,
    };
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);

    return Scaffold(
      extendBody: currentTab != HomeTabType.settings,
      appBar: HomeTopBar(
        title: _titleForTab(l10n, selectionState, diaryCalendarState),
        subtitle: _subtitleForTab(diaryCalendarState),
        titleColor: colors.primary,
        compact: compactHomeChrome,
        actions: _buildActions(
          context,
          ref,
          l10n,
          selectionState,
          compactHomeChrome,
          diaryCalendarState,
          diaryWeekDayLabel,
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
