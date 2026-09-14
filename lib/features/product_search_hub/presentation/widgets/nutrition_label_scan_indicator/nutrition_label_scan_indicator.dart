import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shows a captured nutrition label with an animated scanning line.
class NutritionLabelScanIndicator extends StatefulWidget {
  /// Creates a nutrition-label scan indicator.
  const NutritionLabelScanIndicator({
    required this.imageBytes,
    required this.statusLabel,
    required this.semanticLabel,
    super.key,
  });

  /// Captured label image bytes.
  final Uint8List imageBytes;

  /// Visible scan status.
  final String statusLabel;

  /// Accessible description of the active scan.
  final String semanticLabel;

  @override
  State<NutritionLabelScanIndicator> createState() {
    return _NutritionLabelScanIndicatorState();
  }
}

class _NutritionLabelScanIndicatorState
    extends State<NutritionLabelScanIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: AppDurations.scanSweep,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_animationsDisabled == animationsDisabled) {
      return;
    }
    _animationsDisabled = animationsDisabled;
    if (animationsDisabled) {
      _scanController
        ..stop()
        ..value = 0.5;
      return;
    }
    unawaited(_scanController.repeat(reverse: true));
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScanImage(
                imageBytes: widget.imageBytes,
                scanController: _scanController,
              ),
              const SizedBox(height: AppSpacing.md),
              _ScanStatus(label: widget.statusLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanImage extends StatelessWidget {
  const _ScanImage({
    required this.imageBytes,
    required this.scanController,
  });

  final Uint8List imageBytes;
  final Animation<double> scanController;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: AppSizes.scanPreviewHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colors.surfaceContainerHighest),
            Image.memory(
              imageBytes,
              key: const Key('nutrition_label_scan_image'),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: _buildImageError,
            ),
            const _ScanVignette(),
            _ScanLine(animation: scanController),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ScanVignette extends StatelessWidget {
  const _ScanVignette();

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).colorScheme.scrim;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              shadowColor.withValues(alpha: 0.18),
              Colors.transparent,
              shadowColor.withValues(alpha: 0.18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  const _ScanLine({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Align(
            alignment: Alignment(0, (animation.value * 2) - 1),
            child: child,
          );
        },
        child: Container(
          key: const Key('nutrition_label_scan_line'),
          height: AppSizes.scanLineHeight,
          decoration: BoxDecoration(
            color: primary,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.75),
                blurRadius: AppSpacing.sm,
                spreadRadius: AppSpacing.xxs,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanStatus extends StatelessWidget {
  const _ScanStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.document_scanner_outlined,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

const _previewImageBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
    '+A8AAQUBAScY42YAAAAASUVORK5CYII=';

/// Previews the animated nutrition-label scanner.
@Preview(
  name: 'Nutrition label scan',
  group: 'Product search',
  size: Size(380, 340),
)
Widget nutritionLabelScanIndicatorPreview() {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    ),
    home: Scaffold(
      body: Padding(
        padding: AppInsets.page,
        child: NutritionLabelScanIndicator(
          imageBytes: base64Decode(_previewImageBase64),
          statusLabel: 'Reading nutrition label…',
          semanticLabel: 'Captured nutrition label is being scanned',
        ),
      ),
    ),
  );
}
