import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_prefill.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_editor_draft.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_create_scaffold.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_dialogs.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_flow_handler.dart';

/// Create form content of the calorie entry route.
class CalorieEntryEditorContent extends StatefulWidget {
  /// Creates editor content.
  const new({
    required this.user,
    this.prefilledProfile,
    this.prefilledAmount,
    this.prefilledUnit,
    this.preselectedMealType,
    this.preselectedLoggedAt,
    super.key,
  });

  /// Signed-in user.
  final User user;

  /// Optional prefilled product profile.
  final CalorieProductProfile? prefilledProfile;

  /// Optional prefilled consumed amount.
  final double? prefilledAmount;

  /// Optional unit of [prefilledAmount].
  final ConsumedUnit? prefilledUnit;

  /// Optional preselected meal type.
  final MealType? preselectedMealType;

  /// Optional preselected logged-at value.
  final DateTime? preselectedLoggedAt;

  @override
  State<CalorieEntryEditorContent> createState() {
    return _CalorieEntryEditorContentState();
  }
}

class _CalorieEntryEditorContentState extends State<CalorieEntryEditorContent> {
  final _draft = CalorieEntryEditorDraft();

  @override
  void initState() {
    super.initState();
    _initializeForCreate();
  }

  @override
  void didUpdateWidget(covariant CalorieEntryEditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initializeForCreate() && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalorieEntryEditorCreateScaffold(
      draft: _draft,
      onSave: () => CalorieEntryEditorFlowHandler.returnNewEntry(
        context,
        draft: _draft,
        userId: widget.user.uid,
        prefilledProfile: widget.prefilledProfile,
      ),
      onMealTypeChanged: (type) => setState(() => _draft.mealType = type),
      onConsumedUnitChanged: (unit) =>
          setState(() => _draft.consumedUnit = unit),
      onPickDate: () => _pickDate(context),
      onPickTime: () => _pickTime(context),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showCalorieEntryDatePicker(
      context,
      initialDate: _draft.loggedAt,
    );
    if (pickedDate != null && mounted) {
      setState(() => _draft.updateDate(pickedDate));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showCalorieEntryTimePicker(
      context,
      initialTime: _draft.loggedAt,
    );
    if (pickedTime != null && mounted) {
      setState(() => _draft.updateTime(pickedTime));
    }
  }

  bool _initializeForCreate() {
    final createPrefill = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: widget.prefilledProfile,
      prefilledAmount: widget.prefilledAmount,
      prefilledUnit: widget.prefilledUnit,
      preselectedMealType: widget.preselectedMealType,
      preselectedLoggedAt: widget.preselectedLoggedAt,
    );
    return _draft.initializeForCreate(createPrefill);
  }
}
