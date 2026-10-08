import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Up to 99999 g, so the weight always parses.
const _maxWeightDigits = 5;

/// The pot part of the eat page for a meal weighed in its pot: a reminder
/// to weigh again, the pot on the scale, and what that leaves in the pot.
class EatPotWeighingSection extends StatefulWidget {
  /// Creates the section for a pot that weighs [tareWeight] grams empty.
  const new({
    required this.tareWeight,
    required this.netWeight,
    required this.isTooLight,
    required this.showsReminder,
    required this.onChanged,
    super.key,
  });

  /// Key of the weight field.
  static const grossKey = Key('eat_pot_gross');

  /// Key of the reminder to weigh again.
  static const reminderKey = Key('eat_pot_reminder');

  /// Grams of the empty pot.
  final int tareWeight;

  /// Grams of food in the pot after the weighing, or null without one.
  final int? netWeight;

  /// Whether the typed weight is not above the empty pot.
  final bool isTooLight;

  /// Whether the last weighing is too old to trust.
  final bool showsReminder;

  /// Called with the typed weight of the pot on the scale.
  final ValueChanged<String> onChanged;

  @override
  State<EatPotWeighingSection> createState() => _EatPotWeighingSectionState();
}

class _EatPotWeighingSectionState extends State<EatPotWeighingSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.muted);
    final net = widget.netWeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        if (widget.showsReminder && net == null)
          Text(
            l10n.eatPotWeighReminder,
            key: EatPotWeighingSection.reminderKey,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink),
          ),
        Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: Text(
                l10n.eatPotWeighTitle,
                style: textTheme.titleSmall?.copyWith(color: colors.ink),
              ),
            ),
            SizedBox(
              width: AppGraphit.numberField,
              child: TextField(
                key: EatPotWeighingSection.grossKey,
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxWeightDigits),
                ],
                textAlign: TextAlign.center,
                decoration: InputDecoration(suffixText: l10n.inventoryUnitGram),
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
        if (net != null) ...[
          Text(l10n.eatPotNetWeight(widget.tareWeight, net), style: muted),
          Text(l10n.eatPotTakeOutHint, style: muted),
        ] else if (widget.isTooLight)
          Text(
            l10n.cookedTooLight,
            style: textTheme.bodySmall?.copyWith(color: colors.low),
          ),
      ],
    );
  }
}
