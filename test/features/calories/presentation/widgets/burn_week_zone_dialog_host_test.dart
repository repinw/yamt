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
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required GlobalKey<_TestBurnWeekZoneDialogHostState> key,
  bool canShow = true,
  bool queueOnBuild = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        burnWeekRunControllerProvider.overrideWith(
          _FakeBurnWeekRunController.new,
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
    super.key,
  });

  final bool canShow;
  final bool queueOnBuild;

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
      metrics: _aboveFastOnlyMetrics,
      runState: const BurnWeekRunState.initial(),
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
  @override
  Future<BurnWeekRunState> build() async {
    return const BurnWeekRunState.initial();
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
