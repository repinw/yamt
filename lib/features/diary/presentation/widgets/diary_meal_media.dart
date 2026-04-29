part of 'diary_meals_section.dart';

class _CollapsedMealThumb extends ConsumerWidget {
  const _CollapsedMealThumb({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: 22,
        child: storedImageBytes != null
            ? Image.memory(storedImageBytes, fit: BoxFit.cover)
            : entry.imageUrl == null
            ? _MealThumbFallback(label: entry.name, compact: true)
            : AppCachedNetworkImage(
                imageUrl: entry.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _MealThumbFallback(label: entry.name, compact: true),
              ),
      ),
    );
  }
}

class _MealThumb extends ConsumerWidget {
  const _MealThumb({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox.square(
        dimension: 48,
        child: storedImageBytes != null
            ? Image.memory(storedImageBytes, fit: BoxFit.cover)
            : entry.imageUrl == null
            ? _MealThumbFallback(label: entry.name)
            : AppCachedNetworkImage(
                imageUrl: entry.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _MealThumbFallback(
                  label: entry.name,
                ),
              ),
      ),
    );
  }
}

class _MealThumbFallback extends StatelessWidget {
  const _MealThumbFallback({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style:
              (compact
                      ? Theme.of(context).textTheme.labelSmall
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
        ),
      ),
    );
  }
}
