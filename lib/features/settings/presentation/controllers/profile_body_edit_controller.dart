import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/flexible_decimal_parser.dart';
import 'package:yamt/features/calories/application/calorie_body_edit_service.dart';
import 'package:yamt/features/calories/domain/calorie_age_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_body_edit.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';

part 'profile_body_edit_controller.g.dart';

/// A body fact that the profile page edits.
enum ProfileBodyField {
  /// Body height.
  height,

  /// Birthday.
  birthDate,

  /// Sex.
  sex,

  /// Weight at the goal start.
  startWeight,
}

/// The draft of one body edit and what it changes.
@immutable
class ProfileBodyEditState {
  /// Creates the edit state.
  const new({
    this.edit,
    this.effect,
    this.isInvalid = false,
    this.isSaving = false,
  });

  /// The edit to save, or `null` while the draft is invalid or unchanged.
  final CalorieBodyEdit? edit;

  /// What [edit] changes, or `null` without an [edit].
  final CalorieBodyEditEffect? effect;

  /// Whether the draft lies outside the accepted range.
  final bool isInvalid;

  /// Whether the edit is being saved.
  final bool isSaving;

  /// Whether the user can save the draft.
  bool get canSave => edit != null && !isSaving;
}

/// Checks a draft of one body fact, shows what it changes, and saves it.
@riverpod
class ProfileBodyEditController extends _$ProfileBodyEditController {
  @override
  ProfileBodyEditState build() {
    // Keeps the service and the calorie settings behind it loaded while the
    // editor is open, without dropping the draft when they change.
    ref.listen(calorieBodyEditServiceProvider, (_, _) {});
    return const ProfileBodyEditState();
  }

  /// Takes the typed height in cm.
  void setHeightText(String text) {
    final heightCm = parseFlexibleDecimal(text);
    _preview(
      heightCm == null ||
              heightCm < minimumBodyHeightCm ||
              heightCm > maximumBodyHeightCm
          ? null
          : CalorieHeightEdit(heightCm),
    );
  }

  /// Takes the typed start weight in kg.
  void setStartWeightText(String text) {
    final weightKg = parseFlexibleDecimal(text);
    _preview(
      weightKg == null ||
              weightKg < minimumStartWeightKg ||
              weightKg > maximumStartWeightKg
          ? null
          : CalorieStartWeightEdit(weightKg),
    );
  }

  /// Takes the picked birthday.
  void setBirthDate(DateTime birthDate) {
    final ageYears = ageInYearsAt(birthDate, ref.read(clockProvider)());
    _preview(
      ageYears < minimumBodyAgeYears || ageYears > maximumBodyAgeYears
          ? null
          : CalorieBirthDateEdit(birthDate),
    );
  }

  /// Takes the picked sex.
  void setSex(CalorieCalculatorSex sex) => _preview(CalorieSexEdit(sex));

  /// Saves the draft and reports whether it was stored.
  Future<bool> save() async {
    final edit = state.edit;
    if (edit == null || state.isSaving) {
      return false;
    }
    state = ProfileBodyEditState(
      edit: edit,
      effect: state.effect,
      isSaving: true,
    );
    final saved = await ref
        .read(calorieBodyEditServiceProvider)
        .save(edit, now: ref.read(clockProvider)());
    if (!ref.mounted) {
      return saved;
    }
    state = ProfileBodyEditState(edit: edit, effect: state.effect);
    return saved;
  }

  void _preview(CalorieBodyEdit? edit) {
    if (edit == null) {
      state = const ProfileBodyEditState(isInvalid: true);
      return;
    }
    final service = ref.read(calorieBodyEditServiceProvider);
    final profile = service.settings?.calculatorProfile;
    if (profile == null || profile.isUnchangedBy(edit)) {
      state = const ProfileBodyEditState();
      return;
    }
    state = ProfileBodyEditState(
      edit: edit,
      effect: service.effectOf(edit, now: ref.read(clockProvider)()),
    );
  }
}
