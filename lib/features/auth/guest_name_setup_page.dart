import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/features/auth/domain/auth_user_extensions.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/provider/guest_name_setup_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class GuestNameSetupPage extends ConsumerStatefulWidget {
  const GuestNameSetupPage({super.key});

  @override
  ConsumerState<GuestNameSetupPage> createState() => _GuestNameSetupPageState();
}

class _GuestNameSetupPageState extends ConsumerState<GuestNameSetupPage> {
  final _nameController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      return;
    }
    if (!currentUser.isLikelyFirstSignIn) {
      return;
    }
    final currentDisplayName = currentUser.displayName?.trim();
    if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
      _nameController.text = currentDisplayName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(guestNameSetupControllerProvider);
    final selectedSeedColor = ref.watch(seedColorControllerProvider);
    final selectedThemeMode = ref.watch(themeModeControllerProvider);

    ref.listen<AsyncValue<void>>(guestNameSetupControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, stackTrace) {
          final message = ref
              .read(authErrorViewModelProvider)
              .messageFor(l10n: l10n, error: error);
          if (!context.mounted) {
            return;
          }
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authGuestNameSetupTitle)),
      body: Padding(
        padding: AppInsets.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.authGuestNameSetupSubtitle),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(l10n),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: l10n.authGuestNameFieldLabel,
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            DropdownButtonFormField<int>(
              key: ValueKey<int>(selectedSeedColor.toARGB32()),
              initialValue: selectedSeedColor.toARGB32(),
              decoration: InputDecoration(labelText: l10n.settingsColorTitle),
              onChanged: state.isLoading
                  ? null
                  : (selectedValue) {
                      if (selectedValue == null) {
                        return;
                      }
                      unawaited(
                        ref
                            .read(seedColorControllerProvider.notifier)
                            .setSeedColor(Color(selectedValue)),
                      );
                    },
              items: [
                for (final color in AppSeedColors.values)
                  DropdownMenuItem(
                    value: color.toARGB32(),
                    child: _colorDropdownItem(l10n, color),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            DropdownButtonFormField<ThemeMode>(
              key: ValueKey<ThemeMode>(selectedThemeMode),
              initialValue: selectedThemeMode,
              decoration: InputDecoration(labelText: l10n.settingsThemeTitle),
              onChanged: state.isLoading
                  ? null
                  : (selectedMode) {
                      if (selectedMode == null) {
                        return;
                      }
                      unawaited(
                        ref
                            .read(themeModeControllerProvider.notifier)
                            .setThemeMode(selectedMode),
                      );
                    },
              items: [
                for (final mode in ThemeMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(_themeModeLabel(l10n, mode)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: state.isLoading ? null : () => _submit(l10n),
              child: state.isLoading
                  ? const SizedBox.square(
                      dimension: AppSizes.inlineProgressIndicator,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.progressStrokeWidth,
                      ),
                    )
                  : Text(l10n.authGuestNameSaveAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (ref.read(guestNameSetupControllerProvider).isLoading) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = l10n.authGuestNameRequiredError;
      });
      return;
    }

    final selectedSeedColor = ref.read(seedColorControllerProvider);
    final selectedThemeMode = ref.read(themeModeControllerProvider);
    await ref
        .read(guestNameSetupControllerProvider.notifier)
        .saveDisplayName(
          name,
          seedColor: selectedSeedColor,
          themeMode: selectedThemeMode,
        );
  }

  Widget _colorDropdownItem(AppLocalizations l10n, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: AppSpacing.xl,
          height: AppSpacing.xl,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(_seedColorLabel(l10n, color)),
      ],
    );
  }

  String _seedColorLabel(AppLocalizations l10n, Color color) {
    return switch (color.toARGB32()) {
      int value when value == AppSeedColors.lime.toARGB32() =>
        l10n.settingsColorLime,
      int value when value == AppSeedColors.blue.toARGB32() =>
        l10n.settingsColorBlue,
      int value when value == AppSeedColors.teal.toARGB32() =>
        l10n.settingsColorTeal,
      int value when value == AppSeedColors.pink.toARGB32() =>
        l10n.settingsColorPink,
      int value when value == AppSeedColors.orange.toARGB32() =>
        l10n.settingsColorOrange,
      _ => l10n.settingsColorLime,
    };
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };
  }
}
