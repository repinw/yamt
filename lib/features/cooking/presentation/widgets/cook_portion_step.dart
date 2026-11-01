import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_meal_preview.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_finish_error_text.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_step_frame.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_count_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_table.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The last step: the meal's name, the full pot on the scale, portions or
/// pieces, its nutrition label, and "In Vorrat".
class CookPortionStep extends ConsumerStatefulWidget {
  /// Creates the step.
  const new({
    required this.view,
    required this.busy,
    required this.onFinish,
    super.key,
  });

  /// Key of the weight field.
  static const weightKey = ValueKey<String>('cook-gross-weight');

  /// Key of the name field.
  static const nameKey = ValueKey<String>('cook-meal-name');

  /// The cooking.
  final CookView view;

  /// Whether "In Vorrat" runs.
  final bool busy;

  /// Puts the meal into the Vorrat.
  final ValueChanged<CookPortioning> onFinish;

  @override
  ConsumerState<CookPortionStep> createState() => _CookPortionStepState();
}

class _CookPortionStepState extends ConsumerState<CookPortionStep> {
  late final _name = TextEditingController(text: widget.view.recipe.name);
  final _weight = TextEditingController();
  late int _count = widget.view.portions;
  var _inPieces = false;

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    super.dispose();
  }

  int? get _emptyWeight => switch (widget.view.session.pot) {
    CookPotUtensil(:final emptyWeight) => emptyWeight,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final emptyWeight = _emptyWeight;
    final gross = int.tryParse(_weight.text.trim());
    final net = emptyWeight == null || gross == null
        ? null
        : gross - emptyWeight;
    final weighed = emptyWeight == null || (net != null && net > 0);
    final portioning = (
      name: _name.text,
      count: _count,
      inPieces: _inPieces,
      grossWeight: emptyWeight == null ? null : gross,
    );
    final preview = ref.watch(
      cookMealPreviewProvider(
        widget.view.recipe.id,
        l10n.localeName,
        portioning,
      ),
    );
    return CookStepFrame(
      title: l10n.cookPortionTitle,
      buttonLabel: l10n.cookToStock,
      onButton:
          widget.busy || !weighed || preview.hasError || !widget.view.isSettled
          ? null
          : () => widget.onFinish(portioning),
      children: [
        TextField(
          key: CookPortionStep.nameKey,
          controller: _name,
          decoration: InputDecoration(labelText: l10n.cookMealName),
          onChanged: (_) => setState(() {}),
          onTapUpOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        if (emptyWeight != null) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: CookPortionStep.weightKey,
            controller: _weight,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.cookGrossWeight,
              helperText: net != null && net > 0
                  ? l10n.cookNetWeight(net)
                  : null,
              errorText: net != null && net <= 0
                  ? l10n.cookWeightTooLow(emptyWeight)
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onTapUpOutside: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.cookCountPortions)),
            ButtonSegment(value: true, label: Text(l10n.cookCountPieces)),
          ],
          selected: {_inPieces},
          showSelectedIcon: false,
          onSelectionChanged: (value) =>
              setState(() => _inPieces = value.single),
        ),
        EatCountRow(
          label: _inPieces ? l10n.cookCountPieces : l10n.cookCountPortions,
          count: _count,
          decreaseTooltip: l10n.cookFewer,
          increaseTooltip: l10n.cookMore,
          onDecrease: _count > 1 ? () => setState(() => _count--) : null,
          onIncrease: () => setState(() => _count++),
        ),
        const SizedBox(height: AppSpacing.md),
        preview.when(
          data: (meal) => EatMealTable(meal: meal, portions: _count),
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Text(
            cookFinishErrorText(l10n, error),
            style: textTheme.bodyMedium?.copyWith(color: colors.low),
          ),
        ),
      ],
    );
  }
}
