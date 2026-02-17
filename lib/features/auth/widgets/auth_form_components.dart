import 'package:form_validator/form_validator.dart';
import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

ValidationBuilder _localizedValidationBuilder(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final languageCode = locale.languageCode.toLowerCase();
  final countryCode = locale.countryCode?.toLowerCase();
  final regionLocale = countryCode == null || countryCode.isEmpty
      ? languageCode
      : '$languageCode-$countryCode';

  for (final localeName in [regionLocale, languageCode, 'en']) {
    try {
      return ValidationBuilder(localeName: localeName);
    } on ArgumentError {
      // Try the next locale candidate.
    }
  }

  return ValidationBuilder(localeName: 'en');
}

StringValidationCallback buildEmailValidator(BuildContext context) {
  return _localizedValidationBuilder(context).email().build();
}

StringValidationCallback buildPasswordValidator(
  BuildContext context, {
  int minLength = 6,
}) {
  return _localizedValidationBuilder(context).minLength(minLength).build();
}

StringValidationCallback buildConfirmPasswordValidator(
  TextEditingController passwordController,
  BuildContext context, {
  required String mismatchMessage,
}) {
  return _localizedValidationBuilder(context).add((value) {
    if (value?.trim() != passwordController.text.trim()) {
      return mismatchMessage;
    }
    return null;
  }).build();
}

class AuthEmailField extends StatelessWidget {
  const AuthEmailField({
    required this.controller,
    required this.validator,
    this.label,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final TextEditingController controller;
  final StringValidationCallback validator;
  final String? label;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label ?? l10n.emailLabel,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => validator(value?.trim()),
    );
  }
}

class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    required this.controller,
    required this.validator,
    this.label,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final TextEditingController controller;
  final StringValidationCallback validator;
  final String? label;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      obscureText: true,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label ?? l10n.passwordLabel,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => validator(value?.trim()),
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
