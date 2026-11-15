import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_count_row.dart';
import 'package:yamt/features/kochmodus/domain/cook_meal_name.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_portion_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pot_weight_field.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The input of one meal on "Fertig gekocht": its name, the pot with the food
/// on the scale, and "Wie viele Portionen sind es?" (or Stück, Dosen).
class KochmodusMealBox extends StatefulWidget {
  /// Creates the box of [meal] for the cooking of [target].
  const new({
    required this.target,
    required this.meal,
    required this.inCans,
    super.key,
  });

  /// Key of the name field of the meal of [potId].
  static ValueKey<String> nameKey(String potId) =>
      ValueKey<String>('kochmodus-meal-name-$potId');

  /// Key of the weight field of the meal of [potId].
  static ValueKey<String> weighKey(String potId) =>
      ValueKey<String>('kochmodus-meal-weigh-$potId');

  /// Key of "Stück" of the meal of [potId].
  static ValueKey<String> piecesKey(String potId) =>
      ValueKey<String>('kochmodus-meal-pieces-$potId');

  /// Key of − of the meal of [potId].
  static ValueKey<String> fewerKey(String potId) =>
      ValueKey<String>('kochmodus-meal-fewer-$potId');

  /// Key of + of the meal of [potId].
  static ValueKey<String> moreKey(String potId) =>
      ValueKey<String>('kochmodus-meal-more-$potId');

  /// Key of "Pro Dose: 375 g" of the meal of [potId].
  static ValueKey<String> perCountKey(String potId) =>
      ValueKey<String>('kochmodus-meal-per-count-$potId');

  /// What the page cooks; the input goes to its controller.
  final KochmodusTarget target;

  /// The meal.
  final KochmodusMealView meal;

  /// Whether the meals go into cans: "Dosen" instead of "Portionen".
  final bool inCans;

  /// [name] in words, such as "Chili · Großer Topf" or "Frei gekocht".
  static String nameText(AppLocalizations l10n, CookMealName name) =>
      switch (name) {
        CookMealNamePlain(:final name) => name,
        CookMealNameInPot(:final recipe, :final pot) =>
          l10n.kochmodusMealNameInPot(recipe, pot),
        CookMealNameWith(:final first, :final second) =>
          l10n.kochmodusMealNameWith(first, second),
        CookMealNameFree() => l10n.kochmodusMealNameFree,
      };

  /// The name of the pot of [meal], "Topf N" when it has none.
  static String potLabel(AppLocalizations l10n, KochmodusMealView meal) {
    final name = meal.pot?.name?.trim() ?? '';
    return name.isEmpty ? l10n.kochmodusPotNumbered(meal.number) : name;
  }

  /// What the cook typed in for [meal], or its defaults before the first
  /// input.
  static CookMealDraft draftOf(AppLocalizations l10n, KochmodusMealView meal) =>
      meal.draft ??
      CookMealDraft(
        potId: meal.potId,
        name: nameText(l10n, meal.name),
        count: meal.count,
        inPieces: meal.inPieces,
        grossWeight: null,
      );

  /// Asks for the weight of the pot of [meal] with the food in it and stores
  /// it: what the field "Topf mit Essen" and the main button of "Fertig
  /// gekocht" open while the pot waits for it.
  static Future<void> weigh(
    BuildContext context,
    KochmodusTarget target,
    KochmodusMealView meal,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final pot = meal.pot;
    if (pot == null) return;
    final grams = await KochmodusWeighSheet.show(
      context,
      title: potLabel(l10n, meal),
      sub: l10n.kochmodusPotWeighSub(pot.emptyWeight),
    );
    if (grams == null || !context.mounted) return;
    await KochmodusActionFlow.run(
      context,
      target,
      (controller) =>
          controller.editMeal(draftOf(l10n, meal), grossWeight: grams),
    );
  }

  @override
  State<KochmodusMealBox> createState() => _KochmodusMealBoxState();
}

