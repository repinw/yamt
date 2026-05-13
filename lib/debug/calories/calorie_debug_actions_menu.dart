import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/debug/calories/calorie_debug_keys.dart';
import 'package:yamt/debug/calories/calorie_page_action_controller.dart';
import 'package:yamt/debug/calories/calorie_page_actions.dart';

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
      _CalorieDebugAction.debugDump => Icons.table_chart_rounded,
      _CalorieDebugAction.settingsDump => Icons.data_object_rounded,
      _CalorieDebugAction.weeklyCheckInDump => Icons.rule_rounded,
    };
  }

  String get label {
    return switch (this) {
      _CalorieDebugAction.debugDump => 'Print calorie debug table',
      _CalorieDebugAction.settingsDump => 'Print calorie settings JSON',
      _CalorieDebugAction.weeklyCheckInDump => 'Print weekly check-in state',
    };
  }

  Future<void> run(BuildContext context, WidgetRef ref) {
    return switch (this) {
      _CalorieDebugAction.debugDump => _printCalorieDebugDump(context, ref),
      _CalorieDebugAction.settingsDump => _printCalorieSettingsDebugDump(
        context,
        ref,
      ),
      _CalorieDebugAction.weeklyCheckInDump =>
        _printCalorieWeeklyCheckInDebugDump(context, ref),
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
      tooltip: 'Calorie debug actions',
      icon: const Icon(Icons.bug_report_rounded),
      onSelected: (action) {
        unawaited(action.run(context, ref));
      },
      itemBuilder: (context) {
        return [
          for (final action in _CalorieDebugAction.values)
            PopupMenuItem<_CalorieDebugAction>(
              key: action.key,
              value: action,
              child: _CalorieDebugMenuItem(
                icon: action.icon,
                label: action.label,
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

Future<void> _printCalorieDebugDump(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(calorieDebugActionControllerProvider.notifier);
  final result = await controller.printDebugDump(DateTime.now());
  if (!context.mounted) {
    return;
  }
  showCalorieDebugDumpResultSnackBar(context: context, result: result);
}

Future<void> _printCalorieSettingsDebugDump(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(calorieDebugActionControllerProvider.notifier);
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
  WidgetRef ref,
) async {
  final controller = ref.read(calorieDebugActionControllerProvider.notifier);
  final result = await controller.printWeeklyCheckInDebugDump();
  if (!context.mounted) {
    return;
  }
  showCalorieWeeklyCheckInDebugDumpResultSnackBar(
    context: context,
    result: result,
  );
}
