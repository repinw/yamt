import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/debug/calorie_debug_action_controller.dart';
import 'package:yamt/features/calories/debug/calorie_debug_actions.dart';
import 'package:yamt/features/calories/debug/calorie_debug_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _CalorieDebugAction { debugDump, settingsDump, weeklyCheckInDump }

extension _CalorieDebugActionDetails on _CalorieDebugAction {
  Key get key {
    return switch (this) {
      _CalorieDebugAction.debugDump => CalorieDebugKeys.debugDumpButton,
      _CalorieDebugAction.settingsDump =>
        CalorieDebugKeys.settingsDebugDumpButton,
      _CalorieDebugAction.weeklyCheckInDump =>
        CalorieDebugKeys.weeklyCheckInDebugDumpButton,
    };
  }

  IconData get icon {
    return switch (this) {
      _CalorieDebugAction.debugDump => Icons.download_rounded,
      _CalorieDebugAction.settingsDump => Icons.data_object_rounded,
      _CalorieDebugAction.weeklyCheckInDump => Icons.rule_rounded,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      _CalorieDebugAction.debugDump => l10n.caloriesDebugDumpAction,
      _CalorieDebugAction.settingsDump => l10n.caloriesSettingsDebugDumpAction,
      _CalorieDebugAction.weeklyCheckInDump =>
        l10n.caloriesWeeklyCheckInDebugDumpAction,
    };
  }

  Future<void> run(
    BuildContext context,
    WidgetRef ref,
    CalorieDebugActionController controller,
  ) {
    return switch (this) {
      _CalorieDebugAction.debugDump => _printCalorieDebugDump(
        context,
        controller,
        now: ref.read(clockProvider)(),
      ),
      _CalorieDebugAction.settingsDump => _printCalorieSettingsDebugDump(
        context,
        controller,
      ),
      _CalorieDebugAction.weeklyCheckInDump =>
        _printCalorieWeeklyCheckInDebugDump(context, controller),
    };
  }
}

/// Debug-only calorie actions listed in the home side menu.
class CalorieDebugMenuSection extends ConsumerWidget {
  /// Creates the calorie debug menu section.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xs,
          ),
          child: Text(
            l10n.caloriesDebugActionsTooltip,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final action in _CalorieDebugAction.values)
          ListTile(
            key: action.key,
            leading: Icon(action.icon),
            title: Text(action.label(l10n)),
            onTap: () {
              final controller = ref.read(
                calorieDebugActionControllerProvider.notifier,
              );
              unawaited(action.run(context, ref, controller));
            },
          ),
      ],
    );
  }
}

Future<void> _printCalorieDebugDump(
  BuildContext context,
  CalorieDebugActionController controller, {
  required DateTime now,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await controller.printDebugDump(
    now: now,
    saveDialogTitle: l10n.caloriesDebugDumpSaveDialogTitle,
  );
  if (!context.mounted) {
    return;
  }
  showCalorieDebugDumpResultSnackBar(context: context, result: result);
}

Future<void> _printCalorieSettingsDebugDump(
  BuildContext context,
  CalorieDebugActionController controller,
) async {
  final result = await controller.printSettingsDebugDump();
  if (!context.mounted) {
    return;
  }
  showCalorieSettingsDebugDumpResultSnackBar(context: context, result: result);
}

Future<void> _printCalorieWeeklyCheckInDebugDump(
  BuildContext context,
  CalorieDebugActionController controller,
) async {
  final result = await controller.printWeeklyCheckInDebugDump();
  if (!context.mounted) {
    return;
  }
  showCalorieWeeklyCheckInDebugDumpResultSnackBar(
    context: context,
    result: result,
  );
}
