import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_content.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Editor for a new calorie entry. Returns the entry by popping its route;
/// the caller saves it.
class CalorieEntryEditorPage extends ConsumerStatefulWidget {
  /// The calorie entry editor page.
  const new({
    super.key,
    this.prefilledProfile,
    this.prefilledAmount,
    this.prefilledUnit,
    this.preselectedMealType,
    this.preselectedLoggedAt,
  });

  /// The prefilled profile.
  final CalorieProductProfile? prefilledProfile;

  /// The prefilled consumed amount.
  final double? prefilledAmount;

  /// The unit of [prefilledAmount].
  final ConsumedUnit? prefilledUnit;

  /// The preselected meal type.
  final MealType? preselectedMealType;

  /// The preselected logged at.
  final DateTime? preselectedLoggedAt;

  @override
  ConsumerState<CalorieEntryEditorPage> createState() {
    return _CalorieEntryEditorPageState();
  }
}

class _CalorieEntryEditorPageState
    extends ConsumerState<CalorieEntryEditorPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateChangesProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          ),
        ),
      );
    }

    final user = authState.asData?.value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.homeCalories)),
        body: Center(child: Text(l10n.caloriesAuthRequired)),
      );
    }

    return CalorieEntryEditorContent(
      user: user,
      prefilledProfile: widget.prefilledProfile,
      prefilledAmount: widget.prefilledAmount,
      prefilledUnit: widget.prefilledUnit,
      preselectedMealType: widget.preselectedMealType,
      preselectedLoggedAt: widget.preselectedLoggedAt,
    );
  }
}
