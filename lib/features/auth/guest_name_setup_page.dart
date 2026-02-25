import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(guestNameSetupControllerProvider);

    ref.listen<AsyncValue<void>>(guestNameSetupControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (_) {
          if (context.mounted) {
            context.go(AppRoutes.homeInventory);
          }
        },
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
