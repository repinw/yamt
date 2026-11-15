import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/cook_timer_alarm_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_async_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_done_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pots_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_bar.dart';

/// The cooking page: one cook run through pots and cooking to portioning,
/// then "Fertig". The screen stays on while "Kochen" shows. A recipe run
/// whose lines still need assigning opens "Zuweisen" instead.
class KochmodusPage extends ConsumerStatefulWidget {
  /// Goes on with the cook run [runId].
  const new run({required String this.runId, super.key});

  /// Starts free cooking.
  const new free({super.key}) : runId = null;

  /// The run, for [KochmodusPage.run].
  final String? runId;

  @override
  ConsumerState<KochmodusPage> createState() => _KochmodusPageState();
}

class _KochmodusPageState extends ConsumerState<KochmodusPage> {
  late final KochmodusTarget _target;
  late final ScreenWakeLock _wakeLock;
  late final CookTimerAlarmController _alarms;
  bool _awake = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _target = switch (widget.runId) {
      final String runId => KochmodusTarget.run(runId),
      null => KochmodusTarget.free(const Uuid().v4()),
    };
    _wakeLock = ref.read(screenWakeLockProvider);
    // A tap on a timer notification of this run opens no second page.
    _alarms = ref.read(cookTimerAlarmControllerProvider.notifier)
      ..pageOpened(_target.cookRunId);
    // The timers' permissions come at the start, not mid-step at the first
    // timer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_alarms.askPermissions());
    });
    final provider = kochmodusControllerProvider(_target);
    ref
      ..listenManual(
        provider.select(
          (view) => switch (view.value) {
            KochmodusView(
              step: KochmodusStep.cook,
              finished: null,
              ended: false,
            ) =>
              true,
            _ => false,
          },
        ),
        (_, cooking) => _keepAwake(on: cooking),
        fireImmediately: true,
      )
      // Once, when the run is there: a deep link, "Läuft" or a timer may
      // open a recipe run whose lines still need assigning.
      ..listenManual(provider, (_, next) {
        final run = next.value?.run;
        if (_checked || run == null) return;
        _checked = true;
        final recipeId = run.recipeId;
        if (!run.needsAssigning || recipeId == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.pushReplacement(AppRoutes.homeCookPath(recipeId));
        });
      }, fireImmediately: true);
  }

  @override
  void dispose() {
    _alarms.pageClosed(_target.cookRunId);
    _keepAwake(on: false);
    super.dispose();
  }

  void _keepAwake({required bool on}) {
    if (on == _awake) return;
    _awake = on;
    on ? _wakeLock.acquire() : _wakeLock.release();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FoodLabelColors.of(context).paper,
    body: SafeArea(
      bottom: false,
      child: KochmodusAsyncView(
        target: _target,
        data: (view) => view.finished == null
            ? _KochmodusBody(target: _target, view: view)
            : KochmodusDoneView(target: _target, view: view),
      ),
    ),
  );
}

class _KochmodusBody extends StatelessWidget {
  const new({required this.target, required this.view});

  final KochmodusTarget target;
  final KochmodusView view;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KochmodusStepBar(
        current: view.step,
        locked: view.locked,
        onSelect: (step) => unawaited(
          KochmodusActionFlow.run(
            context,
            target,
            (controller) => controller.goTo(step),
          ),
        ),
        onBack: () => context.pop(),
        onDiscard: view.saved && !view.busy
            ? () => unawaited(KochmodusActionFlow.discard(context, target))
            : null,
      ),
      Expanded(
        child: switch (view.step) {
          KochmodusStep.pots => KochmodusPotsStep(target: target, view: view),
          KochmodusStep.cook => KochmodusCookStep(target: target, view: view),
          KochmodusStep.portion => KochmodusPortionStep(
            target: target,
            view: view,
          ),
        },
      ),
    ],
  );
}
