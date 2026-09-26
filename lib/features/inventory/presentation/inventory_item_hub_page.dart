import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Runs a hub action on top of the hub. Returns whether it changed the item.
/// A changed item closes the hub, except after adding it to the shopping
/// list.
typedef InventoryItemHubActionRunner = Future<bool> Function(
  BuildContext hubContext,
  InventoryItemHubAction,
);

/// Item hub: the eat page of a stock item plus the item's own actions.
///
/// Pops with the entered eat request. The actions run while the hub stays
/// open, so cancelling one returns to the hub. An item without stock to eat
/// shows only its actions, and the main button puts it on the shopping list.
class InventoryItemHubPage extends StatefulWidget {
  /// Creates the hub for [item].
  const new({
    required this.item,
    required this.isOnShoppingList,
    required this.onAction,
    super.key,
  });

  /// The stock item.
  final InventoryItem item;

  /// Whether the item is already on the shopping list.
  final bool isOnShoppingList;

  /// Runs a picked action.
  final InventoryItemHubActionRunner onAction;

  @override
  State<InventoryItemHubPage> createState() => _InventoryItemHubPageState();
}

class _InventoryItemHubPageState extends State<InventoryItemHubPage> {
  // The card sits below the page's own snackbar messenger, so its context
  // shows action hints on the hub.
  final GlobalKey _cardKey = GlobalKey();
  var _isRunning = false;
  late bool _isOnShoppingList = widget.isOnShoppingList;

  @override
  Widget build(BuildContext context) {
    final actions = EatItemActionsCard(
      key: _cardKey,
      isOnShoppingList: _isOnShoppingList,
      onPicked: _run,
    );
    if (consumableInventoryAmount(widget.item) == null) {
      return _UsedUpHubBody(
        item: widget.item,
        isOnShoppingList: _isOnShoppingList,
        actions: actions,
        onAddToShoppingList: () =>
            _run(InventoryItemHubAction.addToShoppingList),
      );
    }
    return InventoryItemEatSheetBody(
      item: widget.item,
      confirmIntent: InventoryItemEatSheetIntent.logOnly,
      footer: actions,
      onSubmitted: (result) => Navigator.of(context).pop(result.request),
    );
  }

  Future<void> _run(InventoryItemHubAction action) async {
    final hubContext = _cardKey.currentContext;
    if (_isRunning || hubContext == null) {
      return;
    }
    _isRunning = true;
    try {
      final changed = await widget.onAction(hubContext, action);
      if (!changed || !mounted) {
        return;
      }
      if (action == InventoryItemHubAction.addToShoppingList) {
        setState(() => _isOnShoppingList = true);
        return;
      }
      Navigator.of(context).pop();
    } finally {
      _isRunning = false;
    }
  }
}

class _UsedUpHubBody extends StatelessWidget {
  const new({
    required this.item,
    required this.isOnShoppingList,
    required this.actions,
    required this.onAddToShoppingList,
  });

  final InventoryItem item;
  final bool isOnShoppingList;
  final Widget actions;
  final VoidCallback onAddToShoppingList;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EatPageScaffold(
      whenControl: const SizedBox.shrink(),
      kcal: null,
      confirmButtonKey: const Key('inventory_item_hub_shopping_list_button'),
      confirmLabel: l10n.inventoryItemAddToListAction,
      onConfirm: isOnShoppingList ? null : onAddToShoppingList,
      cancelButtonKey: const Key('inventory_item_hub_close_button'),
      children: [
        EatPageHeader(
          title: item.name,
          brand: item.brand,
          imageUrl: item.imageUrl,
        ),
        actions,
      ],
    );
  }
}
