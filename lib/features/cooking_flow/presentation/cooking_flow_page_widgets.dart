import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_builder.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_progress_indicator.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Bottom action used by phase pages.
class CookingFlowPhaseBottomAction extends StatelessWidget {
  /// Creates bottom action.
  const CookingFlowPhaseBottomAction({
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    super.key,
  });

  /// Button label.
  final String label;

  /// Tap callback.
  final VoidCallback? onPressed;

  /// Optional trailing icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _CookingFlowPhaseBottomSurface(
      child: SizedBox(
        width: double.infinity,
        child: CookingFlowActionButton(
          label: label,
          onPressed: onPressed,
          icon: icon,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
        ),
      ),
    );
  }
}

/// Bottom action with secondary and primary button.
class CookingFlowPhaseBottomDualAction extends StatelessWidget {
  /// Creates dual action.
  const CookingFlowPhaseBottomDualAction({
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.primaryLeadingIcon,
    this.primaryTrailingIcon,
    super.key,
  });

  /// Secondary label.
  final String secondaryLabel;

  /// Secondary tap callback.
  final VoidCallback? onSecondaryPressed;

  /// Primary label.
  final String primaryLabel;

  /// Primary tap callback.
  final VoidCallback? onPrimaryPressed;

  /// Optional leading icon.
  final IconData? primaryLeadingIcon;

  /// Optional trailing icon.
  final IconData? primaryTrailingIcon;

  @override
  Widget build(BuildContext context) {
    return _CookingFlowPhaseBottomSurface(
      child: Row(
        children: <Widget>[
          Expanded(
            child: CookingFlowSecondaryActionButton(
              label: secondaryLabel,
              onPressed: onSecondaryPressed,
              icon: Icons.schedule_rounded,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: CookingFlowActionButton(
              label: primaryLabel,
              onPressed: onPrimaryPressed,
              leadingIcon: primaryLeadingIcon,
              icon: primaryTrailingIcon,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CookingFlowPhaseBottomSurface extends StatelessWidget {
  const _CookingFlowPhaseBottomSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final horizontalInset = responsivePageHorizontalPadding(context);
    final radius = BorderRadius.circular(AppRadius.xl);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          AppSpacing.md,
          horizontalInset,
          AppSpacing.xl,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: <BoxShadow>[
              AppEditorialSurfaces.ambientBoxShadow(
                colors,
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppEditorial.glassBlur,
                sigmaY: AppEditorial.glassBlur,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppEditorialSurfaces.glass(colors).withValues(
                    alpha: 0.94,
                  ),
                  borderRadius: radius,
                  border: Border.all(
                    color: AppEditorialSurfaces.ghostBorder(colors),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cookflow top app bar.
class CookflowTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates top bar.
  const CookflowTopBar({
    required this.onBackPressed,
    required this.progressIndex,
    super.key,
  });

  /// Back callback.
  final VoidCallback? onBackPressed;

  /// Optional zero-based phase progress index.
  final int? progressIndex;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final horizontalInset = responsivePageHorizontalPadding(context);
    final l10n = AppLocalizations.of(context)!;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppEditorial.glassBlur,
          sigmaY: AppEditorial.glassBlur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppEditorialSurfaces.glass(colors),
            border: Border(
              bottom: BorderSide(
                color: AppEditorialSurfaces.ghostBorder(
                  colors,
                ).withValues(alpha: 0.2),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                child: Row(
                  children: <Widget>[
                    if (onBackPressed != null) ...<Widget>[
                      IconButton(
                        onPressed: onBackPressed,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    const Icon(
                      Icons.soup_kitchen_outlined,
                      color: AppSeedColors.orange,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.cookflowPrepflowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (progressIndex != null)
                      CookingFlowProgressIndicator(
                        activeIndex: progressIndex!,
                        semanticLabel: l10n.cookflowPhaseChip(
                          progressIndex! + 1,
                          4,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Default tara text for new containers.
const String cookingFlowTaraDefaultValue = '1000';

/// Text controller state for one storage container row.
class CookingFlowStorageContainerState {
  /// Creates storage container state.
  CookingFlowStorageContainerState({
    required this.id,
    required this.labelController,
    required this.taraController,
    required this.grossWeightController,
    required this.portionController,
    required this.usesPrimaryWeightControllers,
    this.taraUtensilId,
  });

  /// Stable id.
  final String id;

  /// Optional display label controller.
  final TextEditingController labelController;

  /// Tara text controller.
  final TextEditingController taraController;

  /// Gross text controller.
  final TextEditingController grossWeightController;

  /// Portion text controller.
  final TextEditingController portionController;

  /// Whether this row uses legacy primary controllers.
  final bool usesPrimaryWeightControllers;

  /// Selected utensil id.
  String? taraUtensilId;

  /// Tara grams.
  int get taraWeight => parseCookingFlowWholeWeight(taraController.text);

  /// Gross grams.
  int get grossWeight => parseCookingFlowWholeWeight(
    grossWeightController.text,
  );

  /// Net grams.
  int get finalNetWeight => grossWeight - taraWeight;

  /// Total portions.
  int get totalPortions {
    final portions = parseCookingFlowWholeWeight(portionController.text);
    return portions < 1 ? 0 : portions;
  }

  /// Disposes owned controllers.
  void dispose() {
    labelController.dispose();
    portionController.dispose();
    if (!usesPrimaryWeightControllers) {
      taraController.dispose();
      grossWeightController.dispose();
    }
  }
}
