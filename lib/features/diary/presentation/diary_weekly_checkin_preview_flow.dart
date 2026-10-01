import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the debug preview of the weekly check-in shows.
enum DiaryWeeklyCheckInPreviewKind {
  /// The regular check-in.
  checkIn,

  /// The page for a reached goal.
  goalReached,

  /// A check-in that lacks the end weight.
  missingData,
}

/// Opens the weekly check-in sheet for the latest completed window, or demo
/// data without one, and only reports the result. Debug only: nothing is
/// saved.
Future<void> showDiaryWeeklyCheckInPreviewFlow(
  BuildContext context, {
  required DiaryWeeklyCheckInPreviewKind kind,
  required DateTime today,
}) async {
  final result = await showDiaryWeeklyCheckInSheetRoute(
    context,
    child: kind == DiaryWeeklyCheckInPreviewKind.missingData
        ? DiaryWeeklyCheckInSheet(
            key: DiaryWeeklyCheckInSheetKeys.sheet,
            checkInData: diaryWeeklyCheckInBlockedDemoData(today),
            goalReached: false,
            preview: true,
          )
        : _DiaryWeeklyCheckInPreviewSheet(
            goalReached: kind == DiaryWeeklyCheckInPreviewKind.goalReached,
          ),
  );
  if (!context.mounted || result == null) {
    return;
  }
  ScaffoldMessenger.of(context).showAppSnackBar(
    AppLocalizations.of(context)!.diaryCheckInPreviewResult(
      result.action.name,
      result.training?.trainingDays.length ?? 0,
    ),
  );
}

class _DiaryWeeklyCheckInPreviewSheet extends ConsumerWidget {
  const new({required this.goalReached});

  final bool goalReached;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(diaryWeeklyCheckInPreviewDataProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(AppLocalizations.of(context)!.diaryCheckInLoadFailed),
          ),
          data: (checkInData) => DiaryWeeklyCheckInSheet(
            key: DiaryWeeklyCheckInSheetKeys.sheet,
            checkInData: checkInData,
            goalReached: goalReached,
            preview: true,
          ),
        );
  }
}
