import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Success screen shown after cookflow saved a meal.
class CookingFlowSuccessPage extends StatelessWidget {
  /// Creates success page.
  const CookingFlowSuccessPage({
    required this.mealName,
    required this.onInventoryPressed,
    super.key,
  });

  /// Saved meal name.
  final String mealName;

  /// Opens inventory after save.
  final VoidCallback onInventoryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return CookingFlowStepLayout(
      title: l10n.cookflowSuccessTitle,
      subtitle: l10n.cookflowSuccessSubtitle,
      children: <Widget>[
        DecoratedBox(
          decoration: AppEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(
              AppEditorial.cardRadius,
            ),
            blurRadius: 22,
            shadowOffset: const Offset(0, 10),
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  l10n.cookflowSuccessHeadline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  mealName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                SizedBox(
                  width: double.infinity,
                  child: CookingFlowActionButton(
                    label: l10n.cookflowToInventoryButton,
                    onPressed: onInventoryPressed,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
