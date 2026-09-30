import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_progress_indicator.dart';
import 'package:yamt/l10n/app_localizations.dart';

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
                          style: context.graphitKickerStyle,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                      ],
                      Text(
                        l10n.cookflowPrepflowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.graphitDisplayStyle(
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
