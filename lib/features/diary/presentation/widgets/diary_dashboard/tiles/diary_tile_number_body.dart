import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';

/// A tile's number with caption lines below it.
///
/// Captions drop out from the last one on when the tile is too low for
/// them, for example with large text, so the number never gets squeezed.
class DiaryTileNumberBody extends StatelessWidget {
  /// Creates the body of [number] with [captions].
  const new({required this.number, this.captions = const [], super.key});

  /// The number, usually a `DiaryTileNumber`.
  final Widget number;

  /// Caption lines below the number, most important first.
  final List<Widget> captions;

  @override
  Widget build(BuildContext context) {
    final lineHeight = MediaQuery.textScalerOf(context)
        .scale(AppDashboard.captionLineHeight);
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxHeight - AppDashboard.numberMinHeight;
        final fitting = room <= 0
            ? 0
            : (room / lineHeight).floor().clamp(0, captions.length);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: number),
            ...captions.take(fitting),
          ],
        );
      },
    );
  }
}
