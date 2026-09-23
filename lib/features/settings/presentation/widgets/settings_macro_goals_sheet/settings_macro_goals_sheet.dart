import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/domain/macro_reference_weight.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/macro_goal_settings_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_action_buttons.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_activity_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_adjusted_weight_notice.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_carbs_notice.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_multiplier_card.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_preview_card.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_preview_data.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the macro goals distribution settings bottom sheet.
Future<void> showSettingsMacroGoalsSheet(
  BuildContext context, {
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const SettingsMacroGoalsSheet(),
  );
}

/// Bottom sheet allowing users to configure macro multipliers and activity.
class SettingsMacroGoalsSheet extends ConsumerStatefulWidget {
  /// Creates the macro goals sheet.
  const new({super.key});

  @override
  ConsumerState<SettingsMacroGoalsSheet> createState() =>
      _SettingsMacroGoalsSheetState();
}

class _SettingsMacroGoalsSheetState
    extends ConsumerState<SettingsMacroGoalsSheet> {
  late bool _isSportActive;
  late double _proteinMultiplier;
  late double _fatMultiplier;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(macroGoalSettingsControllerProvider);
    final isMale = _resolveIsMale();
    final hasTrainingDays = _resolveHasTrainingDays();
    _isSportActive = settings.resolveSportActive(
      hasTrainingDays: hasTrainingDays,
    );
    _proteinMultiplier = settings.effectiveProteinMultiplier(
      hasTrainingDays: hasTrainingDays,
    );
    _fatMultiplier = settings.effectiveFatMultiplier(isMale: isMale);
  }

  bool _resolveHasTrainingDays() {
    final goalSettings = ref.read(calorieGoalControllerProvider).value;
    return goalSettings?.calculatorProfile?.trainingWeekdays.isNotEmpty ??
        false;
  }

  bool _resolveIsMale() {
    final goalSettings = ref.read(calorieGoalControllerProvider).value;
    final sex = goalSettings?.calculatorProfile?.sex;
    return (sex ?? CalorieCalculatorSex.male) == CalorieCalculatorSex.male;
  }

  double _resolveWeightKg(bool isMale) {
    final goalSettings = ref.read(calorieGoalControllerProvider).value;
    final profile = goalSettings?.calculatorProfile;
    if (profile == null) {
      return isMale ? 80.0 : 65.0;
    }
    return macroReferenceWeightKg(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
    );
  }

  double _resolveGoalKcal() {
    final goalSettings = ref.read(calorieGoalControllerProvider).value;
    final dailyKcal = goalSettings?.dailyKcalGoal;
    return (dailyKcal != null && dailyKcal > 0) ? dailyKcal : 2200.0;
  }

  void _onToggleSport(bool value) {
    setState(() {
      _isSportActive = value;
      final isMale = _resolveIsMale();
      _proteinMultiplier = MacroCalculationDefaults.defaultProteinMultiplier(
        isSportActive: value,
      );
      _fatMultiplier = MacroCalculationDefaults.defaultFatMultiplier(
        isMale: isMale,
      );
    });
  }

  void _onResetToDefaults() {
    final isMale = _resolveIsMale();
    setState(() {
      _proteinMultiplier = MacroCalculationDefaults.defaultProteinMultiplier(
        isSportActive: _isSportActive,
      );
      _fatMultiplier = MacroCalculationDefaults.defaultFatMultiplier(
        isMale: isMale,
      );
    });
  }

  Future<void> _onSave() async {
    final isMale = _resolveIsMale();
    final defaultProtein = MacroCalculationDefaults.defaultProteinMultiplier(
      isSportActive: _isSportActive,
    );
    final defaultFat = MacroCalculationDefaults.defaultFatMultiplier(
      isMale: isMale,
    );

    final isCustomProtein = (_proteinMultiplier - defaultProtein).abs() > 0.01;
    final isCustomFat = (_fatMultiplier - defaultFat).abs() > 0.01;

    final next = MacroGoalSettings(
      isSportActive: _isSportActive,
      customProteinMultiplier: isCustomProtein ? _proteinMultiplier : null,
      customFatMultiplier: isCustomFat ? _fatMultiplier : null,
    );

    await ref
        .read(macroGoalSettingsControllerProvider.notifier)
        .updateSettings(next);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final isMale = _resolveIsMale();
    final weightKg = _resolveWeightKg(isMale);
    final profile = ref.watch(
      calorieGoalControllerProvider.select(
        (state) => state.value?.calculatorProfile,
      ),
    );
    final adjustedWeightKg = profile == null
        ? null
        : macroAdjustedWeightKg(
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
          );
    final goalKcal = _resolveGoalKcal();

    final previewData = SettingsMacroGoalsPreviewData.compute(
      goalKcal: goalKcal,
      weightKg: weightKg,
      proteinMultiplier: _proteinMultiplier,
      fatMultiplier: _fatMultiplier,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsMacroGoalsSheetTitle,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.settingsMacroGoalsSubtitle,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsMacroGoalsActivityTile(
            isSportActive: _isSportActive,
            onChanged: _onToggleSport,
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsMacroGoalsMultiplierCard(
            sliderKey: SettingsMacroGoalsSheetKeys.proteinSlider,
            label: l10n.settingsMacroGoalsProteinLabel,
            accentColor: accents.protein,
            multiplier: _proteinMultiplier,
            grams: previewData.proteinGrams,
            min: 0.8,
            max: 3,
            divisions: 22,
            onChanged: (val) {
              setState(() {
                _proteinMultiplier = double.parse(val.toStringAsFixed(1));
              });
            },
            formatGramPerKg: (val) =>
                l10n.settingsMacroGoalsGramPerKg(val.toStringAsFixed(1)),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsMacroGoalsMultiplierCard(
            sliderKey: SettingsMacroGoalsSheetKeys.fatSlider,
            label: l10n.settingsMacroGoalsFatLabel,
            accentColor: accents.fat,
            multiplier: _fatMultiplier,
            grams: previewData.fatGrams,
            min: 0.5,
            max: 2,
            divisions: 15,
            onChanged: (val) {
              setState(() {
                _fatMultiplier = double.parse(val.toStringAsFixed(1));
              });
            },
            formatGramPerKg: (val) =>
                l10n.settingsMacroGoalsGramPerKg(val.toStringAsFixed(1)),
          ),
          const SizedBox(height: AppSpacing.md),
          const SettingsMacroGoalsCarbsNotice(),
          if (adjustedWeightKg != null) ...[
            const SizedBox(height: AppSpacing.md),
            SettingsMacroGoalsAdjustedWeightNotice(
              adjustedWeightKg: adjustedWeightKg,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SettingsMacroGoalsPreviewCard(
            goalKcal: goalKcal,
            weightKg: weightKg,
            proteinGrams: previewData.proteinGrams,
            fatGrams: previewData.fatGrams,
            carbsGrams: previewData.carbsGrams,
            proteinPct: previewData.proteinPct,
            fatPct: previewData.fatPct,
            carbsPct: previewData.carbsPct,
            isBudgetExceeded: previewData.isBudgetExceeded,
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsMacroGoalsActionButtons(
            onSave: _onSave,
            onReset: _onResetToDefaults,
          ),
        ],
      ),
    );
  }
}
