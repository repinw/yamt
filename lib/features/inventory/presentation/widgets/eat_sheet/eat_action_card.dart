import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_title.dart';

/// One line of an [EatActionCard].
typedef EatCardAction = ({
  Key key,
  IconData icon,
  String label,
  Color color,
  VoidCallback? onPressed,
});

/// Card of tappable actions on the food label pages, drawn like a second
/// food label: a title and one line per action.
class EatActionCard extends StatelessWidget {
  /// Creates the card.
  const new({required this.title, required this.actions, super.key});

  /// Title of the card.
  final String title;

  /// Lines of the card, from top to bottom. A line without `onPressed` is
  /// muted.
  final List<EatCardAction> actions;

  @override
  Widget build(BuildContext context) {
    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EatLabelTitle(text: title),
          for (final (index, action) in actions.indexed)
            _ActionLine(
              key: action.key,
              icon: action.icon,
              label: action.label,
              color: action.color,
              showRule: index < actions.length - 1,
              onPressed: action.onPressed,
            ),
        ],
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.showRule,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final foreground = onPressed == null ? colors.muted : color;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: showRule ? BorderSide(color: colors.ink) : BorderSide.none,
        ),
      ),
      child: AppInkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Icon(icon, color: foreground),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ),
              if (onPressed != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: foreground,
                  size: AppSizes.actionChevron,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
