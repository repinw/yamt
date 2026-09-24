import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_summary_card/settings_profile_summary_card.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The user's current profile: body data and goals, opened from the Home
/// side menu.
class ProfilePage extends StatelessWidget {
  /// Creates the profile page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeProfile)),
      body: SingleChildScrollView(
        padding: responsivePagePadding(
          context,
          top: AppSpacing.xl,
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: settingsMaxWidth),
            child: const SettingsProfileSummaryCard(),
          ),
        ),
      ),
    );
  }
}
