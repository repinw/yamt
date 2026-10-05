import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_list_view_controller.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_content.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_home_shell_top_chrome.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_empty_state.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entries_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_top_controls_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_quick_filter_chips.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_groups_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_sort_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The flat Vorrat list: search with Sortieren and Liste/Kacheln, quick
/// filter chips, and the foods and meals as rows, tiles, or receipt groups.
class InventoryList extends ConsumerStatefulWidget {
  /// Creates the list.
  const new({
    required this.onOpenMeal,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.onItemLongPress,
    required this.onSelectionToggle,
    super.key,
    this.includeHomeShellChrome = false,
    this.topChromeActions = const <Widget>[],
  });

  /// Opens the detail page of a prepared meal.
  final ValueChanged<PreparedMeal> onOpenMeal;

  /// Whether the list selects foods.
  final bool isSelectionMode;

  /// Selected food ids.
  final Set<String> selectedItemIds;

  /// Starts the selection with a food.
  final ValueChanged<String> onItemLongPress;

  /// Toggles a food in selection mode.
  final ValueChanged<String> onSelectionToggle;

  /// Whether to render the shared home shell app bar as a sliver.
  final bool includeHomeShellChrome;

  /// Tools of the home shell header.
  final List<Widget> topChromeActions;

  @override
  ConsumerState<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<InventoryList> {
  final _voiceSearchController = TextVoiceSearchController();
  final _searchController = TextEditingController();
  late final VoiceSearchService _voiceSearchService = ref.read(
    voiceSearchServiceProvider,
  );

  @override
  void dispose() {
    _voiceSearchController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  InventoryListViewController get _controller =>
      ref.read(inventoryListViewControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(inventoryListViewControllerProvider);
    final content = ref.watch(inventoryListContentProvider).value;
    final enabled = !widget.isSelectionMode;
    final horizontalPadding = responsivePageHorizontalPadding(context);

    return CustomScrollView(
      slivers: [
        if (widget.includeHomeShellChrome)
          const InventoryHomeShellStatusBarSliver(),
        if (widget.includeHomeShellChrome)
          InventoryHomeShellTopChrome(
            tools: widget.topChromeActions,
            stockCount: content?.stockCount,
          ),
        InventoryListTopControlsSliver(
          showSearch: content?.hasSource ?? false,
          searchController: _searchController,
          enabled: enabled,
          onSearchChanged: _controller.setQuery,
          onShowSort: () => unawaited(showInventorySortSheet(context)),
          viewMode: view.preferences.viewMode,
          onToggleViewMode: _controller.toggleViewMode,
          voiceSearchService: _voiceSearchService,
          voiceSearchController: _voiceSearchController,
          l10n: l10n,
        ),
        if (content != null &&
            content.hasSource &&
            content.receiptGroups == null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: InventoryQuickFilterChips(
                selected: view.quickFilter,
                counts: content.counts,
                enabled: enabled,
                onSelected: _controller.setQuickFilter,
              ),
            ),
          ),
        if (content != null) _body(context, l10n, content, view),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    InventoryListContent content,
    InventoryListViewState view,
  ) {
    if (!content.hasSource) {
      return const _EmptySliver();
    }
    final receiptGroups = content.receiptGroups;
    if (receiptGroups != null) {
      return InventoryReceiptGroupsSliver(
        groups: receiptGroups,
        dateFormat: DateFormat.yMMMd(
          Localizations.localeOf(context).toLanguageTag(),
        ),
        selection: ReceiptGroupSelectionOptions(
          isSelectionMode: widget.isSelectionMode,
          selectedItemIds: widget.selectedItemIds,
          onItemLongPress: widget.onItemLongPress,
          onSelectionToggle: widget.onSelectionToggle,
        ),
      );
    }
    if (content.entries.isEmpty) {
      return _EmptySliver(message: l10n.inventoryFilteredEmptyState);
    }
    return InventoryEntriesSliver(
      entries: content.entries,
      viewMode: view.preferences.viewMode,
      isSelectionMode: widget.isSelectionMode,
      selectedItemIds: widget.selectedItemIds,
      onOpenMeal: widget.onOpenMeal,
      onItemLongPress: widget.onItemLongPress,
      onSelectionToggle: widget.onSelectionToggle,
    );
  }
}

class _EmptySliver extends StatelessWidget {
  const new({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: AppInsets.pageLarge,
        child: Align(
          alignment: Alignment.topCenter,
          child: InventoryEmptyState(message: message),
        ),
      ),
    );
  }
}
