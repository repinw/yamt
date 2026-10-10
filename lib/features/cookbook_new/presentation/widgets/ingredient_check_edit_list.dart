import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_amount_labels.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The "Was änderst du?" step: every ingredient with its amount for the
/// chosen portions, a button that leaves it out, and a field for one more.
/// A typed value counts once it is submitted or its field loses focus.
class IngredientCheckEditList extends StatelessWidget {
  /// Creates the step for [check].
  const new({
    required this.check,
    required this.onAmount,
    required this.onRemove,
    required this.onAdd,
    super.key,
  });

  /// Key of the amount field of the line [key]; [occurrence] counts the
  /// lines before it with the same key.
  static ValueKey<String> amountKey(String key, [int occurrence = 0]) =>
      ValueKey<String>('ingredient-check-amount-$key-$occurrence');

  /// Key of the button that leaves out the line [key].
  static ValueKey<String> removeKey(String key, [int occurrence = 0]) =>
      ValueKey<String>('ingredient-check-remove-$key-$occurrence');

  /// Key of the field for one more ingredient.
  static const addKey = ValueKey<String>('ingredient-check-add');

  /// The recipe and the cook's choices.
  final IngredientCheckView check;

  /// Sets the amount of a line.
  final void Function(RecipeIngredientLine line, int amount) onAmount;

  /// Leaves a line out.
  final ValueChanged<RecipeIngredientLine> onRemove;

  /// Adds an ingredient, written for the chosen portions.
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = check.view;
    final lines = view.activeLines.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IngredientCheckTitle(
          kicker: l10n.recipeCheckEditKicker,
          title: l10n.recipeCheckEditTitle,
        ),
        for (final (index, line) in lines.indexed)
          _EditRow(
            // A recipe can name the same ingredient twice.
            occurrence: lines
                .take(index)
                .where((other) => other.key == line.key)
                .length,
            line: line,
            onAmount: (amount) => onAmount(line, amount),
            onRemove: view.canRemove ? () => onRemove(line) : null,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.sm,
            0,
          ),
          child: _AddField(onAdd: onAdd),
        ),
      ],
    );
  }
}

class _EditRow extends StatefulWidget {
  new({
    required this.occurrence,
    required this.line,
    required this.onAmount,
    required this.onRemove,
  }) : super(key: ValueKey<(String, int)>((line.key, occurrence)));

  final int occurrence;
  final RecipeIngredientLine line;
  final ValueChanged<int> onAmount;
  final VoidCallback? onRemove;

  @override
  State<_EditRow> createState() => _EditRowState();
}

class _EditRowState extends State<_EditRow> {
  late final _amount = TextEditingController(text: _text(widget.line));
  final _focus = FocusNode();

  static String _text(RecipeIngredientLine line) =>
      line.row.requirement?.amount.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_EditRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Shows the amount the recipe cooks while the cook is not typing.
    final text = _text(widget.line);
    if (!_focus.hasFocus && _amount.text != text) {
      _amount.text = text;
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    _amount.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focus.hasFocus) {
      _submit(_amount.text);
    }
  }

  void _submit(String text) {
    if (int.tryParse(text) case final amount? when amount > 0) {
      widget.onAmount(amount);
    } else {
      _amount.text = _text(widget.line);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final row = widget.line.row;
    final requirement = row.requirement;
    final unit = requirement == null
        ? null
        : ingredientUnitLabel(l10n, requirement);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xl),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: Text(
                row.foodName,
                style: textTheme.bodyLarge?.copyWith(color: colors.ink),
              ),
            ),
            if (requirement != null)
              SizedBox(
                width: AppGraphit.numberField,
                child: Semantics(
                  label: l10n.recipeCheckEditAmount(row.foodName),
                  child: TextField(
                    key: IngredientCheckEditList.amountKey(
                      widget.line.key,
                      widget.occurrence,
                    ),
                    controller: _amount,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.end,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: widget.line.isChanged
                              ? colors.accent
                              : colors.rule,
                        ),
                      ),
                    ),
                    onSubmitted: _submit,
                  ),
                ),
              ),
            if (unit != null)
              Text(
                unit,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
            IconButton(
              key: IngredientCheckEditList.removeKey(
                widget.line.key,
                widget.occurrence,
              ),
              tooltip: l10n.recipeCheckEditRemove(row.foodName),
              onPressed: widget.onRemove,
              icon: Icon(Icons.close_rounded, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddField extends StatefulWidget {
  const new({required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<_AddField> createState() => _AddFieldState();
}

class _AddFieldState extends State<_AddField> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    _text.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focus.hasFocus) {
      _submit();
    }
  }

  void _submit() {
    widget.onAdd(_text.text);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      key: IngredientCheckEditList.addKey,
      controller: _text,
      focusNode: _focus,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: l10n.recipeCheckEditAdd,
        hintText: l10n.recipeCheckEditAddHint,
        suffixIcon: IconButton(
          tooltip: l10n.recipeCheckEditAdd,
          onPressed: _submit,
          icon: const Icon(Icons.add_rounded),
        ),
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}
