import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_import_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Premium, rich empty state for the cookbook page.
class MealTemplatesEmptyState extends ConsumerWidget {
  /// Creates a premium empty state widget.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final borderRadius = BorderRadius.circular(AppRadius.xl);

    return Center(
      child: SingleChildScrollView(
        padding: AppInsets.pageLarge,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: borderRadius,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GlowingHalo(icon: Icons.restaurant_menu_rounded),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.homeCookbook,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.preparedMealTemplatesEmptyState,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => startRecipeTemplateImport(context, ref),
                  icon: const Icon(Icons.add_link_rounded),
                  label: Text(l10n.preparedMealTemplateAddRecipeAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingHalo extends StatelessWidget {
  const new({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: 96,
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primaryContainer.withValues(alpha: 0.8),
          ),
          child: Icon(icon, size: 32, color: colors.secondary),
        ),
      ),
    );
  }
}
