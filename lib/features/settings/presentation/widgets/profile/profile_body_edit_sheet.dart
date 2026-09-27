import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/calorie_body_edit.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_body_edit_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_edit_effect.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_edit_sheet_frame.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_number_input.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_pill_button.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_sex_choice.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the editor of [field] of [profile].
Future<void> showProfileBodyEditSheet(
  BuildContext context, {
  required ProfileBodyField field,
  required CalorieCalculatorProfile profile,
}) {
  return showProfileEditSheet(
    context,
    builder: (_) => ProfileBodyEditSheet(field: field, profile: profile),
  );
}

/// Edits one body fact and shows what the change does before it is saved.
class ProfileBodyEditSheet extends ConsumerStatefulWidget {
  /// Creates the editor of [field] of [profile].
  const new({required this.field, required this.profile, super.key});

  /// The fact to edit.
  final ProfileBodyField field;

  /// The profile with the current value.
  final CalorieCalculatorProfile profile;

  @override
  ConsumerState<ProfileBodyEditSheet> createState() => _State();
}

class _State extends ConsumerState<ProfileBodyEditSheet> {
  TextEditingController? _text;
  late CalorieCalculatorSex _sex = widget.profile.sex;
  late DateTime? _birthDate = widget.profile.birthDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final format = ProfileFormatters.of(context);
    _text ??= TextEditingController(
      text: switch (widget.field) {
        ProfileBodyField.height => format.whole(widget.profile.heightCm),
        ProfileBodyField.startWeight => format.decimal(widget.profile.weightKg),
        ProfileBodyField.birthDate || ProfileBodyField.sex => '',
      },
    );
  }

  @override
  void dispose() {
    _text?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(profileBodyEditControllerProvider);
    final effect = state.effect;
    final (kicker, title) = switch (widget.field) {
      ProfileBodyField.height => (
        l10n.profileBodySection,
        l10n.profileHeightTitle,
      ),
      ProfileBodyField.birthDate => (
        l10n.profileBodySection,
        l10n.profileBirthDateTitle,
      ),
      ProfileBodyField.sex => (l10n.profileBodySection, l10n.profileSexTitle),
      ProfileBodyField.startWeight => (
        l10n.profileWeightSection,
        l10n.profileStartWeightTitle,
      ),
    };
    return ProfileEditSheetFrame(
      kicker: kicker,
      title: title,
      input: _input(context, state),
      effect: effect == null ? null : ProfileEditEffect(effect: effect),
      canApply: state.canSave,
      onSave: () => _notifier.save(),
    );
  }

  Widget _input(BuildContext context, ProfileBodyEditState state) {
    final l10n = AppLocalizations.of(context)!;
    final format = ProfileFormatters.of(context);
    final birthDate = _birthDate;
    return switch (widget.field) {
      ProfileBodyField.height => ProfileNumberInput(
        controller: _text!,
        unit: l10n.profileUnitCm,
        onChanged: (text) => _notifier.setHeightText(text),
        errorText: state.isInvalid
            ? l10n.profileHeightRange(
                format.whole(minimumBodyHeightCm),
                format.whole(maximumBodyHeightCm),
              )
            : null,
      ),
      ProfileBodyField.startWeight => ProfileNumberInput(
        controller: _text!,
        unit: l10n.profileUnitKg,
        allowDecimals: true,
        onChanged: (text) => _notifier.setStartWeightText(text),
        errorText: state.isInvalid
            ? l10n.profileStartWeightRange(
                format.whole(minimumStartWeightKg),
                format.whole(maximumStartWeightKg),
              )
            : null,
      ),
      ProfileBodyField.sex => ProfileSexChoice(
        selected: _sex,
        onSelected: (sex) {
          setState(() => _sex = sex);
          _notifier.setSex(sex);
        },
      ),
      ProfileBodyField.birthDate => ProfilePillButton(
        icon: Icons.calendar_today_outlined,
        label: birthDate == null
            ? l10n.profileNoValue
            : format.longDate(birthDate),
        onTap: () => unawaited(_pickBirthDate()),
      ),
    };
  }

  Future<void> _pickBirthDate() async {
    final today = ref.read(clockProvider)();
    final latest = DateTime(
      today.year - minimumBodyAgeYears,
      today.month,
      today.day,
    );
    final current = _birthDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null || current.isAfter(latest)
          ? latest
          : current,
      firstDate: DateTime(
        today.year - maximumBodyAgeYears,
        today.month,
        today.day,
      ),
      lastDate: latest,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _birthDate = picked);
    _notifier.setBirthDate(picked);
  }

  ProfileBodyEditController get _notifier =>
      ref.read(profileBodyEditControllerProvider.notifier);
}
