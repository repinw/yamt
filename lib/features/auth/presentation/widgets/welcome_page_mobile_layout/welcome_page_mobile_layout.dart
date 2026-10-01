import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_card/auth_card.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_header/auth_header.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';

/// Narrow auth welcome layout.
class MobileAuthLayout extends StatelessWidget {
  /// Creates the narrow auth welcome layout.
  const new({required this.metrics, super.key});

  /// Current layout metrics.
  final AuthLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: metrics.centerContent
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(isWide: false, metrics: metrics),
        SizedBox(height: metrics.headerSpacing),
        AuthCard(metrics: metrics),
      ],
    );
  }
}
