import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

/// Queues a Burn Week zone dialog after loaded metrics resolve.
typedef DiaryBalanceZoneDialogQueue =
    void Function({
      required BurnWeekMockMetrics metrics,
      required BurnWeekRunState runState,
    });

/// Opens the use-heart dialog for the current Burn Week metrics.
typedef DiaryBalanceUseHeartDialog =
    void Function({
      required double dailyGoalKcal,
      required BurnWeekRunState runState,
    });
