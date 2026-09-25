import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_inline_amount_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_text_link.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Link that opens a field for the inedible part of a food, such as bones.
class EatInedibleLine extends StatelessWidget {
  /// Creates the inedible line.
  const new({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.unitLabel,
    required this.summaryText,
    required this.isExpanded,
    required this.onChanged,
    required this.onToggleExpanded,
    super.key,
  });

  /// Link that opens and closes the field.
  static const toggleKey = Key('inventory_item_inedible_amount_toggle');

  /// Inedible amount field.
  static const fieldKey = Key('inventory_item_inedible_amount_dialog_field');

  /// Text controller of the amount field.
  final TextEditingController controller;

  /// Focus node of the amount field.
  final FocusNode focusNode;

  /// Error text under the field.
  final String? errorText;

  /// Unit after the amount.
  final String unitLabel;

  /// Text of the link.
  final String summaryText;

  /// Whether the field is visible.
  final bool isExpanded;

  /// Called when the text changes.
  final ValueChanged<String> onChanged;

  /// Called when the link is tapped.
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EatTextLink(
          buttonKey: toggleKey,
          label: summaryText,
          isMuted: true,
          onPressed: onToggleExpanded,
        ),
        if (isExpanded)
          EatInlineAmountField(
            fieldKey: fieldKey,
            label: l10n.inventoryItemEatSheetInedibleAmountFieldLabel,
            unitLabel: unitLabel,
            controller: controller,
            focusNode: focusNode,
            errorText: errorText,
            onChanged: onChanged,
          ),
      ],
    );
  }
}
