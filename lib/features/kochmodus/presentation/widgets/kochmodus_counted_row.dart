import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "oder" between two rules, then "Ohne Topf" on "Töpfe": a radio row
/// that counts pieces instead of weighing pots; picking it unpicks the
/// pots.
class KochmodusCountedRow extends StatelessWidget {
  /// Creates the row, checked when [selected].
  const new({required this.selected, required this.onTap, super.key});

  /// Key of the radio row "Ohne Topf".
  static const tileKey = ValueKey<String>('kochmodus-pots-counted');

  /// Whether the cook counts pieces without a pot.
  final bool selected;

  /// Picks "Ohne Topf".
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(child: Divider(color: colors.rule)),
              Text(
                l10n.kochmodusPotsOr,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.muted),
              ),
              Expanded(child: Divider(color: colors.rule)),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? colors.ink : colors.rule,
              width: selected
                  ? AppSizes.selectedBorder
                  : AppSizes.dividerThickness,
            ),
          ),
          child: ListTile(
            key: tileKey,
            selected: selected,
            selectedColor: colors.ink,
            leading: Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? colors.ink : colors.muted,
            ),
            onTap: onTap,
            title: Text(l10n.kochmodusPotsCountedTitle),
            subtitle: Text(l10n.kochmodusPotsCountedHint),
          ),
        ),
      ],
    );
  }
}
