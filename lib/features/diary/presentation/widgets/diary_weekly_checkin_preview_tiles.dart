import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/presentation/diary_weekly_checkin_preview_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Debug entries that open the weekly check-in sheet as a preview.
class DiaryWeeklyCheckInPreviewTiles extends ConsumerWidget {
  /// Creates the preview entries.
  const new({super.key});

  /// Key of the entry for [kind].
  static ValueKey<String> tileKey(DiaryWeeklyCheckInPreviewKind kind) =>
      ValueKey<String>('diary-weekly-checkin-preview-${kind.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final kind in DiaryWeeklyCheckInPreviewKind.values)
          ListTile(
            key: tileKey(kind),
            leading: Icon(switch (kind) {
              DiaryWeeklyCheckInPreviewKind.checkIn =>
                Icons.fact_check_outlined,
              DiaryWeeklyCheckInPreviewKind.goalReached =>
                Icons.emoji_events_outlined,
              DiaryWeeklyCheckInPreviewKind.missingData => Icons.scale_outlined,
            }),
            title: Text(switch (kind) {
              DiaryWeeklyCheckInPreviewKind.checkIn =>
                l10n.diaryCheckInPreviewAction,
              DiaryWeeklyCheckInPreviewKind.goalReached =>
                l10n.diaryCheckInGoalReachedPreviewAction,
              DiaryWeeklyCheckInPreviewKind.missingData =>
                l10n.diaryCheckInMissingDataPreviewAction,
            }),
            onTap: () => unawaited(
              showDiaryWeeklyCheckInPreviewFlow(
                context,
                kind: kind,
                today: ref.read(clockProvider)(),
              ),
            ),
          ),
      ],
    );
  }
}
