import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/initial_tile.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Who the user is: a tilted initial, the name, and the account state.
/// Tapping it opens the account page.
class ProfileIdentityRow extends StatelessWidget {
  /// Creates the identity row for [account].
  const new({required this.account, super.key});

  /// The signed-in user.
  final ProfileSummaryAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = account.name ?? account.email ?? l10n.homeMenuGuest;
    final subtitle = account.isGuest ? l10n.homeMenuGuest : account.email;

    return AppInkWell(
      onTap: () => unawaited(context.push(AppRoutes.homeSettingsAccount)),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            InitialTile(text: title),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null && subtitle != title)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
