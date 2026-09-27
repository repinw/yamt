import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_builder.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_progress_indicator.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_text_styles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Bottom action used by phase pages.
class CookingFlowPhaseBottomAction extends StatelessWidget {
  /// Creates bottom action.
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
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
        ),
      ),
    );
  }
}

/// Bottom action with secondary and primary button.
class CookingFlowPhaseBottomDualAction extends StatelessWidget {
  /// Creates dual action.
  const new({
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
          CookingFlowQuietButton(
            label: secondaryLabel,
            onPressed: onSecondaryPressed,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: CookingFlowActionButton(
              label: primaryLabel,
              onPressed: onPrimaryPressed,
              leadingIcon: primaryLeadingIcon,
              icon: primaryTrailingIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class _CookingFlowPhaseBottomSurface extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final horizontalInset = responsivePageHorizontalPadding(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            AppSpacing.md,
            horizontalInset,
            AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Cookflow top app bar: back, the phase as a small caption over the title,
/// and the step progress on the right.
class CookflowTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates top bar.
  const new({
    required this.onBackPressed,
    required this.progressIndex,
    super.key,
  });

  /// Back callback.
  final VoidCallback? onBackPressed;

  /// Optional zero-based phase progress index.
  final int? progressIndex;

  static const int _phaseCount = 4;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final horizontalInset = responsivePageHorizontalPadding(context);
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final phaseLabel = progressIndex == null
        ? null
        : l10n.cookflowPhaseChip(progressIndex! + 1, _phaseCount);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: EdgeInsets.only(
              left: onBackPressed == null ? horizontalInset : AppSpacing.xs,
              right: horizontalInset,
            ),
            child: Row(
              children: <Widget>[
                if (onBackPressed != null) ...<Widget>[
                  IconButton(
                    onPressed: onBackPressed,
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    color: colors.ink,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (phaseLabel != null) ...<Widget>[
                        Text(
                          phaseLabel.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.cookingFlowKickerStyle,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                      ],
                      Text(
                        l10n.cookflowPrepflowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.cookingFlowDisplayStyle(
                          textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                if (progressIndex != null)
                  CookingFlowProgressIndicator(
                    activeIndex: progressIndex!,
                    semanticLabel: l10n.cookflowPhaseChip(
                      progressIndex! + 1,
                      _phaseCount,
                    ),
                  ),
              ],
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
  new({
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
  int get grossWeight =>
      parseCookingFlowWholeWeight(grossWeightController.text);

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
