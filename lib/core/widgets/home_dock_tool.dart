import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';

/// Tonal tool of a tab's bottom dock: a symbol with its word on the soft
/// button surface.
class HomeDockTool extends StatelessWidget {
  /// Creates a dock tool.
  const new({
    required this.symbol,
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Icon above the word.
  final Widget symbol;

  /// Word under the symbol, shown in capitals.
  final String label;

  /// Called on tap. The tool is disabled when this is `null`.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: HomeHeaderTool(symbol: symbol, label: label, onPressed: onPressed),
    );
  }
}
