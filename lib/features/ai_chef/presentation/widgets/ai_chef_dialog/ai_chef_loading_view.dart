import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Premium animated loading view for AI recipe generator.
class AiChefLoadingView extends StatefulWidget {
  /// Creates a loading view.
  const AiChefLoadingView({super.key});

  @override
  State<AiChefLoadingView> createState() => _AiChefLoadingViewState();
}

class _AiChefLoadingViewState extends State<AiChefLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Timer _quoteTimer;
  int _quoteIndex = 0;
  bool _quoteVisible = true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    unawaited(_rotationController.repeat());

    _quoteTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_quoteVisible) {
          _quoteVisible = false;
        } else {
          _quoteIndex = (_quoteIndex + 1) % _quotes.length;
          _quoteVisible = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _quoteTimer.cancel();
    super.dispose();
  }

  List<String> get _quotes {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.aiChefQuoteLoveGarlic,
      l10n.aiChefQuoteCookingMagic,
      l10n.aiChefQuoteGoodFood,
      l10n.aiChefQuoteKitchenTalks,
      l10n.aiChefQuoteVirtualOven,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          _AnimatedStarsIcon(
            rotationController: _rotationController,
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            l10n.aiChefGeneratingTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.aiChefGeneratingSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedOpacity(
            opacity: _quoteVisible ? 0.85 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              height: 48,
              child: Text(
                _quotes[_quoteIndex],
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _AnimatedStarsIcon extends StatelessWidget {
  const _AnimatedStarsIcon({
    required this.rotationController,
    required this.colors,
  });

  final AnimationController rotationController;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.15),
                blurRadius: 36,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        RotationTransition(
          turns: rotationController,
          child: ShaderMask(
            shaderCallback: (bounds) =>
                AppEditorialSurfaces.soulGradient(colors).createShader(bounds),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
