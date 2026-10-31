import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Runs [change] on the diary dashboard layout, and says so in a snack bar
/// when the layout was not saved.
Future<void> changeDiaryDashboardFlow(
  BuildContext context,
  WidgetRef ref,
  Future<bool> Function(DiaryDashboardLayoutController layout) change,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  if (!await change(
    ref.read(diaryDashboardLayoutControllerProvider.notifier),
  )) {
    messenger.showAppSnackBar(
      l10n.diaryDashboardSaveFailed,
      tone: AppSnackBarTone.error,
    );
  }
}
