import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_kicker.dart';

/// One fact about the user: a caption, a big value, and a note.
///
/// A tile with [onTap] is round and filled and shows a pen; a tile without
/// only shows a thin frame, because the app works its value out itself.
class ProfileFactTile extends StatelessWidget {
  /// Creates a fact tile.
  const new({
    required this.label,
    required this.value,
    this.note,
    this.onTap,
    super.key,
  });

  /// Caption above the value.
  final String label;

  /// The value.
  final String value;

  /// Small text under the value.
  final String? note;

  /// Opens the editor of this fact, or `null` when the fact is read-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FoodLabelColors.of(context);
    final note = this.note;
    final radius = BorderRadius.circular(AppRadius.md);
    final isEditable = onTap != null;
    return Material(
      color: isEditable ? colors.tile : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isEditable ? BorderSide.none : BorderSide(color: colors.rule),
      ),
      child: AppInkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xxs,
            children: [
              Row(
                children: [
                  Expanded(child: ProfileKicker(text: label)),
                  if (isEditable)
                    Icon(
                      Icons.edit_outlined,
                      size: AppFontSizes.bodyMedium,
                      color: colors.muted,
                    ),
                ],
              ),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (note != null)
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
