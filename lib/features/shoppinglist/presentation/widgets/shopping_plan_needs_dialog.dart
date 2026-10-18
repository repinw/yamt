import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_plan_needs.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The question whether the needs go on the shopping list, each one
/// tickable; pops with the ticked ones.
class ShoppingPlanNeedsDialog extends StatefulWidget {
  /// Creates the question for [needs].
  const new({required this.needs, super.key});

  /// Key of the button that adds the ticked needs.
  static const addKey = Key('shopping-plan-needs-dialog-add');

  /// Key of the button that closes the question.
  static const skipKey = Key('shopping-plan-needs-dialog-skip');

  /// Key of the tick box of the need at [index].
  static Key needKey(int index) => Key('shopping-plan-needs-dialog-$index');

  /// The needs to offer.
  final List<ShoppingPlanNeed> needs;

  @override
  State<ShoppingPlanNeedsDialog> createState() =>
      _ShoppingPlanNeedsDialogState();
}

class _ShoppingPlanNeedsDialogState extends State<ShoppingPlanNeedsDialog> {
  late final Set<ShoppingPlanNeed> _ticked = {...widget.needs};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.shoppingPlanNeedsDialogTitle(widget.needs.length)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shoppingPlanNeedsDialogMessage),
            for (final (index, need) in widget.needs.indexed)
              AppCheckboxListTile(
                key: ShoppingPlanNeedsDialog.needKey(index),
                contentPadding: EdgeInsets.zero,
                value: _ticked.contains(need),
                onChanged: (ticked) => setState(
                  () => ticked! ? _ticked.add(need) : _ticked.remove(need),
                ),
                title: Text(need.name),
                subtitle: Text(
                  shoppingPlanNeedSubtitle(need, l10n, l10n.localeName),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: ShoppingPlanNeedsDialog.skipKey,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shoppingPlanNeedsDialogSkip),
        ),
        FilledButton(
          key: ShoppingPlanNeedsDialog.addKey,
          onPressed: _ticked.isEmpty
              ? null
              : () => Navigator.of(context).pop([
                  for (final need in widget.needs)
                    if (_ticked.contains(need)) need,
                ]),
          child: Text(l10n.shoppingPlanNeedsDialogAdd),
        ),
      ],
    );
  }
}
