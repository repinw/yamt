import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/app_update/presentation/app_update_store_flow.dart';
import 'package:yamt/features/app_update/presentation/widgets/app_update_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shown instead of the app while it is older than the minimum version, so
/// it cannot read or rewrite data that a newer version migrated.
///
/// The router leaves this page once the minimum version allows this app.
class UpdateRequiredPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Large text scaling must not push the only action off screen.
          child: SingleChildScrollView(
            padding: AppInsets.pageLarge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appUpdateRequiredTitle,
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.appUpdateRequiredBody,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  key: AppUpdateKeys.requiredUpdateAction,
                  onPressed: () => openAppUpdateStore(context),
                  child: Text(l10n.appUpdateAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
