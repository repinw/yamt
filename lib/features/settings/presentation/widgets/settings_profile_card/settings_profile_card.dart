import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/auth/data/auth_service.dart'
    show userProfileProvider;
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Profile summary card shown at the top of settings.
class SettingsProfileCard extends ConsumerWidget {
  /// Creates a settings profile card.
  const SettingsProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final name =
        profile?.displayName ?? profile?.email ?? l10n.accountPageGuestTitle;
    final subtitle = profile?.email ?? l10n.settingsProfileGuestSubtitle;

    return SettingsCard(
      key: SettingsPageKeys.profileCard,
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push(AppRoutes.homeSettingsAccount),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _SettingsAvatar(name: name),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SettingsChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsAvatar extends StatelessWidget {
  const _SettingsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
