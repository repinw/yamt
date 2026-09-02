import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/macro_goal_settings_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_multiplier_card.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_preview_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Stable keys for Macro Goals Sheet widget tests.
abstract final class SettingsMacroGoalsSheetKeys {
  /// Sport active switch key.
  static const sportActiveSwitch = ValueKey<String>(
    'settings-macro-goals-sport-switch',
  );

  /// Protein slider key.
  static const proteinSlider = ValueKey<String>(
    'settings-macro-goals-protein-slider',
  );

  /// Fat slider key.
  static const fatSlider = ValueKey<String>('settings-macro-goals-fat-slider');

  /// Reset to recommendations button key.
  static const resetButton = ValueKey<String>(
    'settings-macro-goals-reset-button',
  );

  /// Save button key.
  static const saveButton = ValueKey<String>(
    'settings-macro-goals-save-button',
  );
}

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
  const SettingsMacroGoalsSheet({super.key});

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
    _isSportActive = settings.isSportActive;
    _proteinMultiplier = settings.effectiveProteinMultiplier(isMale: isMale);
    _fatMultiplier = settings.effectiveFatMultiplier(isMale: isMale);
  }

  bool _resolveIsMale() {
    final goalSettings = ref.read(calorieGoalControllerProvider).value;
    final sex = goalSettings?.calculatorProfile?.sex;
    return (sex ?? CalorieCalculatorSex.male) == CalorieCalculatorSex.male;
  }

  double _resolveWeightKg(bool isMale) {
    final goalSettings = ref.read(calorieGoalControllerProvider).value;
    final weight = goalSettings?.calculatorProfile?.weightKg;
    return weight ?? (isMale ? 80.0 : 65.0);
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
        isMale: isMale,
        isSportActive: value,
      );
      _fatMultiplier = MacroCalculationDefaults.defaultFatMultiplier(
        isMale: isMale,
        isSportActive: value,
      );
    });
  }

  void _onResetToDefaults() {
    final isMale = _resolveIsMale();
    setState(() {
      _proteinMultiplier = MacroCalculationDefaults.defaultProteinMultiplier(
        isMale: isMale,
        isSportActive: _isSportActive,
      );
      _fatMultiplier = MacroCalculationDefaults.defaultFatMultiplier(
        isMale: isMale,
        isSportActive: _isSportActive,
      );
    });
  }

  Future<void> _onSave() async {
    final isMale = _resolveIsMale();
    final defaultProtein = MacroCalculationDefaults.defaultProteinMultiplier(
      isMale: isMale,
      isSportActive: _isSportActive,
    );
    final defaultFat = MacroCalculationDefaults.defaultFatMultiplier(
      isMale: isMale,
      isSportActive: _isSportActive,
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
    final goalKcal = _resolveGoalKcal();

    final proteinGrams = (weightKg * _proteinMultiplier).round();
    final fatGrams = (weightKg * _fatMultiplier).round();
    final proteinKcal = proteinGrams * 4;
    final fatKcal = fatGrams * 9;
    final isBudgetExceeded = (proteinKcal + fatKcal) > goalKcal;
    final remainingKcal = math.max(0, goalKcal - (proteinKcal + fatKcal));
    final carbsGrams = (remainingKcal / 4).round();
    final carbsKcal = carbsGrams * 4;
    final totalEffectiveKcal = proteinKcal + fatKcal + carbsKcal;

    final proteinPct = totalEffectiveKcal > 0
        ? (proteinKcal / totalEffectiveKcal * 100).round()
        : 0;
    final fatPct = totalEffectiveKcal > 0
        ? (fatKcal / totalEffectiveKcal * 100).round()
        : 0;
    final carbsPct = totalEffectiveKcal > 0
        ? (carbsKcal / totalEffectiveKcal * 100).round()
        : 0;

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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.settingsMacroGoalsSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Activity Switch
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: AppSwitchListTile.adaptive(
              key: SettingsMacroGoalsSheetKeys.sportActiveSwitch,
              value: _isSportActive,
              onChanged: _onToggleSport,
              title: Text(
                l10n.settingsMacroGoalsSportActiveLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                l10n.settingsMacroGoalsSportActiveSubtitle,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Protein Slider
          SettingsMacroGoalsMultiplierCard(
            sliderKey: SettingsMacroGoalsSheetKeys.proteinSlider,
            label: l10n.settingsMacroGoalsProteinLabel,
            accentColor: accents.protein,
            multiplier: _proteinMultiplier,
            grams: proteinGrams,
            min: 0.8,
            max: 3,
            divisions: 22,
            onChanged: (val) {
              setState(() {
                _proteinMultiplier = double.parse(val.toStringAsFixed(1));
              });
            },
            formatGramPerKg: (val) => l10n.settingsMacroGoalsGramPerKg(
              val.toStringAsFixed(1),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Fat Slider
          SettingsMacroGoalsMultiplierCard(
            sliderKey: SettingsMacroGoalsSheetKeys.fatSlider,
            label: l10n.settingsMacroGoalsFatLabel,
            accentColor: accents.fat,
            multiplier: _fatMultiplier,
            grams: fatGrams,
            min: 0.5,
            max: 2,
            divisions: 15,
            onChanged: (val) {
              setState(() {
                _fatMultiplier = double.parse(val.toStringAsFixed(1));
              });
            },
            formatGramPerKg: (val) => l10n.settingsMacroGoalsGramPerKg(
              val.toStringAsFixed(1),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Carbs notice
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: accents.carbs.withValues(
                alpha: colors.brightness == Brightness.dark ? 0.14 : 0.08,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: accents.carbs.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: accents.carbs),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.settingsMacroGoalsCarbsAutoLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Live Preview Card
          SettingsMacroGoalsPreviewCard(
            goalKcal: goalKcal,
            weightKg: weightKg,
            proteinGrams: proteinGrams,
            fatGrams: fatGrams,
            carbsGrams: carbsGrams,
            proteinPct: proteinPct,
            fatPct: fatPct,
            carbsPct: carbsPct,
            isBudgetExceeded: isBudgetExceeded,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Actions: Save & Reset
          FilledButton(
            key: SettingsMacroGoalsSheetKeys.saveButton,
            onPressed: _onSave,
            child: Text(l10n.settingsMacroGoalsSaveButton),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton.icon(
              key: SettingsMacroGoalsSheetKeys.resetButton,
              onPressed: _onResetToDefaults,
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: Text(l10n.settingsMacroGoalsResetButton),
            ),
          ),
        ],
      ),
    );
  }
}
