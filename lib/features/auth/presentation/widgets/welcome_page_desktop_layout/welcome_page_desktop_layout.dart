import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_card/auth_card.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_header/auth_header.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
import 'package:yamt/features/auth/presentation/widgets/welcome_page_editorial_aside/welcome_page_editorial_aside.dart';
import 'package:yamt/features/shared/widgets/credential_form_ui_constants.dart';

/// Wide auth welcome layout.
class DesktopAuthLayout extends StatelessWidget {
  /// Creates the wide auth welcome layout.
  const new({required this.metrics, super.key});

  /// Current layout metrics.
  final AuthLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: EditorialAside()),
        const SizedBox(width: AppSpacing.xxxxl),
        SizedBox(
          width: CredentialFormUi.maxContentWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(isWide: true, metrics: metrics),
              SizedBox(height: metrics.headerSpacing),
              AuthCard(metrics: metrics),
            ],
          ),
        ),
      ],
    );
  }
}
