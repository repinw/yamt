import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_scope_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Two chips that switch the Fortschritt tab between the current goal and
/// all goals.
class ProgressScopeSwitch extends ConsumerWidget {
  /// Creates the scope switch.
  const new({super.key});

  /// Stable key of the chip for [scope].
  static ValueKey<String> chipKey(ProgressScope scope) =>
      ValueKey<String>('progress-scope-${scope.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(progressScopeControllerProvider);
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final scope in ProgressScope.values)
          ChoiceChip(
            key: chipKey(scope),
            label: Text(switch (scope) {
              ProgressScope.goal => l10n.progressScopeGoal,
              ProgressScope.all => l10n.progressScopeAll,
            }),
            selected: scope == selected,
            onSelected: (_) =>
                ref.read(progressScopeControllerProvider.notifier).scope =
                    scope,
          ),
      ],
    );
  }
}
