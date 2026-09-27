import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_run_training_service.dart';

part 'profile_training_edit_controller.g.dart';

/// The drafted training days of the current run and what they change.
@immutable
class ProfileTrainingEditState {
  /// Creates the edit state.
  const new({this.trainingDays, this.effect, this.isSaving = false});

  /// The drafted training days, or `null` before the first change.
  final Set<DateTime>? trainingDays;

  /// What [trainingDays] change, or `null` before the first change.
  final CalorieRunTrainingEffect? effect;

  /// Whether the training days are being saved.
  final bool isSaving;

  /// Whether the draft changes at least one day and can be saved.
  bool get canSave =>
      trainingDays != null &&
      (effect?.changes.isNotEmpty ?? false) &&
      !isSaving;
}

/// Drafts the training days of the current run, shows what they change, and
/// saves them.
@riverpod
class ProfileTrainingEditController extends _$ProfileTrainingEditController {
  @override
  ProfileTrainingEditState build() {
    // Keeps the service and the calorie settings behind it loaded while the
    // editor is open, without dropping the draft when they change.
    ref.listen(calorieRunTrainingServiceProvider, (_, _) {});
    return const ProfileTrainingEditState();
  }

  /// Takes the picked training days of the run.
  void setTrainingDays(Set<DateTime> trainingDays) {
    state = ProfileTrainingEditState(
      trainingDays: trainingDays,
      effect: ref
          .read(calorieRunTrainingServiceProvider)
          .effectOf(trainingDays, now: ref.read(clockProvider)()),
    );
  }

  /// Saves the drafted training days and reports whether they were stored.
  Future<bool> save() async {
    final trainingDays = state.trainingDays;
    if (!state.canSave || trainingDays == null) {
      return false;
    }
    final effect = state.effect;
    state = ProfileTrainingEditState(
      trainingDays: trainingDays,
      effect: effect,
      isSaving: true,
    );
    final saved = await ref
        .read(calorieRunTrainingServiceProvider)
        .save(trainingDays, now: ref.read(clockProvider)());
    if (!ref.mounted) {
      return saved;
    }
    state = ProfileTrainingEditState(
      trainingDays: trainingDays,
      effect: effect,
    );
    return saved;
  }
}
