import 'package:form_validator/form_validator.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

String _resolveValidationLocaleName(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final languageCode = locale.languageCode.toLowerCase();
  final countryCode = locale.countryCode?.toLowerCase();
  final regionLocale =
      countryCode == null ||
          countryCode
              .isEmpty // coverage:ignore-line
      ? languageCode
      : '$languageCode-$countryCode'; // coverage:ignore-line

  // coverage:ignore-start
  for (final localeName in [regionLocale, languageCode, 'en']) {
    try {
      ValidationBuilder(localeName: localeName);
      return localeName;
    } on ArgumentError {
      // Try the next locale candidate.
    }
  }
  // coverage:ignore-end

  return 'en';
}

class AuthValidationFactory {
  const AuthValidationFactory._(this._localeName);

  factory AuthValidationFactory.fromContext(BuildContext context) {
    return AuthValidationFactory._(_resolveValidationLocaleName(context));
  }

  final String _localeName;

  ValidationBuilder _builder() => ValidationBuilder(localeName: _localeName);

  StringValidationCallback email() => _builder().email().build();

  StringValidationCallback password({int minLength = 6}) {
    return _builder().minLength(minLength).build();
  }

  StringValidationCallback confirmPassword({
    required TextEditingController passwordController,
    required String mismatchMessage,
  }) {
    return _builder().add((value) {
      if (value?.trim() != passwordController.text.trim()) {
        return mismatchMessage;
      }
      return null;
    }).build();
  }
}

StringValidationCallback buildEmailValidator(BuildContext context) {
  return AuthValidationFactory.fromContext(context).email();
}

StringValidationCallback buildPasswordValidator(
  BuildContext context, {
  int minLength = 6,
}) {
  return AuthValidationFactory.fromContext(
    context,
  ).password(minLength: minLength);
}

StringValidationCallback buildConfirmPasswordValidator(
  TextEditingController passwordController,
  BuildContext context, {
  required String mismatchMessage,
}) {
  return AuthValidationFactory.fromContext(context).confirmPassword(
    passwordController: passwordController,
    mismatchMessage: mismatchMessage,
  );
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
              width: AppSizes.inlineProgressIndicator,
              height: AppSizes.inlineProgressIndicator,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
              ),
            )
          : Text(label),
    );
  }
}
