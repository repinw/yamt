import 'package:form_validator/form_validator.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/auth_ui_constants.dart';
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

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.validator,
    required this.label,
    this.showLabel = true,
    this.prefixIcon,
    this.fieldKey,
    this.placeholder,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.autofillHints,
    super.key,
  });

  final TextEditingController controller;
  final StringValidationCallback validator;
  final String label;
  final bool showLabel;
  final Widget? prefixIcon;
  final Key? fieldKey;
  final String? placeholder;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          _AuthFieldLabel(text: label),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          decoration: _authInputDecoration(
            context,
            hintText: placeholder ?? label,
            prefixIcon: prefixIcon,
          ),
          validator: (value) => validator(value?.trim()),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class AuthEmailField extends StatelessWidget {
  const AuthEmailField({
    required this.controller,
    required this.validator,
    this.label,
    this.showLabel = true,
    this.prefixIcon,
    this.fieldKey,
    this.placeholder,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final StringValidationCallback validator;
  final String? label;
  final bool showLabel;
  final Widget? prefixIcon;
  final Key? fieldKey;
  final String? placeholder;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthTextField(
      controller: controller,
      validator: validator,
      label: label ?? l10n.emailLabel,
      showLabel: showLabel,
      prefixIcon: prefixIcon,
      fieldKey: fieldKey,
      placeholder: placeholder,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      onChanged: onChanged,
      autofillHints: const [AutofillHints.email],
    );
  }
}

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.controller,
    required this.validator,
    this.label,
    this.labelTrailing,
    this.showLabel = true,
    this.prefixIcon,
    this.fieldKey,
    this.placeholder,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.showVisibilityToggle = false,
    super.key,
  });

  final TextEditingController controller;
  final StringValidationCallback validator;
  final String? label;
  final Widget? labelTrailing;
  final bool showLabel;
  final Widget? prefixIcon;
  final Key? fieldKey;
  final String? placeholder;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final bool showVisibilityToggle;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  var _isObscured = true;

  void _toggleVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel || widget.labelTrailing != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showLabel)
                Expanded(
                  child: _AuthFieldLabel(
                    text: widget.label ?? l10n.passwordLabel,
                  ),
                )
              else
                const Spacer(),
              if (widget.labelTrailing != null) widget.labelTrailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          obscureText: _isObscured,
          textInputAction: widget.textInputAction,
          autofillHints: const [AutofillHints.password],
          decoration: _authInputDecoration(
            context,
            hintText:
                widget.placeholder ?? (widget.label ?? l10n.passwordLabel),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.showVisibilityToggle
                ? IconButton(
                    onPressed: _toggleVisibility,
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  )
                : null,
          ),
          validator: (value) => widget.validator(value?.trim()),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
    this.buttonKey,
    this.trailingIcon,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onPressed;
  final String label;
  final Key? buttonKey;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gradientEnd = Color.alphaBlend(
      colors.primaryContainer.withValues(alpha: 0.24),
      colors.primary,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, gradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppAuthUi.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: FilledButton(
        key: buttonKey,
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: colors.onPrimary,
          disabledForegroundColor: colors.onPrimary.withValues(alpha: 0.82),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppAuthUi.buttonRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: AppSizes.inlineProgressIndicator,
                height: AppSizes.inlineProgressIndicator,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.progressStrokeWidth,
                  color: colors.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    trailingIcon!,
                  ],
                ],
              ),
      ),
    );
  }
}

class _AuthFieldLabel extends StatelessWidget {
  const _AuthFieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      text.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
    );
  }
}

InputDecoration _authInputDecoration(
  BuildContext context, {
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final colors = Theme.of(context).colorScheme;
  final borderRadius = BorderRadius.circular(AppAuthUi.fieldRadius);
  final borderColor = colors.outlineVariant.withValues(alpha: 0.16);

  return InputDecoration(
    hintText: hintText,
    hintStyle: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: colors.outlineVariant),
    filled: true,
    fillColor: colors.surfaceContainerLow,
    prefixIcon: prefixIcon,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.lg,
    ),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: colors.primary.withValues(alpha: 0.34),
        width: 1.2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.error.withValues(alpha: 0.42)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.error.withValues(alpha: 0.72)),
    ),
  );
}
