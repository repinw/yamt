// Internal split widget is public only for sibling imports.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_text_styles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Portion stepper of the intro step: a caption, the count as a large
/// number field and a minus and a plus button on soft tiles.
class CookingFlowIntroPortionScaler extends StatefulWidget {
  const new({
    required this.originalPortions,
    required this.targetPortions,
    required this.onChanged,
  });

  final int originalPortions;
  final int targetPortions;
  final ValueChanged<double> onChanged;

  @override
  State<CookingFlowIntroPortionScaler> createState() =>
      _CookingFlowIntroPortionScalerState();
}

class _CookingFlowIntroPortionScalerState
    extends State<CookingFlowIntroPortionScaler> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _portionText(widget.targetPortions),
    );
  }

  @override
  void didUpdateWidget(CookingFlowIntroPortionScaler oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = _portionText(widget.targetPortions);
    if (_controller.text == nextText) {
      return;
    }
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final resolvedTargetPortions = widget.targetPortions < 1
        ? 1
        : widget.targetPortions;
    final canDecrease = resolvedTargetPortions > 1;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: <Widget>[
              Text(
                l10n.cookflowPortionScalerTitle.toUpperCase(),
                style: context.cookingFlowKickerStyle,
              ),
              Text(
                l10n.cookflowTargetPortionsFieldLabel,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _PortionStepButton(
          tooltip: l10n.inventoryItemEatSheetDecreasePortionCountAction,
          icon: Icons.remove_rounded,
          onPressed: canDecrease
              ? () => widget.onChanged((resolvedTargetPortions - 1).toDouble())
              : null,
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: AppGraphit.numberField,
          child: TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            cursorColor: colors.ink,
            onChanged: (value) {
              final portions = int.tryParse(value.trim());
              if (portions == null || portions < 1) {
                return;
              }
              widget.onChanged(portions.toDouble());
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: colors.tile,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              border: _fieldBorder,
              enabledBorder: _fieldBorder,
              focusedBorder: _fieldBorder,
            ),
            style: context.cookingFlowDisplayStyle(textTheme.headlineSmall),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _PortionStepButton(
          tooltip: l10n.inventoryItemEatSheetIncreasePortionCountAction,
          icon: Icons.add_rounded,
          onPressed: () =>
              widget.onChanged((resolvedTargetPortions + 1).toDouble()),
        ),
      ],
    );
  }

  OutlineInputBorder get _fieldBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide.none,
  );

  String _portionText(int value) {
    final resolvedValue = value < 1 ? 1 : value;
    return resolvedValue.toString();
  }
}

/// Minus or plus of the stepper: an icon on a soft tile. Like prev and next,
/// it is one of the few actions that needs no word.
class _PortionStepButton extends StatelessWidget {
  const new({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final isEnabled = onPressed != null;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.tile,
        foregroundColor: isEnabled ? colors.ink : colors.muted,
        minimumSize: const Size.square(AppGraphit.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      icon: Icon(icon, size: AppGraphit.toolIcon),
    );
  }
}
