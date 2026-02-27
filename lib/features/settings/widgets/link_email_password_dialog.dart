import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/widgets/register_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

class EmailPasswordCredentials {
  const EmailPasswordCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

class LinkEmailPasswordDialog extends StatelessWidget {
  const LinkEmailPasswordDialog({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final registerFormKey = GlobalKey<RegisterFormState>();

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.accountPageLinkEmailPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.accountPageLinkEmailPasswordDescription),
          const SizedBox(height: AppSpacing.md),
          RegisterForm(
            key: registerFormKey,
            submitLabel: l10n.accountPageLinkEmailPasswordConfirmAction,
            showSubmitButton: false,
            onSubmitCredentials: ({required email, required password}) async {
              if (!context.mounted) {
                return;
              }
              Navigator.of(
                context,
              ).pop(EmailPasswordCredentials(email: email, password: password));
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            registerFormKey.currentState?.submit();
          },
          child: Text(l10n.accountPageLinkEmailPasswordConfirmAction),
        ),
      ],
    );
  }
}