class _KochmodusMealBoxState extends State<KochmodusMealBox> {
  final _name = TextEditingController();
  final _focus = FocusNode();
  var _synced = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _saveName();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_synced) {
      _synced = true;
      _name.text = _storedName;
    }
  }

  @override
  void didUpdateWidget(KochmodusMealBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A name from another device shows unless the cook is typing.
    if (!_focus.hasFocus && _name.text != _storedName) {
      _name.text = _storedName;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _name.dispose();
    super.dispose();
  }

  String get _storedName =>
      KochmodusMealBox.draftOf(AppLocalizations.of(context)!, widget.meal).name;

  void _edit({String? name, int? count, bool? inPieces}) {
    final fallback = KochmodusMealBox.draftOf(
      AppLocalizations.of(context)!,
      widget.meal,
    );
    unawaited(
      KochmodusActionFlow.run(
        context,
        widget.target,
        (controller) => controller.editMeal(
          fallback,
          name: name,
          count: count,
          inPieces: inPieces,
        ),
      ),
    );
  }

  // An empty field goes back to the default name, so no meal goes into the
  // Vorrat without one.
  void _saveName() {
    if (!mounted) return;
    final typed = _name.text.trim();
    final name = typed.isEmpty
        ? KochmodusMealBox.nameText(
            AppLocalizations.of(context)!,
            widget.meal.name,
          )
        : typed;
    if (typed.isEmpty) _name.text = name;
    if (name == _storedName) return;
    _edit(name: name);
  }

  String? _perCount(AppLocalizations l10n, String kind) {
    final meal = widget.meal;
    if (meal.inPieces || meal.count < 1) return null;
    if (meal.netWeight case final net?) {
      return l10n.kochmodusMealPerCount(kind, (net / meal.count).round());
    }
    final grams = meal.ingredientGrams;
    if (meal.pot != null || grams == null || grams < meal.count) return null;
    return l10n.kochmodusMealPerCountEstimated(
      kind,
      (grams / meal.count).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meal = widget.meal;
    final kind = meal.inPieces
        ? 'piece'
        : widget.inCans
        ? 'can'
        : 'portion';
    final countQuestion = l10n.kochmodusMealCountQuestion(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        TextField(
          key: KochmodusMealBox.nameKey(meal.potId),
          controller: _name,
          focusNode: _focus,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveName(),
          onTapUpOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            labelText: l10n.cookMealName,
            hintText: KochmodusMealBox.nameText(l10n, meal.name),
          ),
        ),
        if (meal.pot != null)
          KochmodusPotWeightField(
            key: KochmodusMealBox.weighKey(meal.potId),
            meal: meal,
            label: KochmodusMealBox.potLabel(l10n, meal),
            onTap: () =>
                unawaited(KochmodusMealBox.weigh(context, widget.target, meal)),
          ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text(
                widget.inCans ? l10n.kochmodusMealCans : l10n.cookCountPortions,
              ),
            ),
            ButtonSegment(
              value: true,
              label: Text(
                l10n.cookCountPieces,
                key: KochmodusMealBox.piecesKey(meal.potId),
              ),
            ),
          ],
          selected: {meal.inPieces},
          showSelectedIcon: false,
          onSelectionChanged: (value) => _edit(inPieces: value.single),
        ),
        EatCountRow(
          label: countQuestion,
          count: meal.count,
          decreaseTooltip: l10n.cookFewer,
          increaseTooltip: l10n.cookMore,
          decreaseKey: KochmodusMealBox.fewerKey(meal.potId),
          increaseKey: KochmodusMealBox.moreKey(meal.potId),
          onDecrease: meal.count > 1
              ? () => _edit(count: meal.count - 1)
              : null,
          onIncrease: () => _edit(count: meal.count + 1),
        ),
        // How much goes into each can or portion: from the weighed pot, or
        // roughly from the ingredients when there is no pot.
        if (_perCount(l10n, kind) case final text?)
          Text(
            text,
            key: KochmodusMealBox.perCountKey(meal.potId),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
      ],
    );
  }
}
