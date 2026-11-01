import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_step_frame.dart';
import 'package:yamt/features/kitchen_utensils/application/kitchen_utensil_list_provider.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The pot question: a saved utensil with its empty weight, or none. Nothing
/// is chosen at first; "Fertig gekocht" waits for a choice.
class CookPotStep extends ConsumerWidget {
  /// Creates the step with the chosen [pot].
  const new({
    required this.pot,
    required this.onPot,
    required this.onNext,
    super.key,
  });

  /// Key of the choice without a pot.
  static const noPotKey = ValueKey<String>('cook-pot-none');

  /// Key of the utensil [utensilId].
  static ValueKey<String> utensilKey(String utensilId) =>
      ValueKey('cook-pot-$utensilId');

  /// The chosen pot, `null` while none is chosen.
  final CookPot? pot;

  /// Chooses a pot.
  final ValueChanged<CookPot> onPot;

  /// Goes on to portioning.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final utensilsAsync = ref.watch(kitchenUtensilListProvider);
    final utensils = utensilsAsync.value ?? const <KitchenUtensil>[];
    final pot = this.pot;
    return CookStepFrame(
      title: l10n.cookPotTitle,
      hint: l10n.cookPotHint,
      buttonLabel: l10n.cookDoneCooking,
      onButton: pot == null ? null : onNext,
      children: [
        if (utensilsAsync.isLoading && !utensilsAsync.hasValue)
          const AppLoadingView()
        else if (utensilsAsync.hasError && !utensilsAsync.hasValue)
          AppErrorRetryView(
            message: l10n.cookPotLoadFailed,
            retryLabel: l10n.inventoryRetryAction,
            onRetry: () => ref.invalidate(kitchenUtensilListProvider),
          ),
        for (final utensil in utensils)
          _PotTile(
            key: utensilKey(utensil.id),
            title: utensil.hasName ? utensil.name! : l10n.cookPotUnnamed,
            subtitle: l10n.cookPotEmptyWeight(utensil.weightGrams),
            selected: pot is CookPotUtensil && pot.utensilId == utensil.id,
            onTap: () => onPot(
              CookPotUtensil(
                utensilId: utensil.id,
                emptyWeight: utensil.weightGrams,
              ),
            ),
          ),
        _PotTile(
          key: noPotKey,
          title: l10n.cookPotNone,
          selected: pot is CookPotNone,
          onTap: () => onPot(const CookPotNone()),
        ),
      ],
    );
  }
}

class _PotTile extends StatelessWidget {
  const new({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final subtitle = this.subtitle;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        selected: selected,
        selectedColor: colors.ink,
        onTap: onTap,
        leading: Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
      ),
    );
  }
}
