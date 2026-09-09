import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/presentation/auth_error_message_mapper.dart';
import 'package:yamt/features/auth/presentation/controllers/guest_name_setup_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines guest name setup page.
class GuestNameSetupPage extends ConsumerStatefulWidget {
  /// The guest name setup page.
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
    final defaults = ref
        .read(guestNameSetupControllerProvider.notifier)
        .initialFormDefaults();
    if (defaults.prefilledName != null) {
      _nameController.text = defaults.prefilledName!;
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
    final canCancelGuestSetup = ref.watch(canCancelGuestSetupProvider);
    final authErrorMessageMapper = ref.watch(authErrorMessageMapperProvider);

    ref.listen<AsyncValue<void>>(guestNameSetupControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, stackTrace) {
          if (!context.mounted) {
            return;
          }
          final message = authErrorMessageMapper.messageFor(
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
        .saveDisplayName(name);
  }
}
