import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_zone_dialog_host.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('queueBurnWeekZoneDialogIfNeeded shows queued dialog', (
    tester,
  ) async {
    final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
    await _pumpHost(tester, key: key, queueOnBuild: true);

    await _pumpQueuedDialog(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('invalidateBurnWeekZoneDialogs cancels queued dialog', (
    tester,
  ) async {
    final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
    await _pumpHost(tester, key: key, queueOnBuild: true);

    key.currentState!.invalidateBurnWeekZoneDialogs();
    await _pumpQueuedDialog(tester);

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('invalidateBurnWeekZoneDialogs closes active dialog', (
    tester,
  ) async {
    final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
    await _pumpHost(tester, key: key, queueOnBuild: true);
    await _pumpQueuedDialog(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);

    key.currentState!.invalidateBurnWeekZoneDialogs();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('queue does not show dialog when host cannot show dialogs', (
    tester,
  ) async {
    final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
    await _pumpHost(
      tester,
      key: key,
      canShow: false,
      queueOnBuild: true,
    );

    await _pumpQueuedDialog(tester);

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('showBurnWeekZoneUseHeartDialog skips when no hearts remain', (
    tester,
  ) async {
    final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
    final controller = _FakeBurnWeekRunController();
    await _pumpHost(tester, key: key, controller: controller);

    await key.currentState!.showBurnWeekZoneUseHeartDialog(
      dailyGoalKcal: 2000,
      runState: const BurnWeekRunState.initial().copyWith(heartCount: 0),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(controller.positiveHeartCalls, isEmpty);
    expect(controller.negativeHeartCalls, isEmpty);
  });

  testWidgets(
    'showBurnWeekZoneUseHeartDialog adds heart and resets zone status',
    (tester) async {
      final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
      final controller = _FakeBurnWeekRunController();
      await _pumpHost(
        tester,
        key: key,
        queueOnBuild: true,
        controller: controller,
      );
      await _primeAboveZoneStatus(tester, key);

      final dialogFuture = key.currentState!.showBurnWeekZoneUseHeartDialog(
        dailyGoalKcal: 2000,
        runState: const BurnWeekRunState.initial(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1 day kcal'));
      await tester.pumpAndSettle();
      await dialogFuture;

      expect(controller.positiveHeartCalls, [2000]);
      expect(controller.negativeHeartCalls, isEmpty);
      expect(
        key.currentState!.debugLastZoneStatus,
        BurnWeekZoneStatus.inside,
      );
    },
  );

  testWidgets('showBurnWeekZoneUseHeartDialog removes heart', (tester) async {
    final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
    final controller = _FakeBurnWeekRunController();
    await _pumpHost(tester, key: key, controller: controller);

    final dialogFuture = key.currentState!.showBurnWeekZoneUseHeartDialog(
      dailyGoalKcal: 2000,
      runState: const BurnWeekRunState.initial(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('-1 day kcal'));
    await tester.pumpAndSettle();
    await dialogFuture;

    expect(controller.negativeHeartCalls, [2000]);
    expect(controller.positiveHeartCalls, isEmpty);
  });

  testWidgets('below-zone use heart spends positive heart and resets status', (
    tester,
  ) async {
    final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
    final controller = _FakeBurnWeekRunController();
    await _pumpHost(
      tester,
      key: key,
      queueOnBuild: true,
      metrics: _belowRecoverMetrics,
      controller: controller,
    );
    await _pumpQueuedDialog(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      key.currentState!.debugLastZoneStatus,
      BurnWeekZoneStatus.below,
    );

    await tester.tap(find.text('Use heart'));
    await tester.pumpAndSettle();

    expect(controller.positiveHeartCalls, [2000]);
    expect(controller.negativeHeartCalls, isEmpty);
    expect(
      key.currentState!.debugLastZoneStatus,
      BurnWeekZoneStatus.inside,
    );
  });

  testWidgets('below-zone without hearts shows run over and restarts', (
    tester,
  ) async {
    final key = GlobalKey<_TestBurnWeekZoneDialogHostState>();
    final controller = _FakeBurnWeekRunController();
    await _pumpHost(
      tester,
      key: key,
      queueOnBuild: true,
      metrics: _belowNeedsHeartMetrics,
      runState: const BurnWeekRunState.initial().copyWith(heartCount: 0),
      controller: controller,
    );
    await _pumpQueuedDialog(tester);
    expect(find.text('Run over'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(controller.restartRunFromCalls, hasLength(1));
    expect(controller.positiveHeartCalls, isEmpty);
    expect(controller.negativeHeartCalls, isEmpty);
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required GlobalKey<_TestBurnWeekZoneDialogHostState> key,
  bool canShow = true,
  bool queueOnBuild = false,
  BurnWeekMockMetrics metrics = _aboveFastOnlyMetrics,
  BurnWeekRunState runState = const BurnWeekRunState.initial(),
  _FakeBurnWeekRunController? controller,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        burnWeekRunControllerProvider.overrideWith(
          () => controller ?? _FakeBurnWeekRunController(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: _TestBurnWeekZoneDialogHost(
            key: key,
            canShow: canShow,
            queueOnBuild: queueOnBuild,
            metrics: metrics,
            runState: runState,
          ),
        ),
      ),
    ),
  );
  if (queueOnBuild) {
    return;
  }
  await tester.pumpAndSettle();
}

Future<void> _primeAboveZoneStatus(
  WidgetTester tester,
  GlobalKey<_TestBurnWeekZoneDialogHostState> key,
) async {
  await _pumpQueuedDialog(tester);
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(
    key.currentState!.debugLastZoneStatus,
    BurnWeekZoneStatus.above,
  );

  await tester.tap(find.text('Close'));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsNothing);
}

Future<void> _pumpQueuedDialog(WidgetTester tester) async {
  tester.binding.scheduleFrame();
  for (var frame = 0; frame < 5; frame += 1) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pumpAndSettle();
}

class _TestBurnWeekZoneDialogHost extends ConsumerStatefulWidget {
  const _TestBurnWeekZoneDialogHost({
    required this.canShow,
    required this.queueOnBuild,
    required this.metrics,
    required this.runState,
    super.key,
  });

  final bool canShow;
  final bool queueOnBuild;
  final BurnWeekMockMetrics metrics;
  final BurnWeekRunState runState;

  @override
  ConsumerState<_TestBurnWeekZoneDialogHost> createState() {
    return _TestBurnWeekZoneDialogHostState();
  }
}

class _TestBurnWeekZoneDialogHostState
    extends ConsumerState<_TestBurnWeekZoneDialogHost>
    with BurnWeekZoneDialogHost<_TestBurnWeekZoneDialogHost> {
  var _queuedFromBuild = false;

  @override
  bool get canShowBurnWeekZoneDialogs => widget.canShow;

  void queueAboveDialog() {
    queueBurnWeekZoneDialogIfNeeded(
      metrics: widget.metrics,
      runState: widget.runState,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.queueOnBuild && !_queuedFromBuild) {
      _queuedFromBuild = true;
      queueAboveDialog();
    }
    return const SizedBox.shrink();
  }
}

class _FakeBurnWeekRunController extends BurnWeekRunController {
  final positiveHeartCalls = <double>[];
  final negativeHeartCalls = <double>[];
  final restartRunFromCalls = <DateTime>[];

  @override
  Future<BurnWeekRunState> build() async {
    return const BurnWeekRunState.initial();
  }

  @override
  Future<void> usePositiveHeart(double dailyGoalKcal) async {
    positiveHeartCalls.add(dailyGoalKcal);
  }

  @override
  Future<void> useNegativeHeart(double dailyGoalKcal) async {
    negativeHeartCalls.add(dailyGoalKcal);
  }

  @override
  Future<void> restartRunFrom({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) async {
    restartRunFromCalls.add(weekStartDate);
  }
}

const _aboveFastOnlyMetrics = BurnWeekMockMetrics(
  dailyGoalKcal: 2000,
  weeklyGoalKcal: 14000,
  usesFallbackGoal: false,
  paceRatio: 0.5,
  targetKcal: 7000,
  consumedKcal: 7600,
  safeZoneMinKcal: 6500,
  safeZoneMaxKcal: 7500,
  barMinKcal: 0,
  barMaxKcal: 14000,
);

const _belowRecoverMetrics = BurnWeekMockMetrics(
  dailyGoalKcal: 2000,
  weeklyGoalKcal: 14000,
  usesFallbackGoal: false,
  paceRatio: 0.5,
  targetKcal: 7000,
  consumedKcal: 6000,
  safeZoneMinKcal: 6500,
  safeZoneMaxKcal: 7500,
  barMinKcal: 0,
  barMaxKcal: 14000,
);

const _belowNeedsHeartMetrics = BurnWeekMockMetrics(
  dailyGoalKcal: 2000,
  weeklyGoalKcal: 14000,
  usesFallbackGoal: false,
  paceRatio: 0.9,
  targetKcal: 13000,
  consumedKcal: 5000,
  safeZoneMinKcal: 12000,
  safeZoneMaxKcal: 14000,
  barMinKcal: 0,
  barMaxKcal: 14000,
);
