import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Label row of a cooking flow button with optional icons.
class CookingFlowButtonLabel extends StatelessWidget {
  /// Creates the label.
  const new({
    required this.label,
    required this.color,
    this.leadingIcon,
    this.trailingIcon,
    super.key,
  });

  /// Button text.
  final String label;

  /// Text color.
  final Color color;

  /// Optional icon before the text.
  final IconData? leadingIcon;

  /// Optional icon after the text.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (leadingIcon != null) ...<Widget>[
          Icon(leadingIcon, size: AppGraphit.toolIcon),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailingIcon != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Icon(trailingIcon, size: AppGraphit.toolIcon),
        ],
      ],
    );
  }
}
