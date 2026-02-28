import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CalorieEntryEditorPage extends ConsumerStatefulWidget {
  const CalorieEntryEditorPage({
    super.key,
    this.entryId,
    this.prefilledProfile,
    this.scannedSourceRef,
  });

  final String? entryId;
  final CalorieProductProfile? prefilledProfile;
  final CalorieScannedSourceRef? scannedSourceRef;

  @override
  ConsumerState<CalorieEntryEditorPage> createState() {
    return _CalorieEntryEditorPageState();
  }
}

class _CalorieEntryEditorPageState
    extends ConsumerState<CalorieEntryEditorPage> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _amountController = TextEditingController(text: '100');
  final _per100KcalController = TextEditingController();
  final _per100ProteinController = TextEditingController();
  final _per100CarbsController = TextEditingController();
  final _per100FatController = TextEditingController();

  MealType _mealType = MealType.defaultForDateTime(DateTime.now());
  ConsumedUnit _consumedUnit = ConsumedUnit.grams;
  DateTime _loggedAt = DateTime.now();
  String? _initializedEntryId;
  ProviderSubscription<AsyncValue<CalorieEntry?>>? _entrySubscription;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeForCreate();
    _subscribeToEntry();
  }

  @override
  void didUpdateWidget(covariant CalorieEntryEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final didEntryIdChange = oldWidget.entryId != widget.entryId;
    final oldBarcode = oldWidget.prefilledProfile?.barcode;
    final nextBarcode = widget.prefilledProfile?.barcode;
    final didPrefillChange = oldBarcode != nextBarcode;
    if (!didEntryIdChange && !didPrefillChange) {
      return;
    }
    _entrySubscription?.close();
    _entrySubscription = null;
    _initializeForCreate();
    _subscribeToEntry();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _entrySubscription?.close();
    _nameController.dispose();
    _brandController.dispose();
    _amountController.dispose();
    _per100KcalController.dispose();
    _per100ProteinController.dispose();
    _per100CarbsController.dispose();
    _per100FatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateChangesProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          ),
        ),
      );
    }

    final user = authState.asData?.value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.homeCalories)),
        body: Center(child: Text(l10n.caloriesAuthRequired)),
      );
    }

    final entryId = widget.entryId;
    if (entryId == null) {
      return _buildEditorScaffold(context, user: user, initialEntry: null);
    }

    final entryState = ref.watch(calorieEntryByIdProvider(entryId));
    return entryState.when(
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.caloriesEditEntryTitle)),
            body: Center(child: Text(l10n.caloriesEntryNotFound)),
          );
        }
        return _buildEditorScaffold(context, user: user, initialEntry: entry);
      },
      loading: () => const Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          ),
        ),
      ),
      error: (error, stackTrace) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.caloriesEditEntryTitle)),
          body: Center(child: Text(l10n.caloriesLoadFailed)),
        );
      },
    );
  }

  bool _initializeFromEntry(CalorieEntry? entry) {
    final nextEntryId = entry?.id ?? '__new_entry__';
    if (_initializedEntryId == nextEntryId) {
      return false;
    }

    _nameController.text = entry?.name ?? '';
    _brandController.text = entry?.brand ?? '';
    _amountController.text = _formatDouble(entry?.consumedAmount ?? 100);
    _per100KcalController.text = _formatDouble(entry?.per100Kcal ?? 0);
    _per100ProteinController.text = _formatDouble(entry?.per100Protein ?? 0);
    _per100CarbsController.text = _formatDouble(entry?.per100Carbs ?? 0);
    _per100FatController.text = _formatDouble(entry?.per100Fat ?? 0);

    _mealType = entry?.mealType ?? MealType.defaultForDateTime(DateTime.now());
    _consumedUnit = entry?.consumedUnit ?? ConsumedUnit.grams;
    _loggedAt = entry?.loggedAt ?? DateTime.now();
    _initializedEntryId = nextEntryId;
    return true;
  }

  bool _initializeForCreate() {
    if (widget.entryId != null) {
      return false;
    }

    final prefill = widget.prefilledProfile;
    final prefillKey = prefill == null
        ? '__new_entry__'
        : '__new_entry__${prefill.barcode}_${prefill.source.jsonValue}';
    if (_initializedEntryId == prefillKey) {
      return false;
    }

    _nameController.text = prefill?.name ?? '';
    _brandController.text = prefill?.brand ?? '';
    _amountController.text = _formatDouble(100);
    _per100KcalController.text = _formatDouble(prefill?.per100Kcal ?? 0);
    _per100ProteinController.text = _formatDouble(prefill?.per100Protein ?? 0);
    _per100CarbsController.text = _formatDouble(prefill?.per100Carbs ?? 0);
    _per100FatController.text = _formatDouble(prefill?.per100Fat ?? 0);
    _mealType = MealType.defaultForDateTime(DateTime.now());
    _consumedUnit = ConsumedUnit.grams;
    _loggedAt = DateTime.now();
    _initializedEntryId = prefillKey;
    return true;
  }

  void _subscribeToEntry() {
    final entryId = widget.entryId;
    if (entryId == null) {
      return;
    }

    _entrySubscription = ref.listenManual<AsyncValue<CalorieEntry?>>(
      calorieEntryByIdProvider(entryId),
      (previous, next) {
        final entry = next.asData?.value;
        if (entry == null || !mounted) {
          return;
        }
        final changed = _initializeFromEntry(entry);
        if (!changed) {
          return;
        }
        setState(() {});
      },
      fireImmediately: true,
    );
  }

  Scaffold _buildEditorScaffold(
    BuildContext context, {
    required User user,
    required CalorieEntry? initialEntry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = initialEntry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.caloriesEditEntryTitle : l10n.caloriesAddEntryTitle,
        ),
        actions: <Widget>[
          TextButton(
            key: CalorieEntryEditorKeys.saveButton,
            onPressed: _isSaving
                ? null
                : () => _save(context, user: user, initialEntry: initialEntry),
            child: Text(l10n.caloriesSaveEntryAction),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppInsets.page,
            children: <Widget>[
              TextFormField(
                key: CalorieEntryEditorKeys.nameField,
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.caloriesEntryNameLabel,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.caloriesRequiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _brandController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.caloriesEntryBrandLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<MealType>(
                key: CalorieEntryEditorKeys.mealField,
                initialValue: _mealType,
                decoration: InputDecoration(
                  labelText: l10n.caloriesEntryMealLabel,
                ),
                items: MealType.sectionOrder
                    .map((mealType) {
                      return DropdownMenuItem<MealType>(
                        value: mealType,
                        child: Text(_mealLabel(l10n, mealType)),
                      );
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _mealType = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      key: CalorieEntryEditorKeys.amountField,
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.caloriesEntryAmountLabel,
                      ),
                      validator: _positiveNumberValidator,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<ConsumedUnit>(
                      key: CalorieEntryEditorKeys.unitField,
                      initialValue: _consumedUnit,
                      decoration: InputDecoration(
                        labelText: l10n.caloriesEntryUnitLabel,
                      ),
                      items: ConsumedUnit.values
                          .map((unit) {
                            return DropdownMenuItem<ConsumedUnit>(
                              value: unit,
                              child: Text(unit.localizedName(l10n)),
                            );
                          })
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _consumedUnit = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.caloriesPer100SectionTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: CalorieEntryEditorKeys.per100KcalField,
                controller: _per100KcalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesPer100KcalLabel,
                ),
                validator: _positiveNumberValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: CalorieEntryEditorKeys.per100ProteinField,
                controller: _per100ProteinController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesPer100ProteinLabel,
                ),
                validator: _nonNegativeNumberValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: CalorieEntryEditorKeys.per100CarbsField,
                controller: _per100CarbsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesPer100CarbsLabel,
                ),
                validator: _nonNegativeNumberValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: CalorieEntryEditorKeys.per100FatField,
                controller: _per100FatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesPer100FatLabel,
                ),
                validator: _nonNegativeNumberValidator,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.caloriesEntryDateTimeLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      key: CalorieEntryEditorKeys.dateButton,
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(_loggedAt),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: CalorieEntryEditorKeys.timeButton,
                      onPressed: () => _pickTime(context),
                      icon: const Icon(Icons.access_time_outlined),
                      label: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatTimeOfDay(TimeOfDay.fromDateTime(_loggedAt)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || pickedDate == null) {
      return;
    }

    setState(() {
      _loggedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _loggedAt.hour,
        _loggedAt.minute,
      );
    });
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_loggedAt),
    );
    if (!mounted || pickedTime == null) {
      return;
    }

    setState(() {
      _loggedAt = DateTime(
        _loggedAt.year,
        _loggedAt.month,
        _loggedAt.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save(
    BuildContext context, {
    required User user,
    required CalorieEntry? initialEntry,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final amount = _parseDouble(_amountController.text);
    final per100Kcal = _parseDouble(_per100KcalController.text);
    final per100Protein = _parseDouble(_per100ProteinController.text);
    final per100Carbs = _parseDouble(_per100CarbsController.text);
    final per100Fat = _parseDouble(_per100FatController.text);

    if (amount == null || per100Kcal == null) {
      _showFailureSnackBar(messenger, l10n.caloriesInvalidNumber);
      return;
    }
    if (per100Protein == null || per100Carbs == null || per100Fat == null) {
      _showFailureSnackBar(messenger, l10n.caloriesInvalidNumber);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final trimmedName = _nameController.text.trim();
    final trimmedBrand = _brandController.text.trim();
    final now = DateTime.now();
    final entry = initialEntry == null
        ? CalorieEntry.create(
            id: _uuid.v4(),
            userId: user.uid,
            name: trimmedName,
            brand: trimmedBrand.isEmpty ? null : trimmedBrand,
            mealType: _mealType,
            consumedAmount: amount,
            consumedUnit: _consumedUnit,
            per100Kcal: per100Kcal,
            per100Protein: per100Protein,
            per100Carbs: per100Carbs,
            per100Fat: per100Fat,
            loggedAt: _loggedAt,
            createdAt: now,
            updatedAt: now,
          )
        : initialEntry
              .copyWith(
                name: trimmedName,
                brand: trimmedBrand.isEmpty ? null : trimmedBrand,
                mealType: _mealType,
                consumedAmount: amount,
                consumedUnit: _consumedUnit,
                per100Kcal: per100Kcal,
                per100Protein: per100Protein,
                per100Carbs: per100Carbs,
                per100Fat: per100Fat,
                loggedAt: _loggedAt,
                updatedAt: now,
              )
              .recalculateTotals(updatedAt: now);

    final saved = await ref
        .read(calorieEntriesControllerProvider.notifier)
        .saveEntry(
          entry,
          scannedSourceRef: initialEntry == null
              ? widget.scannedSourceRef
              : null,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (saved) {
      if (router.canPop()) {
        router.pop();
      }
      return;
    }

    _showFailureSnackBar(messenger, l10n.caloriesSaveFailed);
  }

  String _mealLabel(AppLocalizations l10n, MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => l10n.caloriesMealBreakfast,
      MealType.lunch => l10n.caloriesMealLunch,
      MealType.dinner => l10n.caloriesMealDinner,
      MealType.snack => l10n.caloriesMealSnack,
    };
  }

  String? _positiveNumberValidator(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = _parseDouble(value);
    if (parsed == null || parsed <= 0) {
      return l10n.caloriesPositiveNumberValidation;
    }
    return null;
  }

  String? _nonNegativeNumberValidator(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = _parseDouble(value);
    if (parsed == null || parsed < 0) {
      return l10n.caloriesNonNegativeNumberValidation;
    }
    return null;
  }

  double? _parseDouble(String? rawValue) {
    if (rawValue == null) {
      return null;
    }
    final normalized = rawValue.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatDouble(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  void _showFailureSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
