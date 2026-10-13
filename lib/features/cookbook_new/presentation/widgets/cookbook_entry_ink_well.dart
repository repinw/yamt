import 'dart:async';

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The touch area of a Vorlage or recipe in the Kochbuch: a tap opens it,
/// and a long press opens a small menu with "Entfernen". Screen readers get
/// "Entfernen" as an action of its own.
class CookbookEntryInkWell extends StatelessWidget {
  /// Creates the touch area around [child].
  const new({
    required this.onOpen,
    required this.onRemove,
    required this.child,
    super.key,
  });

  /// Key of the "Entfernen" item in the long press menu.
  static const removeKey = ValueKey<String>('cookbook-entry-remove');

  /// Opens the Vorlage or recipe.
  final VoidCallback onOpen;

  /// Removes the Vorlage or recipe.
  final VoidCallback onRemove;

  /// The card.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final remove = AppLocalizations.of(context)!.cookbookRemoveAction;
    return Semantics(
      container: true,
      onLongPressHint: remove,
      customSemanticsActions: {CustomSemanticsAction(label: remove): onRemove},
      child: AppInkWell(
        onTap: onOpen,
        onLongPress: () => unawaited(_showMenu(context, remove)),
        child: child,
      ),
    );
  }

  /// Opens the menu over the card, like a [PopupMenuButton] over itself.
  Future<void> _showMenu(BuildContext context, String remove) async {
    final card = context.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final chosen = await showMenu<bool>(
      context: context,
      useRootNavigator: true,
      position: RelativeRect.fromRect(
        card.localToGlobal(Offset.zero, ancestor: overlay) & card.size,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<bool>(
          key: removeKey,
          value: true,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline_rounded),
            title: Text(remove),
          ),
        ),
      ],
    );
    if (chosen ?? false) {
      onRemove();
    }
  }
}
