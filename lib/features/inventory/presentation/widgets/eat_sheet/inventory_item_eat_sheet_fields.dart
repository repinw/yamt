import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_portion_count.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_text_field.dart';

/// The text fields of the item eat page, kept in step with its state.
class InventoryItemEatSheetFields {
  /// Amount in the item's unit.
  final inventoryAmount = EatSheetTextField();

  /// Number of pieces or portions.
  final pieceCount = EatSheetTextField();

  /// Weight of one piece.
  final pieceWeight = EatSheetTextField();

  /// Amount that is not eaten, such as a peel.
  final inedibleAmount = EatSheetTextField();

  /// Shows the texts of [state] in the fields.
  void sync(InventoryItemEatSheetState state) {
    if (countsWeightPortions(state)) {
      inventoryAmount.syncValue(
        portionWeightText(state),
        parsePositiveDecimalInput,
      );
    } else {
      inventoryAmount.sync(state.inventoryAmountText);
    }
    pieceCount.sync(state.portionCountText);
    pieceWeight.sync(state.portionAmountText);
    inedibleAmount.sync(state.inedibleAmountText);
  }

  /// Releases all fields.
  void dispose() {
    for (final field in [
      inventoryAmount,
      pieceCount,
      pieceWeight,
      inedibleAmount,
    ]) {
      field.dispose();
    }
  }
}
