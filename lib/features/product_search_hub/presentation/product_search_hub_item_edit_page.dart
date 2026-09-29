import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Product editor for a Vorrat item that already exists. It opens with the
/// item's values and saves with "Speichern"; the edited item comes back as
/// the result of the route.
class ProductSearchHubItemEditPage extends ConsumerWidget {
  /// Creates the page for the item with [itemId].
  const new({required this.itemId, super.key});

  /// Id of the Vorrat item.
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final item = ref.watch(
      inventoryQuickEatItemsProvider.select(
        (items) => items.value?.firstWhereOrNull((item) => item.id == itemId),
      ),
    );
    if (item == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return InventoryReceiptManualProductEditorPage(
      // The editor reads the item once; later stock changes do not reset
      // the form.
      key: ValueKey(item.id),
      config: InventoryReceiptManualProductConfig(item: item),
      showEatImmediatelyOption: false,
      initialAction: InventoryReceiptManualProductAction.addToInventory,
      showActionSelector: false,
      confirmLabel: l10n.productEditorSaveAction,
    );
  }
}
