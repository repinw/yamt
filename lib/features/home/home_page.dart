import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/core/widgets/content_visibility.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_more_sheet.dart';
import 'package:yamt/core/widgets/home_nav_action.dart';
import 'package:yamt/core/widgets/home_nav_entry.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/core/widgets/home_shell_menu_scope.dart';
import 'package:yamt/core/widgets/home_shell_more_scope.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_actions.dart';
import 'package:yamt/features/home/domain/home_action_ranking.dart';
import 'package:yamt/features/home/presentation/controllers/home_action_usage_controller.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';
import 'package:yamt/features/home/presentation/widgets/home_menu_panel.dart';
import 'package:yamt/features/home/presentation/widgets/home_slide_menu.dart';
import 'package:yamt/features/home/presentation/widgets/inventory_add_actions.dart';
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
  RouteObserver<ModalRoute<void>>? _routeObserver;

  /// Whether the side menu or the action panel is open.
  var _isMenuOpen = false;

  /// Whether the open panel is the action panel on the right; it stays set
  /// while the panel closes, so the right content slides away.
  var _showsActions = false;

  /// Whether a sheet, dialog, or page covers the shell.
  var _isCovered = false;

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
    super.dispose();
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _openMenu() => setState(() {
    _showsActions = false;
    _isMenuOpen = true;
  });

  void _openActions() => setState(() {
    _showsActions = true;
    _isMenuOpen = true;
  });

  void _closeMenu() => setState(() => _isMenuOpen = false);

  /// Opens the Mehr sheet with the actions of the current tab.
  void _openMore(String title, List<HomeMoreEntry> entries) {
    unawaited(
      showHomeMoreSheet(
        context,
        sections: [HomeMoreSection(title: title, entries: entries)],
      ),
    );
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

  /// Word of the action button of [tab], or `null` when the tab has no
  /// actions.
  String? _actionLabel(AppLocalizations l10n, HomeTabType tab) {
    return switch (tab) {
      HomeTabType.inventory => l10n.inventoryDockAddAction,
      HomeTabType.diary => l10n.homeActionEat,
      HomeTabType.cookbook || HomeTabType.progress => null,
    };
  }

  /// The actions of [tab] for the action panel.
  List<HomeMoreSection> _actions(HomeTabType tab) {
    return switch (tab) {
      HomeTabType.inventory => inventoryAddActions(context, ref),
      HomeTabType.diary => diaryQuickEatActions(context, ref),
      HomeTabType.cookbook || HomeTabType.progress => const <HomeMoreSection>[],
    };
  }

  /// The action panel of [tab]; its most used action is drawn in lime.
  Widget _buildActionPanel(HomeTabType tab) {
    final sections = _actions(tab);
    final counts = ref.watch(homeActionUsageControllerProvider);
    final mostUsed = mostUsedAction(counts, [
      for (final section in sections)
        for (final entry in section.entries) ?_usageId(entry),
    ]);
    return HomeActionPanel(
      sections: sections,
      onClose: _closeMenu,
      highlightedKey: mostUsed == null ? null : ValueKey<String>(mostUsed),
      onUsed: (entry) {
        if (_usageId(entry) case final id?) {
          unawaited(
            ref.read(homeActionUsageControllerProvider.notifier).record(id),
          );
        }
      },
    );
  }

  /// Id under which taps on [entry] are counted: its string key.
  String? _usageId(HomeMoreEntry entry) {
    return switch (entry.key) {
      ValueKey<String>(:final value) => value,
      _ => null,
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
    final actionLabel = _actionLabel(l10n, currentTab);
    // Keeps floating snack bars above the round action button.
    final floatingActionButton = actionLabel == null
        ? null
        : const SizedBox(height: AppGraphit.navActionOverhang);

    return HomeSlideMenu(
      isOpen: _isMenuOpen,
      onClose: _closeMenu,
      fromEnd: _showsActions,
      menu: _showsActions
          ? _buildActionPanel(currentTab)
          : HomeMenuPanel(onClose: _closeMenu),
      child: _buildShell(l10n, currentTab, floatingActionButton),
    );
  }

  Widget _buildShell(
    AppLocalizations l10n,
    HomeTabType currentTab,
    Widget? floatingActionButton,
  ) {
    return Scaffold(
      extendBody: true,
      body: HomeShellMenuScope(
        openMenu: _openMenu,
        child: HomeShellMoreScope(
          openMore: _openMore,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HomeBottomNavBar(
                      entries: _navEntries(context, l10n),
                      action: switch (_actionLabel(l10n, currentTab)) {
                        final label? => HomeNavAction(
                          label: label,
                          onPressed: _openActions,
                        ),
                        null => null,
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      // The slot stays even when empty: floating snack bars sit above the
      // floating action button slot, so they clear the bottom navigation.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: AppSizes.homeShellBottomBarClearance,
        ),
        child: floatingActionButton ?? const SizedBox.shrink(),
      ),
    );
  }
}
