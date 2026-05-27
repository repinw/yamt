import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/debug/calorie_debug_action_controller.dart';
import 'package:yamt/features/calories/debug/calorie_debug_actions.dart';
import 'package:yamt/features/calories/debug/calorie_debug_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _appBarDebugIconSplashRadius = 18.0;

enum _CalorieDebugAction {
  debugDump,
  settingsDump,
  weeklyCheckInDump,
}

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
    CalorieDebugActionController controller,
  ) {
    return switch (this) {
      _CalorieDebugAction.debugDump => _printCalorieDebugDump(
        context,
        controller,
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

/// Debug-only calorie actions menu for the home shell app bar.
class CalorieDebugActionsMenu extends ConsumerWidget {
  /// Creates the calorie debug actions menu.
  const CalorieDebugActionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_CalorieDebugAction>(
      key: CalorieDebugKeys.actionsMenuButton,
      tooltip: AppLocalizations.of(context)!.caloriesDebugActionsTooltip,
      useRootNavigator: true,
      icon: const Icon(Icons.bug_report_rounded),
      iconSize: 20,
      padding: EdgeInsets.zero,
      splashRadius: _appBarDebugIconSplashRadius,
      onSelected: (action) {
        final controller = ref.read(
          calorieDebugActionControllerProvider.notifier,
        );
        unawaited(action.run(context, controller));
      },
      itemBuilder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return [
          for (final action in _CalorieDebugAction.values)
            PopupMenuItem<_CalorieDebugAction>(
              key: action.key,
              value: action,
              child: _CalorieDebugMenuItem(
                icon: action.icon,
                label: action.label(l10n),
              ),
            ),
        ];
      },
    );
  }
}

class _CalorieDebugMenuItem extends StatelessWidget {
  const _CalorieDebugMenuItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }
}

Future<void> _printCalorieDebugDump(
  BuildContext context,
  CalorieDebugActionController controller,
) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await controller.printDebugDump(
    now: DateTime.now(),
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
  showCalorieSettingsDebugDumpResultSnackBar(
    context: context,
    result: result,
  );
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
