import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_body_tiles.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_identity_row.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_kicker.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_weight_card.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The profile page body: identity, weight, and body data.
class ProfileContent extends StatelessWidget {
  /// Creates the profile content for [state].
  const new({required this.state, super.key});

  /// The profile summary to show.
  final ProfileSummaryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = state.profile;
    return ListView(
      padding: responsivePagePadding(
        context,
        top: AppSpacing.md,
        bottom: AppSpacing.xxxxl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: settingsMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileIdentityRow(account: state.account),
                const SizedBox(height: AppSpacing.xl),
                ProfileWeightCard(state: state),
                _SectionTitle(text: l10n.profileBodySection),
                if (profile == null)
                  Text(l10n.settingsProfileSummaryNoProfile)
                else
                  ProfileBodyTiles(state: state, profile: profile),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxxl,
        bottom: AppSpacing.xs,
      ),
      child: ProfileKicker(text: text),
    );
  }
}
