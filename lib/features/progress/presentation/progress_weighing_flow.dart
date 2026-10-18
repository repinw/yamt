import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_weighing_controller.dart';
import 'package:yamt/features/progress/presentation/models/progress_weighing_action.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weighing_edit_sheet.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weighing_info_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

// Static, so a double tap while Health is read opens one sheet.
bool _isOpening = false;

/// Opens the sheet of [weighing] and carries out what the user picks there:
/// the edit sheet for a weighing this device can change, else the info
/// sheet.
Future<void> openProgressWeighing(
  BuildContext context,
  WidgetRef ref,
  ProgressWeighing weighing,
) async {
  if (_isOpening) return;
  _isOpening = true;
  final bool? editable;
  try {
    editable = await ref
        .read(progressWeighingControllerProvider.notifier)
        .canChange(weighing);
  } finally {
    _isOpening = false;
  }
  if (!context.mounted) return;
  if (editable == null) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.progressWeighingHealthReadFailed,
      tone: AppSnackBarTone.error,
    );
    return;
  }
  final canEdit = editable;
  final now = ref.read(clockProvider)();
  final action = await showModalBottomSheet<ProgressWeighingAction>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => canEdit
        ? ProgressWeighingEditSheet(weighing: weighing, now: now)
        : ProgressWeighingInfoSheet(weighing: weighing),
  );
  if (action == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final controller = ref.read(progressWeighingControllerProvider.notifier);
  final (done, failure) = switch (action) {
    ProgressWeighingSave(:final at, :final weightKg) => (
      await controller.save(weighing, at: at, weightKg: weightKg),
      l10n.diaryWeightSaveFailed,
    ),
    ProgressWeighingDelete() => (
      await controller.delete(weighing),
      l10n.progressWeighingDeleteFailed,
    ),
    ProgressWeighingIgnore(:final ignored) => (
      await controller.setIgnored(weighing.sample!, ignored: ignored),
      l10n.progressWeighingIgnoreFailed,
    ),
    ProgressWeighingOpenHealth() => (
      await controller.openHealth(),
      l10n.progressWeighingOpenHealthFailed,
    ),
  };
  if (!context.mounted) return;
  if (!done) {
    ScaffoldMessenger.of(context)
        .showAppSnackBar(failure, tone: AppSnackBarTone.error);
    return;
  }
  if (action case ProgressWeighingSave(:final at, :final weightKg)) {
    await _handleRecordedWeight(context, at, weightKg);
  }
}

/// Offers the next goal when the changed weight reached the goal, as after
/// a weigh-in.
Future<void> _handleRecordedWeight(
  BuildContext context,
  DateTime at,
  double weightKg,
) async {
  // Keeps the auto-dispose weight flow alive until it is done.
  final subscription = ProviderScope.containerOf(
    context,
    listen: false,
  ).listen(diaryWeightTrackingFlowProvider, (_, _) {});
  try {
    await subscription.read().handleRecordedWeight(
      context: context,
      day: normalizeLocalDay(at),
      weightKg: weightKg,
    );
  } finally {
    subscription.close();
  }
}
