import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/presentation/kitchen_utensil_edit_flow.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_counted_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pot_tile.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Töpfe": "Worin kochst du?" with its reason, the household's utensils as
/// tiles with their empty weight, "Ohne Topf", "Danach in Dosen" and "Weiter",
/// which says what is missing while nothing is chosen.
///
/// The choice stays here until "Weiter" saves it; it starts from the run's
/// pots. A utensil the cook adds here is chosen at once, like a tap on its
/// tile; one that is gone again, as after the undo of adding it, is not.
class KochmodusPotsStep extends ConsumerStatefulWidget {
  /// Creates the step of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// Key of the tile that adds a utensil.
  static const addKey = ValueKey<String>('kochmodus-pots-add');

  /// Key of the switch "Danach in Dosen".
  static const cansKey = ValueKey<String>('kochmodus-pots-cans');

  /// Key of "Weiter".
  static const nextKey = ValueKey<String>('kochmodus-pots-next');

  /// Key of the tile of the utensil [utensilId].
  static ValueKey<String> potKey(String utensilId) =>
      ValueKey<String>('kochmodus-pots-pot-$utensilId');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  @override
  ConsumerState<KochmodusPotsStep> createState() => _KochmodusPotsStepState();
}

class _KochmodusPotsStepState extends ConsumerState<KochmodusPotsStep> {
  // The ids of the picked utensils in the order they were picked; the first
  // is where the lines start.
  late List<String> _chosenIds;
  late bool _counted;
  late bool _cans;

  @override
  void initState() {
    super.initState();
    final view = widget.view;
    final utensilIds = {for (final utensil in view.utensils) utensil.id};
    _chosenIds = [
      for (final pot in view.pots)
        if (utensilIds.contains(pot.id)) pot.id,
    ];
    _counted = view.counted;
    _cans = view.inCans;
  }

  // The picked utensils that the household still has, in pick order.
  List<KitchenUtensil> get _chosen {
    final utensils = {
      for (final utensil in widget.view.utensils) utensil.id: utensil,
    };
    return [for (final id in _chosenIds) ?utensils[id]];
  }

  void _toggle(KitchenUtensil utensil) => setState(() {
    _counted = false;
    _chosenIds = _chosenIds.contains(utensil.id)
        ? [
            for (final id in _chosenIds)
              if (id != utensil.id) id,
          ]
        : [..._chosenIds, utensil.id];
  });

  void _chooseCounted() => setState(() {
    _counted = true;
    _chosenIds = const [];
  });

  Future<void> _add() async {
    final utensilId = await KitchenUtensilEditFlow.add(
      context,
      ref,
      title: AppLocalizations.of(context)!.kochmodusPotsAdd,
    );
    if (!mounted || utensilId == null) return;
    setState(() {
      _counted = false;
      _chosenIds = [..._chosenIds, utensilId];
    });
  }

  Future<void> _next() {
    final counted = _counted;
    final chosen = _chosen;
    final cans = _cans;
    return KochmodusActionFlow.run(
      context,
      widget.target,
      (controller) => counted
          ? controller.chooseCounted()
          : controller.choosePots(chosen, inCans: cans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final view = widget.view;
    final chosen = _chosen;
    final ready = _counted || chosen.isNotEmpty;
    final tiles = [
      for (final utensil in view.utensils)
        KochmodusPotTile(
          key: KochmodusPotsStep.potKey(utensil.id),
          name: _utensilName(l10n, utensil),
          sub: l10n.kochmodusPotEmptyWeight(utensil.weightGrams),
          imagePath: utensil.imageStoragePath,
          selected: _chosenIds.contains(utensil.id),
          onTap: () => _toggle(utensil),
        ),
      KochmodusPotTile(
        key: KochmodusPotsStep.addKey,
        name: l10n.kochmodusPotsAdd,
        selected: false,
        isAdd: true,
        onTap: () => unawaited(_add()),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: AppInsets.page,
            children: [
              if (!view.isFree)
                Text(
                  l10n
                      .kochmodusRunKicker(view.run.name, view.run.portions)
                      .toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.muted,
                    letterSpacing: AppGraphit.kickerTracking,
                  ),
                ),
              Text(
                l10n.kochmodusPotsTitle,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.kochmodusPotsLead,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < tiles.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.sm,
                      children: [
                        Expanded(child: tiles[i]),
                        Expanded(
                          child: i + 1 < tiles.length
                              ? tiles[i + 1]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              KochmodusCountedRow(selected: _counted, onTap: _chooseCounted),
              const SizedBox(height: AppSpacing.sm),
              AppSwitchListTile(
                key: KochmodusPotsStep.cansKey,
                contentPadding: EdgeInsets.zero,
                value: _cans,
                onChanged: _counted
                    ? null
                    : (value) => setState(() => _cans = value),
                title: Text(l10n.kochmodusPotsCansTitle),
                subtitle: Text(l10n.kochmodusPotsCansHint),
              ),
              if (ready)
                _ResultLine(
                  label: l10n.kochmodusPotsResultLabel,
                  result: _result(l10n, chosen),
                ),
            ],
          ),
        ),
        KochmodusStepFoot(
          children: [
            if (!ready)
              Text(
                l10n.kochmodusPotsChooseHint,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
            FilledButton(
              key: KochmodusPotsStep.nextKey,
              onPressed: ready && !view.busy ? () => unawaited(_next()) : null,
              style: KochmodusStepFoot.mainButtonStyle(context),
              child: Text(l10n.kochmodusPotsNextCook),
            ),
          ],
        ),
      ],
    );
  }

  String _result(AppLocalizations l10n, List<KitchenUtensil> chosen) {
    if (_counted) return l10n.kochmodusPotsResultCounted;
    return switch (chosen) {
      [_] when _cans => l10n.kochmodusPotsResultTogetherCans,
      [final pot] => l10n.kochmodusPotsResultTogether(_utensilName(l10n, pot)),
      _ when _cans => l10n.kochmodusPotsResultSeparateCans(chosen.length),
      _ => l10n.kochmodusPotsResultSeparate(chosen.length),
    };
  }
}

String _utensilName(AppLocalizations l10n, KitchenUtensil utensil) =>
    switch (utensil.name?.trim()) {
      final name? when name.isNotEmpty => name,
      _ => l10n.kitchenUtensilUnnamedLabel,
    };

/// "Ergibt:" and what comes out of the choice, in bold.
class _ResultLine extends StatelessWidget {
  const new({required this.label, required this.result});

  final String label;
  final String result;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: AppGraphit.chipIcon,
          color: colors.muted,
        ),
        Text(label, style: style?.copyWith(color: colors.muted)),
        Expanded(
          child: Text(
            result,
            style: style?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
