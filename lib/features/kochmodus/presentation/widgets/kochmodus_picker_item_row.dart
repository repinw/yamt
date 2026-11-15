import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entry_row.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One Vorrat row of the picker; a tapped row carries its place in the tap
/// order on its picture. Every row with nothing left for the line says for
/// which run it is planned ("für Pfannkuchen verplant", [holder]) or just
/// "verplant"; only a suggestion ([match]) says what is missing ("300
/// fehlen").
class KochmodusPickerItemRow extends StatelessWidget {
  /// Creates the row of [offer].
  const new({
    required this.offer,
    required this.match,
    required this.holder,
    required this.number,
    required this.tiltLeft,
    required this.onTap,
    super.key,
  });

  /// The item as the picker offers it.
  final KochmodusOffer offer;

  /// Whether the item's name resembles the line ("Passt vielleicht").
  final bool match;

  /// The name of another run that takes something of the item, or `null`.
  final String? holder;

  /// The place in the tap order from 1, or 0 when not tapped.
  final int number;

  /// Whether the picture tilts to the left; rows alternate.
  final bool tiltLeft;

  /// Taps or untaps the item.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final held = offer.held && offer.reserved > 0;
    final holder = this.holder;
    return Semantics(
      selected: number > 0,
      child: Stack(
        children: [
          InventoryEntryRow(
            entry: InventoryFoodEntry(offer.item),
            tiltLeft: tiltLeft,
            planned: offer.reserved,
            missing: match && !held ? offer.missing : 0,
            status: !held
                ? null
                : holder == null
                ? l10n.kochmodusPickerHeld
                : l10n.kochmodusPickerHeldFor(holder),
            onTap: onTap,
          ),
          if (number > 0)
            PositionedDirectional(
              top: AppSpacing.xs,
              start: 0,
              child: IgnorePointer(
                child: CircleAvatar(
                  radius: AppGraphit.chipIcon,
                  backgroundColor: colors.ink,
                  foregroundColor: colors.paper,
                  child: Text(
                    '$number',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.paper,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
