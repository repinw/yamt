import 'dart:async';

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The touch area of a Vorlage or recipe in the Kochbuch: a tap opens it,
/// and a long press opens a small menu with "Planen" and "Entfernen".
/// Screen readers get both as actions of their own.
class CookbookEntryInkWell extends StatelessWidget {
  /// Creates the touch area around [child].
  const new({
    required this.onOpen,
    required this.onRemove,
    required this.onPlan,
    required this.child,
    super.key,
  });

  /// Key of the "Entfernen" item in the long press menu.
  static const removeKey = ValueKey<String>('cookbook-entry-remove');

  /// Key of the "Planen" item in the long press menu.
  static const planKey = ValueKey<String>('cookbook-entry-plan');

  /// Opens the Vorlage or recipe.
  final VoidCallback onOpen;

  /// Removes the Vorlage or recipe.
  final VoidCallback onRemove;

  /// Plans one portion of the Vorlage or recipe for a day.
  final VoidCallback onPlan;

  /// The card.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remove = l10n.cookbookRemoveAction;
    final plan = l10n.eatPagePlanIconTooltip;
    return Semantics(
      container: true,
      onLongPressHint: l10n.cookbookEntryMenuHint,
      customSemanticsActions: {
        CustomSemanticsAction(label: plan): onPlan,
        CustomSemanticsAction(label: remove): onRemove,
      },
      child: AppInkWell(
        onTap: onOpen,
        onLongPress: () => unawaited(_showMenu(context, plan, remove)),
        child: child,
      ),
    );
  }

  /// Opens the menu over the card, like a [PopupMenuButton] over itself.
  Future<void> _showMenu(
    BuildContext context,
    String plan,
    String remove,
  ) async {
    final card = context.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final chosen = await showMenu<VoidCallback>(
      context: context,
      useRootNavigator: true,
      position: RelativeRect.fromRect(
        card.localToGlobal(Offset.zero, ancestor: overlay) & card.size,
        Offset.zero & overlay.size,
      ),
      items: [
        _item(planKey, onPlan, Icons.event_rounded, plan),
        _item(removeKey, onRemove, Icons.delete_outline_rounded, remove),
      ],
    );
    chosen?.call();
  }

  PopupMenuItem<VoidCallback> _item(
    Key key,
    VoidCallback action,
    IconData icon,
    String label,
  ) => PopupMenuItem<VoidCallback>(
    key: key,
    value: action,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
    ),
  );
}
