import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/core/theme/theme_option_labels.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/auth/provider/auth_service.dart'
    show userProfileProvider;
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_dialog.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _settingsMaxWidth = 560.0;
const _settingsSectionRadius = 18.0;
const _settingsTileIconSize = 34.0;

/// Defines settings page.
class SettingsPage extends ConsumerWidget {
  /// The settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final pageColor = Color.alphaBlend(
      colors.primary.withValues(alpha: 0.035),
      colors.surface,
    );

    return ColoredBox(
      color: pageColor,
      child: ListView(
        padding: responsivePagePadding(
          context,
          top: AppSpacing.xl,
          bottom: AppSpacing.xxxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _settingsMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsHeader(l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),
                  const _SettingsProfileCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _SettingsSection(
                    title: l10n.settingsAccountHouseholdSectionTitle,
                    children: [
                      _HouseholdTile(l10n: l10n),
                      _AccountTile(l10n: l10n),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsHealthGoalsSectionTitle,
                    children: const [
                      _HealthConnectTile(),
                      _CalorieGoalStartTile(),
                      _CalorieGoalCalculatorTile(),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsAppearanceSectionTitle,
                    children: const [
                      _ThemeModeTile(),
                      _SeedColorTile(),
                      _LanguageTile(),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsAppSectionTitle,
                    children: [
                      _NotImplementedTile(
                        icon: Icons.notifications_none_rounded,
                        title: l10n.settingsNotificationsTitle,
                        subtitle: l10n.settingsNotificationsSubtitle,
                        message: l10n.commonNotImplementedYet,
                      ),
                      _NotImplementedTile(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.settingsPrivacyTitle,
                        subtitle: l10n.settingsPrivacySubtitle,
                        message: l10n.commonNotImplementedYet,
                      ),
                      const _AboutTile(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeSettings,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.settingsManagePreferencesSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SettingsProfileCard extends ConsumerWidget {
  const _SettingsProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final name =
        profile?.displayName ?? profile?.email ?? l10n.accountPageGuestTitle;
    final subtitle = profile?.email ?? l10n.settingsProfileGuestSubtitle;

    return _SettingsCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_settingsSectionRadius),
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
                const _SettingsChevron(),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          _SettingsCard(
            child: Column(
              children: [
                for (var index = 0; index < children.length; index += 1) ...[
                  children[index],
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 58,
                      color: colors.outlineVariant.withValues(alpha: 0.34),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerLow : colors.surface,
        borderRadius: BorderRadius.circular(_settingsSectionRadius),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.24 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_settingsSectionRadius),
        child: child,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.showChevron = true,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showChevron;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ?? colors.primary;
    final effectiveOnTap = enabled ? onTap : null;
    final opacity = enabled ? 1.0 : 0.45;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveOnTap,
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: _settingsTileIconSize,
                  height: _settingsTileIconSize,
                  decoration: BoxDecoration(
                    color: resolvedIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: resolvedIconColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle case final subtitle?) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing case final trailing?) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing,
                ],
                if (showChevron) const _SettingsChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsChevron extends StatelessWidget {
  const _SettingsChevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 22,
    );
  }
}

class _SettingsTrailingValue extends StatelessWidget {
  const _SettingsTrailingValue({required this.value, this.swatchColor});

  final String value;
  final Color? swatchColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (swatchColor case final swatchColor?) ...[
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: swatchColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CalorieGoalStartTile extends ConsumerWidget {
  const _CalorieGoalStartTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(calorieGoalControllerProvider);
    final settings = settingsState.asData?.value;
    final latestGoal = settings?.latestGoalEntry;
    final hasGoal = latestGoal != null;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final initialGoalStartDate =
        latestGoal?.effectiveCountingStartDate ?? DateTime.now();

    return _SettingsTile(
      icon: Icons.event_note_rounded,
      title: l10n.caloriesShiftGoalStartAction,
      subtitle: hasGoal
          ? dateFormat.format(initialGoalStartDate)
          : l10n.settingsDiaryGoalSetGoalFirst,
      enabled: hasGoal && !settingsState.isLoading,
      onTap: !hasGoal || settingsState.isLoading
          ? null
          : () => unawaited(
              showCalorieGoalStartDialog(
                context: context,
                initialGoalStartDate: initialGoalStartDate,
                onSaveGoalStart: (goalStartDate) {
                  return ref
                      .read(calorieGoalControllerProvider.notifier)
                      .shiftGoalStart(goalStartDate: goalStartDate);
                },
              ),
            ),
    );
  }
}

class _CalorieGoalCalculatorTile extends ConsumerWidget {
  const _CalorieGoalCalculatorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(calorieGoalControllerProvider);
    final settings = settingsState.asData?.value;

    return _SettingsTile(
      icon: Icons.track_changes_rounded,
      title: l10n.caloriesCalculatorAction,
      subtitle: l10n.caloriesCalculatorOnboardingSubtitle,
      enabled: settings != null && !settingsState.isLoading,
      onTap: settings == null || settingsState.isLoading
          ? null
          : () => unawaited(
              showCalorieGoalCalculatorSheet(
                context,
                initialSettings: settings,
              ),
            ),
    );
  }
}

class _AboutTile extends ConsumerWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final version = ref.watch(appVersionProvider);

    return _SettingsTile(
      icon: Icons.info_outline_rounded,
      title: l10n.settingsAboutTitle,
      subtitle: l10n.settingsAboutSubtitle,
      trailing: switch (version) {
        AsyncData(:final value) => _SettingsTrailingValue(value: value),
        AsyncLoading() => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        AsyncError() => null,
      },
      showChevron: version is! AsyncLoading,
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  const _HouseholdTile({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.groups_2_outlined,
      title: l10n.settingsHouseholdTitle,
      subtitle: l10n.settingsHouseholdSubtitle,
      onTap: () => context.push(AppRoutes.homeSettingsHousehold),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.person_outline_rounded,
      title: l10n.settingsAccountTitle,
      subtitle: l10n.settingsAccountSubtitle,
      onTap: () => context.push(AppRoutes.homeSettingsAccount),
    );
  }
}

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeControllerProvider);

    return _SettingsTile(
      icon: Icons.palette_outlined,
      title: l10n.settingsThemeTitle,
      subtitle: localizedThemeModeLabel(l10n, themeMode),
      trailing: _SettingsTrailingValue(
        value: localizedThemeModeLabel(l10n, themeMode),
      ),
      onTap: () => _showThemeModeSheet(context, ref, themeMode),
    );
  }

  void _showThemeModeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode selectedMode,
  ) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: RadioGroup<ThemeMode>(
              groupValue: selectedMode,
              onChanged: (mode) {
                if (mode == null) {
                  return;
                }
                unawaited(
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(mode),
                );
                Navigator.of(sheetContext).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(localizedThemeModeLabel(l10n, mode)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SeedColorTile extends ConsumerWidget {
  const _SeedColorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seedColor = ref.watch(seedColorControllerProvider);

    return _SettingsTile(
      icon: Icons.format_paint_outlined,
      title: l10n.settingsColorTitle,
      subtitle: localizedSeedColorLabel(l10n, seedColor),
      trailing: _SettingsTrailingValue(
        value: localizedSeedColorLabel(l10n, seedColor),
        swatchColor: seedColor,
      ),
      iconColor: seedColor,
      onTap: () => _showSeedColorSheet(context, ref, seedColor),
    );
  }

  void _showSeedColorSheet(
    BuildContext context,
    WidgetRef ref,
    Color selectedColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: RadioGroup<int>(
              groupValue: selectedColor.toARGB32(),
              onChanged: (colorValue) {
                if (colorValue == null) {
                  return;
                }
                unawaited(
                  ref
                      .read(seedColorControllerProvider.notifier)
                      .setSeedColor(Color(colorValue)),
                );
                Navigator.of(sheetContext).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final color in AppSeedColors.values)
                    RadioListTile<int>(
                      value: color.toARGB32(),
                      title: Text(localizedSeedColorLabel(l10n, color)),
                      secondary: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final language = switch (languageCode) {
      'de' => l10n.settingsLanguageGerman,
      _ => l10n.settingsLanguageEnglish,
    };

    return _SettingsTile(
      icon: Icons.language_rounded,
      title: l10n.settingsLanguageTitle,
      subtitle: language,
      onTap: () =>
          _showNotImplementedSnackBar(context, l10n.commonNotImplementedYet),
    );
  }
}

class _HealthConnectTile extends ConsumerWidget {
  const _HealthConnectTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(healthConnectionControllerProvider);
    final status = statusAsync.asData?.value;
    final accessState = status?.accessState;
    final isUnsupported = accessState == HealthDataAccessState.unsupported;
    final showsInstall = accessState == HealthDataAccessState.installRequired;
    final showsConnect =
        status == null ||
        accessState == HealthDataAccessState.permissionRequired ||
        accessState == HealthDataAccessState.historyRequired;
    final needsHistoryOnly = status?.needsHistoryOnly ?? false;
    final shouldOpenPermissionSettings =
        showsConnect && status?.errorMessage != null;
    final shouldOpenAppPermissionSettings =
        status?.errorMessage == healthActivityRecognitionPermissionErrorMessage;

    return _SettingsTile(
      icon: isUnsupported
          ? Icons.block_outlined
          : showsInstall
          ? Icons.download_for_offline_outlined
          : showsConnect
          ? Icons.favorite_border_rounded
          : Icons.link_off_rounded,
      title: _tileTitle(l10n, status),
      subtitle: isUnsupported
          ? l10n.healthUnsupportedHint
          : showsInstall
          ? l10n.settingsHealthInstallSubtitle
          : showsConnect
          ? needsHistoryOnly
                ? l10n.settingsHealthHistorySubtitle
                : _connectSubtitle(l10n, status)
          : _disconnectSubtitle(l10n, status),
      trailing: statusAsync.isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      enabled: !statusAsync.isLoading && !isUnsupported,
      onTap: statusAsync.isLoading || isUnsupported
          ? null
          : showsInstall
          ? () => _installHealthConnect(ref)
          : showsConnect
          ? shouldOpenPermissionSettings
                ? shouldOpenAppPermissionSettings
                      ? () => _openAppPermissionSettings(ref)
                      : () => _openHealthPermissionSettings(ref)
                : () => _connectHealth(context, ref)
          : () => _confirmDisconnect(context, ref),
    );
  }

  Future<void> _connectHealth(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final status = await ref
        .read(healthConnectionControllerProvider.notifier)
        .connect();
    if (!context.mounted) {
      return;
    }
    if (_shouldShowConnectFailure(status)) {
      _showSnackBar(context, l10n.settingsHealthConnectFailed);
    }
  }

  Future<void> _installHealthConnect(WidgetRef ref) async {
    await ref
        .read(healthConnectionControllerProvider.notifier)
        .installHealthConnect();
  }

  Future<void> _openHealthPermissionSettings(WidgetRef ref) async {
    await ref
        .read(healthConnectionControllerProvider.notifier)
        .openHealthPermissionSettings();
  }

  Future<void> _openAppPermissionSettings(WidgetRef ref) async {
    await ref
        .read(healthConnectionControllerProvider.notifier)
        .openAppPermissionSettings();
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.read(healthConnectionControllerProvider).asData?.value;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.settingsHealthDisconnectDialogTitle),
          content: Text(_disconnectDialogBody(l10n, status)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.inventoryReceiptReviewCancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.settingsHealthDisconnectAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final result = await ref
        .read(healthConnectionControllerProvider.notifier)
        .disconnect();
    if (!context.mounted) {
      return;
    }
    final nextStatus = ref
        .read(healthConnectionControllerProvider)
        .asData
        ?.value;
    _showSnackBar(context, _disconnectMessage(l10n, result, nextStatus));
  }

  bool _shouldShowConnectFailure(HealthConnectionStatus status) {
    return status.errorMessage != null ||
        status.accessState == HealthDataAccessState.permissionRequired ||
        status.accessState == HealthDataAccessState.historyRequired ||
        status.accessState == HealthDataAccessState.installRequired ||
        status.accessState == HealthDataAccessState.unsupported;
  }

  String _disconnectMessage(
    AppLocalizations l10n,
    HealthDisconnectResult result,
    HealthConnectionStatus? status,
  ) {
    return switch (result) {
      HealthDisconnectResult.disconnected => switch (status?.platform) {
        HealthPlatform.ios => l10n.settingsAppleHealthDisconnectSuccess,
        _ => l10n.settingsHealthDisconnectSuccess,
      },
      HealthDisconnectResult.openedSettings =>
        l10n.settingsHealthDisconnectOpenedSettings,
      HealthDisconnectResult.unsupported =>
        status?.errorMessage != null
            ? l10n.settingsHealthDisconnectFailed
            : l10n.healthUnsupportedHint,
    };
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _tileTitle(AppLocalizations l10n, HealthConnectionStatus? status) {
    return switch (status?.platform) {
      HealthPlatform.ios => l10n.settingsAppleHealthTitle,
      _ => l10n.settingsHealthConnectPlatformTitle,
    };
  }

  String _connectSubtitle(
    AppLocalizations l10n,
    HealthConnectionStatus? status,
  ) {
    return switch (status?.platform) {
      HealthPlatform.ios => l10n.settingsAppleHealthConnectSubtitle,
      _ => l10n.settingsHealthConnectSubtitle,
    };
  }

  String _disconnectSubtitle(
    AppLocalizations l10n,
    HealthConnectionStatus? status,
  ) {
    return switch (status?.platform) {
      HealthPlatform.ios => l10n.settingsAppleHealthDisconnectSubtitle,
      _ => l10n.settingsHealthDisconnectSubtitle,
    };
  }

  String _disconnectDialogBody(
    AppLocalizations l10n,
    HealthConnectionStatus? status,
  ) {
    return switch (status?.platform) {
      HealthPlatform.ios => l10n.settingsAppleHealthDisconnectDialogBody,
      _ => l10n.settingsHealthDisconnectDialogBody,
    };
  }
}

class _NotImplementedTile extends StatelessWidget {
  const _NotImplementedTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => _showNotImplementedSnackBar(context, message),
    );
  }
}

void _showNotImplementedSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
