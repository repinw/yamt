import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_entry_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Foods picked on [InventoryCombinePickPage]: ticked stock items in list
/// order, and a food found by search.
typedef InventoryCombinePickResult = ({
  List<InventoryItem> stock,
  InventoryReceiptManualProductResult? searched,
});

/// Opens the inventory list to pick the foods to log together with the
/// item hub's item. Returns null when the user closes it.
Future<InventoryCombinePickResult?> showInventoryCombinePickPage(
  BuildContext context, {
  required List<InventoryItem> candidates,
  bool canSearch = true,
}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<InventoryCombinePickResult>(
    MaterialPageRoute<InventoryCombinePickResult>(
      fullscreenDialog: true,
      builder: (_) => InventoryCombinePickPage(
        candidates: candidates,
        canSearch: canSearch,
      ),
    ),
  );
}

/// The inventory list in selection mode, showing only [candidates].
class InventoryCombinePickPage extends StatefulWidget {
  /// Creates the page.
  const new({required this.candidates, this.canSearch = true, super.key});

  /// Key of the button that takes over the selection.
  static const confirmKey = Key('inventory_combine_pick_confirm');

  /// Key of the button that searches for a food outside the stock.
  static const searchKey = Key('inventory_combine_pick_search');

  /// Key of the hint shown when no stock item is left to pick.
  static const emptyKey = Key('inventory_combine_pick_empty');

  /// Stock items that can be combined.
  final List<InventoryItem> candidates;

  /// Whether a food outside the stock can be searched.
  final bool canSearch;

  @override
  State<InventoryCombinePickPage> createState() =>
      _InventoryCombinePickPageState();
}

class _InventoryCombinePickPageState extends State<InventoryCombinePickPage> {
  var _selected = const <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected.isEmpty
              ? l10n.inventoryPageTitle
              : l10n.preparedMealSelectionCount(_selected.length),
        ),
        actions: [
          if (widget.canSearch)
            IconButton(
              key: InventoryCombinePickPage.searchKey,
              tooltip: l10n.eatPageCombineSearch,
              onPressed: _search,
              icon: const Icon(Icons.search_rounded),
            ),
          TextButton(
            key: InventoryCombinePickPage.confirmKey,
            onPressed: _selected.isEmpty ? null : _confirm,
            child: Text(l10n.eatPageCombinePickConfirm),
          ),
        ],
      ),
      body: widget.candidates.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  l10n.eatPageCombineNoMoreStock,
                  key: InventoryCombinePickPage.emptyKey,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: widget.candidates.length,
              itemBuilder: (context, index) {
                final item = widget.candidates[index];
                return InventoryEntryRow(
                  key: ValueKey('combine_pick_row_${item.id}'),
                  entry: InventoryFoodEntry(item),
                  tiltLeft: index.isEven,
                  isSelectionMode: true,
                  isSelected: _selected.contains(item.id),
                  onTap: () => _toggle(item.id),
                );
              },
            ),
    );
  }

  void _toggle(String itemId) {
    setState(() {
      _selected = _selected.contains(itemId)
          ? ({..._selected}..remove(itemId))
          : {..._selected, itemId};
    });
  }

  List<InventoryItem> get _selectedItems => [
    for (final item in widget.candidates)
      if (_selected.contains(item.id)) item,
  ];

  void _confirm() {
    Navigator.of(context).pop((stock: _selectedItems, searched: null));
  }

  Future<void> _search() async {
    final result = await context.push<InventoryReceiptManualProductResult>(
      AppRoutes.homeFoodPick,
    );
    if (result == null || !mounted) {
      return;
    }
    Navigator.of(context).pop((stock: _selectedItems, searched: result));
  }
}
