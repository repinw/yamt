import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/core/widgets/content_visibility.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_nav_entry.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';
import 'package:yamt/core/widgets/home_shell_bottom_chrome.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/core/widgets/home_shell_floating_action_button_chrome.dart';
import 'package:yamt/core/widgets/home_shell_menu_scope.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_dock.dart';
import 'package:yamt/features/home/widgets/home_menu_drawer.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome_visibility_controller.dart';
import 'package:yamt/features/home/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryBranchIndex = 0;
const _diaryBranchIndex = 1;
const _cookbookBranchIndex = 2;
const _progressBranchIndex = 3;

/// Shell page that hosts the main app tabs and shared home chrome.
class HomePage extends ConsumerStatefulWidget {
  /// The home page.
  const new({required this.navigationShell, super.key});

  /// The navigation shell.
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  late final HomeShellChromeVisibilityController _chromeVisibilityController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RouteObserver<ModalRoute<void>>? _routeObserver;

  /// Whether a sheet, dialog, or page covers the shell.
  var _isCovered = false;

  @override
  void initState() {
    super.initState();
    _chromeVisibilityController = HomeShellChromeVisibilityController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_routeObserver == null && route != null) {
      final observer = ref.read(appRouteObserverProvider)
        ..subscribe(this, route);
      _routeObserver = observer;
    }
  }

  @override
  void didPushNext() => setState(() => _isCovered = true);

  @override
  void didPopNext() => setState(() => _isCovered = false);

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
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

  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  HomeTabType _currentTab() {
    return switch (widget.navigationShell.currentIndex) {
      _inventoryBranchIndex => HomeTabType.inventory,
      _diaryBranchIndex => HomeTabType.diary,
      _cookbookBranchIndex => HomeTabType.cookbook,
      _progressBranchIndex => HomeTabType.progress,
      _ => HomeTabType.inventory, // coverage:ignore-line
    };
  }

  List<HomeNavEntry> _navEntries(BuildContext context, AppLocalizations l10n) {
    final currentTab = _currentTab();
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
          icon: Icons.insights_rounded,
          label: l10n.homeProgress,
        ),
        isSelected: currentTab == HomeTabType.progress,
        onTap: () => _onTabTapped(_progressBranchIndex),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentTab = _currentTab();
    final floatingActionButton = switch (currentTab) {
      HomeTabType.inventory => _buildInventoryFab(ref),
      // Keeps floating snack bars above the diary's quick-eat dock.
      HomeTabType.diary => const SizedBox(height: diaryQuickEatDockHeight),
      HomeTabType.cookbook || HomeTabType.progress => null,
    };

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: const HomeMenuDrawer(),
      body: NotificationListener<ScrollNotification>(
        onNotification: _chromeVisibilityController.handleScrollNotification,
        child: HomeShellMenuScope(
          openMenu: _openMenu,
          child: Stack(
            children: [
              ContentVisibility(
                isVisible: !_isCovered,
                child: widget.navigationShell,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: _chromeVisibilityController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The dock sits on the navigation bar and hides with
                      // it.
                      if (currentTab == HomeTabType.diary)
                        const DiaryQuickEatDock(),
                      HomeBottomNavBar(entries: _navEntries(context, l10n)),
                    ],
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      // The chrome wraps an empty slot too: floating snack bars sit above the
      // floating action button slot, so they clear the bottom navigation.
      floatingActionButton: ValueListenableBuilder<double>(
        valueListenable: _chromeVisibilityController,
        child: floatingActionButton ?? const SizedBox.shrink(),
        builder: (context, visibility, fab) {
          return HomeShellFloatingActionButtonChrome(
            visibility: visibility,
            child: fab!,
          );
        },
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
}
