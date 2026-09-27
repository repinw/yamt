import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_content.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The user's profile: who they are, their weight, body data, and goal.
/// The side menu opens it.
class ProfilePage extends ConsumerWidget {
  /// Creates the profile page.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(profileSummaryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeProfile)),
      body: summary.when(
        data: (state) => ProfileContent(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: AppInsets.page,
            child: Text(l10n.settingsProfileSummaryLoadFailed),
          ),
        ),
      ),
    );
  }
}
