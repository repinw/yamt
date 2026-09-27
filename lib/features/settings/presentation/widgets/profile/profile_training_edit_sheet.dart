import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_training_edit_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_edit_sheet_frame.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_run_day_picker.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_training_effect.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the editor of the training days of the run in [plan].
Future<void> showProfileTrainingEditSheet(
  BuildContext context, {
  required CalorieRunTrainingPlan plan,
}) {
  return showProfileEditSheet(
    context,
    builder: (_) => ProfileTrainingEditSheet(plan: plan),
  );
}

/// Picks the training days of the current run and shows what they change
/// before they are saved.
class ProfileTrainingEditSheet extends ConsumerStatefulWidget {
  /// Creates the editor for the run in [plan].
  const new({required this.plan, super.key});

  /// The current run with its training and pause days.
  final CalorieRunTrainingPlan plan;

  @override
  ConsumerState<ProfileTrainingEditSheet> createState() => _State();
}

class _State extends ConsumerState<ProfileTrainingEditSheet> {
  late Set<DateTime> _trainingDays = {...widget.plan.trainingDays};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = ProfileFormatters.of(context);
    final state = ref.watch(profileTrainingEditControllerProvider);
    final effect = state.effect;
    final plan = widget.plan;
    return ProfileEditSheetFrame(
      kicker: l10n.profileTrainingRunRange(
        format.shortDate(plan.days.first),
        format.shortDate(plan.lastDay),
      ),
      title: l10n.profileTrainingLabel,
      input: ProfileRunDayPicker(
        plan: plan,
        trainingDays: _trainingDays,
        onToggle: _toggle,
      ),
      effect: effect == null ? null : ProfileTrainingEffect(effect: effect),
      canApply: state.canSave,
      onSave: () =>
          ref.read(profileTrainingEditControllerProvider.notifier).save(),
    );
  }

  void _toggle(DateTime day) {
    final next = {..._trainingDays};
    if (!next.remove(day)) {
      next.add(day);
    }
    setState(() => _trainingDays = next);
    ref
        .read(profileTrainingEditControllerProvider.notifier)
        .setTrainingDays(next);
  }
}
