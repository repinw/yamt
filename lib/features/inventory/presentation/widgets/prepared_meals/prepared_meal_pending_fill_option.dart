import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// One way to fill an open row: an icon, a title, and a description.
class PreparedMealPendingFillOption extends StatelessWidget {
  /// Creates the option.
  const new({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  /// The icon in the tile.
  final Widget icon;

  /// The option's name.
  final String title;

  /// What the option does.
  final String description;

  /// Chooses the option.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: AppInkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppGraphit.toolButton),
          child: Row(
            spacing: AppSpacing.lg,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.tile,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: IconTheme(
                    data: IconThemeData(
                      color: colors.ink,
                      size: AppGraphit.toolIcon,
                    ),
                    child: icon,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xxs,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
