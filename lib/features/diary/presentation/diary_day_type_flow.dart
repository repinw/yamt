import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_type_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Marks [day] as [type], and says so in a snack bar when it was not saved.
Future<void> selectDiaryDayTypeFlow(
  BuildContext context,
  WidgetRef ref, {
  required DateTime day,
  required DiaryDayType type,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  if (!await ref
      .read(diaryDayTypeControllerProvider.notifier)
      .select(day, type)) {
    messenger.showAppSnackBar(
      l10n.diaryDayTypeSaveFailed,
      tone: AppSnackBarTone.error,
    );
  }
}
