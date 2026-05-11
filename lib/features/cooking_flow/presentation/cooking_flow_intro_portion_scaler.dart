// Internal split widget is public only for sibling imports.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CookingFlowIntroPortionScaler extends StatefulWidget {
  const CookingFlowIntroPortionScaler({
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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final resolvedOriginalPortions = widget.originalPortions < 1
        ? 1
        : widget.originalPortions;
    final resolvedTargetPortions = widget.targetPortions < 1
        ? 1
        : widget.targetPortions;
    final canDecrease = resolvedTargetPortions > 1;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(
          AppInventoryEditorial.cardRadius,
        ),
        blurRadius: 18,
        shadowOffset: const Offset(0, 8),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.cookflowPortionScalerTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.cookflowOriginalPortionsLabel(resolvedOriginalPortions),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: <Widget>[
                IconButton.outlined(
                  tooltip: l10n.inventoryItemEatSheetDecreasePortionCountAction,
                  onPressed: canDecrease
                      ? () => widget.onChanged(
                          (resolvedTargetPortions - 1).toDouble(),
                        )
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      final portions = int.tryParse(value.trim());
                      if (portions == null || portions < 1) {
                        return;
                      }
                      widget.onChanged(portions.toDouble());
                    },
                    decoration: InputDecoration(
                      labelText: l10n.cookflowTargetPortionsFieldLabel,
                      isDense: true,
                      filled: true,
                      fillColor: colors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: colors.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton.outlined(
                  tooltip: l10n.inventoryItemEatSheetIncreasePortionCountAction,
                  onPressed: () => widget.onChanged(
                    (resolvedTargetPortions + 1).toDouble(),
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _portionText(int value) {
    final resolvedValue = value < 1 ? 1 : value;
    return resolvedValue.toString();
  }
}
