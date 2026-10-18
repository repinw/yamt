import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_chip.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_photo_servings.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_piece_weight.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The choice between the piece the front read and the serving of the
/// nutrition table, shown only when the two differ.
class ManualProductServingChoice extends StatelessWidget {
  /// Creates the choice.
  const new({
    required this.servings,
    required this.countedInPieces,
    required this.onPickFront,
    super.key,
  });

  /// Key of the chip for the front's piece.
  static const frontKey = Key('manual_product_serving_front');

  /// Key of the chip for the table's serving.
  static const tableKey = Key('manual_product_serving_table');

  /// The servings the package photos read.
  final ManualProductPhotoServings servings;

  /// Whether the package is counted in pieces, so it takes the front's piece
  /// without a choice.
  final bool countedInPieces;

  /// Called with true when the user picks the front's piece.
  final ValueChanged<bool> onPickFront;

  @override
  Widget build(BuildContext context) {
    final front = servings.front;
    final table = servings.table;
    if (!servings.offersChoice(countedInPieces: countedInPieces) ||
        front == null ||
        table == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final picksFront = servings.prefersFront;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.productServingChoiceLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          EatChip(
            key: tableKey,
            label: _label(l10n, table),
            isSelected: !picksFront,
            onPressed: () => onPickFront(false),
          ),
          EatChip(
            key: frontKey,
            label: _label(l10n, front),
            isSelected: picksFront,
            onPressed: () => onPickFront(true),
          ),
        ],
      ),
    );
  }

  static String _label(AppLocalizations l10n, ManualProductServing serving) {
    final unit = serving.quantityUnit == 'ml'
        ? l10n.inventoryUnitMilliliter
        : l10n.caloriesUnitGram;
    return serving.size ??
        l10n.productServingAmount(
          formatManualProductDouble(serving.quantity),
          unit,
        );
  }
}
