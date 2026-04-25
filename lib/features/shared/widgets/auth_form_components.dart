import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
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
      // Validator throws ArgumentError for unsupported locale names.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      // Try the next locale candidate.
    }
  }
  // coverage:ignore-end

  return 'en';
}

/// Defines auth validation factory.
class AuthValidationFactory {
  const AuthValidationFactory._(this._localeName);

  /// Creates a [AuthValidationFactory] for from context.
  factory AuthValidationFactory.fromContext(BuildContext context) {
    return AuthValidationFactory._(_resolveValidationLocaleName(context));
  }

  final String _localeName;

  ValidationBuilder _builder() => ValidationBuilder(localeName: _localeName);

  /// Email.
  StringValidationCallback email() => _builder().email().build();

  /// Password.
  StringValidationCallback password({int minLength = 6}) {
    return _builder().minLength(minLength).build();
  }

  /// Confirm password.
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

/// Defines auth text field.
class AuthTextField extends StatelessWidget {
  /// The auth text field.
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

  /// The controller.
  final TextEditingController controller;

  /// The validator.
  final StringValidationCallback validator;

  /// The label.
  final String label;

  /// The show label.
  final bool showLabel;

  /// The prefix icon.
  final Widget? prefixIcon;

  /// The field key.
  final Key? fieldKey;

  /// The placeholder.
  final String? placeholder;

  /// The keyboard type.
  final TextInputType? keyboardType;

  /// The text input action.
  final TextInputAction textInputAction;

  /// The on changed.
  final ValueChanged<String>? onChanged;

  /// The autofill hints.
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

/// Defines auth email field.
class AuthEmailField extends StatelessWidget {
  /// The auth email field.
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

  /// The controller.
  final TextEditingController controller;

  /// The validator.
  final StringValidationCallback validator;

  /// The label.
  final String? label;

  /// The show label.
  final bool showLabel;

  /// The prefix icon.
  final Widget? prefixIcon;

  /// The field key.
  final Key? fieldKey;

  /// The placeholder.
  final String? placeholder;

  /// The text input action.
  final TextInputAction textInputAction;

  /// The on changed.
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

/// Defines auth password field.
class AuthPasswordField extends StatefulWidget {
  /// The auth password field.
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

  /// The controller.
  final TextEditingController controller;

  /// The validator.
  final StringValidationCallback validator;

  /// The label.
  final String? label;

  /// The label trailing.
  final Widget? labelTrailing;

  /// The show label.
  final bool showLabel;

  /// The prefix icon.
  final Widget? prefixIcon;

  /// The field key.
  final Key? fieldKey;

  /// The placeholder.
  final String? placeholder;

  /// The text input action.
  final TextInputAction textInputAction;

  /// The on changed.
  final ValueChanged<String>? onChanged;

  /// The show visibility toggle.
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

/// Defines auth submit button.
class AuthSubmitButton extends StatelessWidget {
  /// The auth submit button.
  const AuthSubmitButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
    this.buttonKey,
    this.trailingIcon,
    super.key,
  });

  /// Whether loading.
  final bool isLoading;

  /// The on pressed.
  final VoidCallback onPressed;

  /// The label.
  final String label;

  /// The button key.
  final Key? buttonKey;

  /// The trailing icon.
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
