import 'dart:math' show max, min;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_presets.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/features/recipes/application/ingredient_exact_quantity.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What "Übernehmen" of the amount sheet changes: the cook's own amount, or
/// `null` to go back to the recipe's.
typedef KochmodusAmountChoice = ({int? own});

/// "Menge für dieses Kochen": a number field with − and + around what a line
/// needs, in the line's unit, and presets that fill it; the recipe stays as
/// it is. The field holds whole numbers, so an amount with a part of a unit
/// ("1/4 Zwiebel") stands empty with the part as its hint, never as the whole
/// number it rounds to, and taking it untouched changes nothing.
class KochmodusAmountSheet extends StatefulWidget {
  /// Creates the sheet for [line] of a cooking of [portions] portions.
  const new({required this.line, required this.portions, super.key});

  /// Key of "Übernehmen".
  static const applyKey = ValueKey<String>('kochmodus-amount-apply');

  /// Key of the number field.
  static const fieldKey = ValueKey<String>('kochmodus-amount-field');

  /// Key of the preset "Vorhandenes".
  static const ValueKey<String> availableKey =
      KochmodusAmountPresets.availableKey;

  /// Key of the preset "Rezept".
  static const ValueKey<String> recipeKey = KochmodusAmountPresets.recipeKey;

  /// Key of −.
  static const fewerKey = ValueKey<String>('kochmodus-amount-fewer');

  /// Key of +.
  static const moreKey = ValueKey<String>('kochmodus-amount-more');

  // What − and + change: one piece, or 50 g or ml.
  static const _pieceStep = 1;
  static const _massStep = 50;

  // The most the field holds, so that it cannot overflow.
  static const _maxAmount = 99999;
  static const _maxDigits = 5;

  /// The line.
  final KochmodusLineView line;

  /// The portions of the cooking.
  final int portions;

  /// Shows the sheet and returns what to change, or `null` when it is closed
  /// or nothing changes.
  static Future<KochmodusAmountChoice?> show(
    BuildContext context, {
    required KochmodusLineView line,
    required int portions,
  }) => showModalBottomSheet<KochmodusAmountChoice>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => KochmodusAmountSheet(line: line, portions: portions),
  );

  @override
  State<KochmodusAmountSheet> createState() => _KochmodusAmountSheetState();
}

class _KochmodusAmountSheetState extends State<KochmodusAmountSheet> {
  // What the empty field stands for when it cannot hold the amount: the line's
  // own part of a unit, or the recipe's after its preset.
  late TemplateIngredientRequirement? _part = cookNeedHasPart(widget.line.shown)
      ? widget.line.shown
      : null;

  late final _controller = TextEditingController(
    text: switch (widget.line.need) {
      null => '',
      final need => _part == null ? '${need.amount}' : '',
    },
  );

  int? get _value => int.tryParse(_controller.text);

  void _fill(int amount) {
    final text = '${min(amount, KochmodusAmountSheet._maxAmount)}';
    setState(
      () => _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  // "Rezept" for an amount with a part of a unit, which the field cannot hold.
  void _fillRecipePart() => setState(() {
    _part = widget.line.parsed;
    _controller.clear();
  });

  // What "Übernehmen" changes: nothing for an empty field that stands for what
  // the line has already.
  KochmodusAmountChoice? get _choice {
    final line = widget.line;
    if (_value case final value?) return (own: line.ownAmountFor(value));
    return identical(_part, line.parsed) && line.line.amount != null
        ? const (own: null)
        : null;
  }

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
    final need = widget.line.need;
    final parsed = widget.line.parsed;
    final value = _value;
    final part = _part;
    final step = widget.line.amountUnit == TemplateIngredientUnit.piece
        ? KochmodusAmountSheet._pieceStep
        : KochmodusAmountSheet._massStep;
    final fewer = value != null
        ? (value > 0 ? max(0, value - step) : null)
        : part?.exactQuantity?.floor();
    final more = value != null
        ? value + step
        : part?.exactQuantity?.ceil() ?? step;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.kochmodusAmountKicker.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.muted,
                    letterSpacing: AppGraphit.kickerTracking,
                  ),
                ),
                Text(
                  need?.name ?? widget.line.line.text,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (parsed != null)
                  Text(
                    l10n.kochmodusAmountRecipe(
                      kochmodusNeedText(l10n, parsed),
                      widget.portions,
                    ),
                    style: textTheme.bodySmall?.copyWith(color: colors.muted),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.lg,
              children: [
                IconButton.filledTonal(
                  key: KochmodusAmountSheet.fewerKey,
                  tooltip: l10n.cookFewer,
                  onPressed: fewer == null ? null : () => _fill(fewer),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Semantics(
                    label: need?.name ?? widget.line.line.text,
                    child: TextField(
                      key: KochmodusAmountSheet.fieldKey,
                      controller: _controller,
                      selectAllOnFocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          KochmodusAmountSheet._maxDigits,
                        ),
                      ],
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        hintText: part == null
                            ? '0'
                            : ingredientQuantityText(part),
                        suffixText: _unitLabel(l10n, widget.line),
                        suffixStyle: textTheme.titleMedium?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onTapUpOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  key: KochmodusAmountSheet.moreKey,
                  tooltip: l10n.cookMore,
                  onPressed: () => _fill(more),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            KochmodusAmountPresets(
              line: widget.line,
              value: value,
              standsForRecipe: identical(part, parsed),
              onRecipePart: _fillRecipePart,
              onFill: _fill,
            ),
            Text(
              l10n.kochmodusAmountNote,
              style: textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
            FilledButton(
              key: KochmodusAmountSheet.applyKey,
              onPressed: value == null && part == null
                  ? null
                  : () => Navigator.of(context).pop(_choice),
              style: KochmodusStepFoot.mainButtonStyle(context),
              child: Text(l10n.cookPickerApply),
            ),
          ],
        ),
      ),
    );
  }
}

// The unit of [line] after the number; bare pieces show nothing.
String? _unitLabel(AppLocalizations l10n, KochmodusLineView line) {
  final measure = line.need?.countMeasureLabel?.trim() ?? '';
  return switch (line.amountUnit) {
    TemplateIngredientUnit.gram => l10n.inventoryUnitGram,
    TemplateIngredientUnit.milliliter => l10n.inventoryUnitMilliliter,
    TemplateIngredientUnit.piece when measure.isNotEmpty => measure,
    TemplateIngredientUnit.piece => null,
  };
}
