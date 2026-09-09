import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

/// Shows the modal bottom sheet to select the day type (training, rest, pause).
Future<void> showDiaryDayTypeSheet({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime selectedDay,
  required CalorieGoalSettings settings,
}) {
  final colors = Theme.of(context).colorScheme;
  final isPause = settings.isPauseDay(selectedDay);
  final isTraining = !isPause && settings.isTrainingDay(selectedDay);
  final isRest = !isPause && !isTraining;

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
    ),
    builder: (modalContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tages-Status wählen',
                style: Theme.of(modalContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Steuere deinen Kalorienbedarf dynamisch nach deinem '
                'Aktivitätsplan.',
                style: Theme.of(modalContext).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _OptionTile(
                icon: Icons.fitness_center_rounded,
                title: '🏋️ Trainingstag',
                subtitle: settings.trainingDayKcalOffset > 0
                    ? '+${settings.trainingDayKcalOffset.toInt()} kcal '
                          'erhöhtes Kalorienziel'
                    : 'Trainingstag (Kalorienziel aktiv)',
                isSelected: isTraining,
                color: colors.primary,
                onTap: () async {
                  Navigator.of(modalContext).pop();
                  final controller = ref.read(
                    calorieGoalControllerProvider.notifier,
                  );
                  if (isPause) {
                    await controller.setPauseDay(
                      day: selectedDay,
                      isPause: false,
                    );
                  }
                  if (!settings.isTrainingDay(selectedDay)) {
                    await controller.toggleTrainingDay(selectedDay);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              _OptionTile(
                icon: Icons.weekend_rounded,
                title: '🛋️ Ruhetag',
                subtitle: 'Ausgleichendes Kalorienziel für die Regeneration',
                isSelected: isRest,
                color: colors.secondary,
                onTap: () async {
                  Navigator.of(modalContext).pop();
                  final controller = ref.read(
                    calorieGoalControllerProvider.notifier,
                  );
                  if (isPause) {
                    await controller.setPauseDay(
                      day: selectedDay,
                      isPause: false,
                    );
                  }
                  if (settings.isTrainingDay(selectedDay)) {
                    await controller.toggleTrainingDay(selectedDay);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              _OptionTile(
                icon: Icons.pause_circle_filled_rounded,
                title: '⏸️ Pausentag',
                subtitle:
                    'Neutraler Tag (Urlaub, Krankheit). Kein Streak-Bruch.',
                isSelected: isPause,
                color: colors.tertiary,
                onTap: () async {
                  Navigator.of(modalContext).pop();
                  final controller = ref.read(
                    calorieGoalControllerProvider.notifier,
                  );
                  await controller.setPauseDay(
                    day: selectedDay,
                    isPause: !isPause,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.12)
          : colors.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? color : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected ? color : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
