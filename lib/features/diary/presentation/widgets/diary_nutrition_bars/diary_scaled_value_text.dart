import 'package:material_ui/material_ui.dart';

/// One-line value that shrinks to fit its width but keeps the line height of
/// [style], so rows do not change height when a longer value appears.
class DiaryScaledValueText extends StatelessWidget {
  /// Creates the value text.
  const new(this.value, {required this.style, super.key});

  /// Text to show.
  final String value;

  /// Full-size text style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        // Reserves the full-size line height.
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Text('0', maxLines: 1, style: style),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(value, maxLines: 1, style: style),
        ),
      ],
    );
  }
}
