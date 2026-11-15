import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/cook_timer_alarm_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_assign_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_async_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_discard_menu.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_type_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Was hast du da?" of a recipe, between its recipe page and the cooking
/// page: each line from the Vorrat, onto the shopping list, or left out. The
/// cook comes back after the shopping as often as needed; once every line is
/// settled, "Kochen" replaces it with the cooking page.
class KochmodusAssignPage extends ConsumerStatefulWidget {
  /// Assigns the recipe [recipeId] for [portions] portions, the recipe's own
  /// when `null`; goes on with the household's run of it when there is one.
  const new({required this.recipeId, this.portions, super.key});

  /// Key of "Weitere Zutat", the plus in the top bar.
  static const addLineKey = ValueKey<String>('kochmodus-assign-add-line');

  /// The recipe.
  final String recipeId;

  /// The portions asked for.
  final int? portions;

  @override
  ConsumerState<KochmodusAssignPage> createState() =>
      _KochmodusAssignPageState();
}

class _KochmodusAssignPageState extends ConsumerState<KochmodusAssignPage> {
  late final KochmodusTarget _target = KochmodusTarget.recipe(
    recipeId: widget.recipeId,
    portions: widget.portions,
  );

  @override
  void initState() {
    super.initState();
    // Once, after the first frame, so a failure can show its snack bar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Cooking starts here: the timers' permissions come first.
      unawaited(
        ref.read(cookTimerAlarmControllerProvider.notifier).askPermissions(),
      );
      unawaited(
        KochmodusActionFlow.run(
          context,
          _target,
          (controller) => controller.open(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FoodLabelColors.of(context).paper,
    body: SafeArea(
      bottom: false,
      child: KochmodusAsyncView(
        target: _target,
        data: (view) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(target: _target, view: view),
            Expanded(
              child: KochmodusAssignStep(target: _target, view: view),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Back, the recipe's name, "Weitere Zutat" as a plus, and the menu with
/// "Verwerfen" once the run is stored.
class _TopBar extends StatelessWidget {
  const new({required this.target, required this.view});

  final KochmodusTarget target;
  final KochmodusView view;

  // Asks what comes in and adds it as an open line.
  Future<void> _addLine(BuildContext context) async {
    final text = await KochmodusTypeSheet.show(context);
    if (text == null || !context.mounted) return;
    await KochmodusActionFlow.result(
      context,
      target,
      (controller) => controller.addLine(text, CookLineOrigin.added),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discardable = view.saved && !view.busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              view.run.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: KochmodusAssignPage.addLineKey,
            onPressed: () => unawaited(_addLine(context)),
            tooltip: AppLocalizations.of(context)!.kochmodusAssignAddLine,
            icon: const Icon(Icons.add_rounded),
          ),
          if (discardable)
            KochmodusDiscardMenu(
              onDiscard: () =>
                  unawaited(KochmodusActionFlow.discard(context, target)),
            ),
        ],
      ),
    );
  }
}
