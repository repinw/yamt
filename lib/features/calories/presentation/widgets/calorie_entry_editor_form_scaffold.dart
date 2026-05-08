import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shared scaffold for creating and editing calorie entries.
class CalorieEntryEditorFormScaffold extends StatelessWidget {
  /// Creates calorie entry form scaffold.
  const CalorieEntryEditorFormScaffold({
    required this.formKey,
    required this.isEditing,
    required this.isSaving,
    required this.nameController,
    required this.brandController,
    required this.amountController,
    required this.per100KcalController,
    required this.per100ProteinController,
    required this.per100CarbsController,
    required this.per100FatController,
    required this.selectedMealType,
    required this.selectedConsumedUnit,
    required this.loggedAt,
    required this.onSave,
    required this.onMealTypeChanged,
    required this.onConsumedUnitChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.positiveNumberValidator,
    required this.nonNegativeNumberValidator,
    super.key,
  });

  /// The form key.
  final GlobalKey<FormState> formKey;

  /// Whether editing existing entry.
  final bool isEditing;

  /// Whether save in progress.
  final bool isSaving;

  /// Name controller.
  final TextEditingController nameController;

  /// Brand controller.
  final TextEditingController brandController;

  /// Amount controller.
  final TextEditingController amountController;

  /// Calories controller.
  final TextEditingController per100KcalController;

  /// Protein controller.
  final TextEditingController per100ProteinController;

  /// Carbs controller.
  final TextEditingController per100CarbsController;

  /// Fat controller.
  final TextEditingController per100FatController;

  /// Selected meal type.
  final MealType selectedMealType;

  /// Selected consumed unit.
  final ConsumedUnit selectedConsumedUnit;

  /// Logged at value.
  final DateTime loggedAt;

  /// Save callback.
  final VoidCallback onSave;

  /// Meal type changed callback.
  final ValueChanged<MealType> onMealTypeChanged;

  /// Consumed unit changed callback.
  final ValueChanged<ConsumedUnit> onConsumedUnitChanged;

  /// Pick date callback.
  final VoidCallback onPickDate;

  /// Pick time callback.
  final VoidCallback onPickTime;

  /// Positive validator.
  final FormFieldValidator<String> positiveNumberValidator;

  /// Non-negative validator.
  final FormFieldValidator<String> nonNegativeNumberValidator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.caloriesEditEntryTitle : l10n.caloriesAddEntryTitle,
        ),
        actions: <Widget>[
          TextButton(
            key: CalorieEntryEditorKeys.saveButton,
            onPressed: isSaving ? null : onSave,
            child: Text(l10n.caloriesSaveEntryAction),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: AppInsets.page,
            children: <Widget>[
              _CalorieEntryIdentitySection(
                nameController: nameController,
                brandController: brandController,
                selectedMealType: selectedMealType,
                onMealTypeChanged: onMealTypeChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              _CalorieEntryAmountSection(
                amountController: amountController,
                selectedConsumedUnit: selectedConsumedUnit,
                onConsumedUnitChanged: onConsumedUnitChanged,
                positiveNumberValidator: positiveNumberValidator,
              ),
              const SizedBox(height: AppSpacing.lg),
              _CalorieEntryNutritionSection(
                per100KcalController: per100KcalController,
                per100ProteinController: per100ProteinController,
                per100CarbsController: per100CarbsController,
                per100FatController: per100FatController,
                positiveNumberValidator: positiveNumberValidator,
                nonNegativeNumberValidator: nonNegativeNumberValidator,
              ),
              const SizedBox(height: AppSpacing.lg),
              _CalorieEntryLoggedAtSection(
                loggedAt: loggedAt,
                onPickDate: onPickDate,
                onPickTime: onPickTime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalorieEntryIdentitySection extends StatelessWidget {
  const _CalorieEntryIdentitySection({
    required this.nameController,
    required this.brandController,
    required this.selectedMealType,
    required this.onMealTypeChanged,
  });

  final TextEditingController nameController;
  final TextEditingController brandController;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: <Widget>[
        TextFormField(
          key: CalorieEntryEditorKeys.nameField,
          controller: nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.caloriesEntryNameLabel),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.caloriesRequiredField;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: brandController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.caloriesEntryBrandLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<MealType>(
          initialValue: selectedMealType,
          decoration: InputDecoration(labelText: l10n.caloriesEntryMealLabel),
          items: MealType.sectionOrder
              .map((mealType) {
                return DropdownMenuItem<MealType>(
                  value: mealType,
                  child: Text(mealType.localizedName(l10n)),
                );
              })
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              onMealTypeChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _CalorieEntryAmountSection extends StatelessWidget {
  const _CalorieEntryAmountSection({
    required this.amountController,
    required this.selectedConsumedUnit,
    required this.onConsumedUnitChanged,
    required this.positiveNumberValidator,
  });

  final TextEditingController amountController;
  final ConsumedUnit selectedConsumedUnit;
  final ValueChanged<ConsumedUnit> onConsumedUnitChanged;
  final FormFieldValidator<String> positiveNumberValidator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            key: CalorieEntryEditorKeys.amountField,
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.caloriesEntryAmountLabel,
            ),
            validator: positiveNumberValidator,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DropdownButtonFormField<ConsumedUnit>(
            key: CalorieEntryEditorKeys.unitField,
            initialValue: selectedConsumedUnit,
            decoration: InputDecoration(labelText: l10n.caloriesEntryUnitLabel),
            items: ConsumedUnit.values
                .map((unit) {
                  return DropdownMenuItem<ConsumedUnit>(
                    value: unit,
                    child: Text(unit.localizedName(l10n)),
                  );
                })
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onConsumedUnitChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _CalorieEntryNutritionSection extends StatelessWidget {
  const _CalorieEntryNutritionSection({
    required this.per100KcalController,
    required this.per100ProteinController,
    required this.per100CarbsController,
    required this.per100FatController,
    required this.positiveNumberValidator,
    required this.nonNegativeNumberValidator,
  });

  final TextEditingController per100KcalController;
  final TextEditingController per100ProteinController;
  final TextEditingController per100CarbsController;
  final TextEditingController per100FatController;
  final FormFieldValidator<String> positiveNumberValidator;
  final FormFieldValidator<String> nonNegativeNumberValidator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.caloriesPer100SectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: CalorieEntryEditorKeys.per100KcalField,
          controller: per100KcalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.caloriesPer100KcalLabel),
          validator: positiveNumberValidator,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: CalorieEntryEditorKeys.per100ProteinField,
          controller: per100ProteinController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.caloriesPer100ProteinLabel,
          ),
          validator: nonNegativeNumberValidator,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: CalorieEntryEditorKeys.per100CarbsField,
          controller: per100CarbsController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.caloriesPer100CarbsLabel,
          ),
          validator: nonNegativeNumberValidator,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: CalorieEntryEditorKeys.per100FatField,
          controller: per100FatController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.caloriesPer100FatLabel),
          validator: nonNegativeNumberValidator,
        ),
      ],
    );
  }
}

class _CalorieEntryLoggedAtSection extends StatelessWidget {
  const _CalorieEntryLoggedAtSection({
    required this.loggedAt,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime loggedAt;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.caloriesEntryDateTimeLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(materialL10n.formatMediumDate(loggedAt)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.access_time_outlined),
                label: Text(
                  materialL10n.formatTimeOfDay(
                    TimeOfDay.fromDateTime(loggedAt),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
