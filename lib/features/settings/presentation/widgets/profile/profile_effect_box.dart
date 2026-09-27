import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_kicker.dart';

/// A framed box that lists what an edit changes, with a note below.
class ProfileEffectBox extends StatelessWidget {
  /// Creates the box.
  const new({
    required this.title,
    required this.rows,
    required this.note,
    super.key,
  });

  /// Caption of the box, such as "What changes from today".
  final String title;

  /// One [ProfileEffectRow] per change.
  final List<Widget> rows;

  /// Why the edit changes what it changes.
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = FoodLabelColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: label.rule)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ProfileKicker(text: title),
            ),
            ...rows,
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(color: label.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One change in a [ProfileEffectBox]: a caption, a value, and an optional
/// color square before the caption.
class ProfileEffectRow extends StatelessWidget {
  /// Creates the row.
  const new({required this.label, required this.value, this.color, super.key});

  /// What changes.
  final String label;

  /// The change, such as "70 → 79 g".
  final String value;

  /// Color of the square before [label], or `null` for none.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = this.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: FoodLabelColors.of(context).rule),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          spacing: AppSpacing.xs,
          children: [
            if (color != null)
              SizedBox.square(
                dimension: AppSizes.profileMacroSquare,
                child: ColoredBox(color: color),
              ),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
