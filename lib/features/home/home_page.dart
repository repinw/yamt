import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/features/home/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
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
class HomePage extends ConsumerStatefulWidget {
  /// The home page.
  const HomePage({required this.navigationShell, super.key});

  /// The navigation shell.
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final _HomeShellChromeVisibilityController _chromeVisibilityController;

  @override
  void initState() {
    super.initState();
    _chromeVisibilityController = _HomeShellChromeVisibilityController();
  }

  @override
  void dispose() {
    _chromeVisibilityController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _chromeVisibilityController.reveal();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  HomeTabType _currentTab() {
    return switch (widget.navigationShell.currentIndex) {
      _inventoryBranchIndex => HomeTabType.inventory,
      _diaryBranchIndex => HomeTabType.diary,
      _cookbookBranchIndex => HomeTabType.cookbook,
      _statisticsBranchIndex => HomeTabType.statistics,
      _settingsBranchIndex => HomeTabType.settings,
      _ => HomeTabType.inventory, // coverage:ignore-line
    };
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentTab = _currentTab();
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
        body: NotificationListener<ScrollNotification>(
          onNotification: _chromeVisibilityController.handleScrollNotification,
          child: Stack(
            children: [
              widget.navigationShell,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: _chromeVisibilityController,
                  child: HomeBottomNavBar(
                    entries: _navEntries(context, l10n),
                  ),
                  builder: (context, visibility, bottomNavBar) {
                    return HomeShellBottomChrome(
                      visibility: visibility,
                      child: bottomNavBar!,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        floatingActionButton: floatingActionButton == null
            ? const SizedBox.shrink()
            : ValueListenableBuilder<double>(
                valueListenable: _chromeVisibilityController,
                child: floatingActionButton,
                builder: (context, visibility, fab) {
                  return HomeShellFloatingActionButtonChrome(
                    visibility: visibility,
                    child: fab!,
                  );
                },
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

  void _showMoreMenu(BuildContext context, AppLocalizations l10n) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        useRootNavigator: true,
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
}

class _HomeShellChromeVisibilityController extends ValueNotifier<double> {
  _HomeShellChromeVisibilityController() : super(1);

  static const _hideScrollDistance = 320;
  static const _revealScrollDistance = 140;
  static const _topRevealThreshold = 8;

  double get visibility => value;

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        notification.metrics.maxScrollExtent <=
            notification.metrics.minScrollExtent) {
      return false;
    }

    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null) {
      _updateFromScrollDelta(notification.scrollDelta!);
    } else if (notification.metrics.pixels <=
        notification.metrics.minScrollExtent + _topRevealThreshold) {
      reveal();
    }

    return false;
  }

  void reveal() {
    _setVisibility(1);
  }

  void _updateFromScrollDelta(double scrollDelta) {
    if (scrollDelta == 0) {
      return;
    }

    final scrollDistance = scrollDelta > 0
        ? _hideScrollDistance
        : _revealScrollDistance;
    final nextVisibility = (visibility - (scrollDelta / scrollDistance)).clamp(
      0.0,
      1.0,
    );
    _setVisibility(nextVisibility);
  }

  void _setVisibility(double value) {
    final targetVisibility = value.clamp(0.0, 1.0);
    if ((visibility - targetVisibility).abs() < 0.001) {
      return;
    }

    this.value = targetVisibility;
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
