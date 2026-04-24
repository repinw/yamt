import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/core/theme/theme_option_labels.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/features/auth/provider/guest_name_setup_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines guest name setup page.
class GuestNameSetupPage extends ConsumerStatefulWidget {
  /// The guest name setup page.
  const GuestNameSetupPage({super.key});

  @override
  ConsumerState<GuestNameSetupPage> createState() => _GuestNameSetupPageState();
}

class _GuestNameSetupPageState extends ConsumerState<GuestNameSetupPage> {
  static const double _colorPreviewSize = AppSpacing.xl;

  final _nameController = TextEditingController();
  String? _errorText;
  late SeedColorController _seedColorController;
  late ThemeModeController _themeModeController;
  late Color _initialSeedColor;
  late ThemeMode _initialThemeMode;
  late Color _selectedSeedColor;
  late ThemeMode _selectedThemeMode;
  bool _didPersistSetup = false;

  @override
  void initState() {
    super.initState();
    _seedColorController = ref.read(seedColorControllerProvider.notifier);
    _themeModeController = ref.read(themeModeControllerProvider.notifier);
    final defaults = ref
        .read(guestNameSetupControllerProvider.notifier)
        .initialFormDefaults();
    _initialSeedColor = defaults.seedColor;
    _initialThemeMode = defaults.themeMode;
    _selectedSeedColor = defaults.seedColor;
    _selectedThemeMode = defaults.themeMode;
    if (defaults.prefilledName != null) {
      _nameController.text = defaults.prefilledName!;
    }
  }

  @override
  void dispose() {
    _restorePreviewIfNeeded();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(guestNameSetupControllerProvider);
    final canCancelGuestSetup = ref
        .read(guestNameSetupControllerProvider.notifier)
        .canCancelGuestSetup();
    final authErrorViewModel = ref.watch(authErrorViewModelProvider);

    ref.listen<AsyncValue<void>>(guestNameSetupControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, stackTrace) {
          if (!context.mounted) {
            return;
          }
          final message = authErrorViewModel.messageFor(
            l10n: l10n,
            error: error,
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        leading: canCancelGuestSetup
            ? IconButton(
                key: const Key('guest_name_setup_back_button'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: state.isLoading ? null : _cancelGuestSetup,
              )
            : null,
        title: Text(l10n.authGuestNameSetupTitle),
      ),
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
              key: ValueKey<int>(_selectedSeedColor.toARGB32()),
              initialValue: _selectedSeedColor.toARGB32(),
              decoration: InputDecoration(labelText: l10n.settingsColorTitle),
              onChanged: state.isLoading
                  ? null
                  : (selectedValue) {
                      if (selectedValue == null) {
                        return;
                      }
                      setState(() {
                        _selectedSeedColor = Color(selectedValue);
                      });
                      _seedColorController.previewSeedColor(_selectedSeedColor);
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
              key: ValueKey<ThemeMode>(_selectedThemeMode),
              initialValue: _selectedThemeMode,
              decoration: InputDecoration(labelText: l10n.settingsThemeTitle),
              onChanged: state.isLoading
                  ? null
                  : (selectedMode) {
                      if (selectedMode == null) {
                        return;
                      }
                      setState(() {
                        _selectedThemeMode = selectedMode;
                      });
                      _themeModeController.previewThemeMode(_selectedThemeMode);
                    },
              items: [
                for (final mode in ThemeMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(localizedThemeModeLabel(l10n, mode)),
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

  Future<void> _cancelGuestSetup() async {
    if (ref.read(guestNameSetupControllerProvider).isLoading) {
      return;
    }
    await ref
        .read(guestNameSetupControllerProvider.notifier)
        .cancelGuestSetup();
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

    await ref
        .read(guestNameSetupControllerProvider.notifier)
        .saveDisplayName(
          name,
          seedColor: _selectedSeedColor,
          themeMode: _selectedThemeMode,
        );
    if (!mounted) {
      return;
    }
    final nextState = ref.read(guestNameSetupControllerProvider);
    if (!nextState.hasError) {
      _didPersistSetup = true;
    }
  }

  Widget _colorDropdownItem(AppLocalizations l10n, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: _colorPreviewSize,
          height: _colorPreviewSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(localizedSeedColorLabel(l10n, color)),
      ],
    );
  }

  void _restorePreviewIfNeeded() {
    if (_didPersistSetup) {
      return;
    }
    try {
      _seedColorController.previewSeedColor(_initialSeedColor);
      _themeModeController.previewThemeMode(_initialThemeMode);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Guest setup preview restore failed during dispose',
        name: 'GuestNameSetupPage',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
