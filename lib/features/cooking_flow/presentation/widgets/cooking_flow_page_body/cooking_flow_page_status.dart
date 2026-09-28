import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// Centered state of the cookflow body: a spinner while loading, or a
/// message when the template cannot be shown.
class CookingFlowPageStatus extends StatelessWidget {
  /// Creates the status view. Without [message] it shows a spinner.
  const new({this.message, super.key});

  /// Message to show instead of the spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text != null) {
      return Center(
        child: Padding(padding: AppInsets.page, child: Text(text)),
      );
    }
    return const Center(
      child: SizedBox.square(
        dimension: AppSizes.inlineProgressIndicator,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.progressStrokeWidth,
        ),
      ),
    );
  }
}
