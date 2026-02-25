import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CalorieBarcodeCandidatePickerSheet extends StatelessWidget {
  const CalorieBarcodeCandidatePickerSheet({
    super.key,
    required this.candidates,
    required this.onSelect,
  });

  final List<CalorieProductCandidate> candidates;
  final ValueChanged<CalorieProductCandidate> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        key: CalorieBarcodeScanKeys.candidateSheet,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(l10n.caloriesBarcodeCandidateTitle),
            subtitle: Text(l10n.caloriesBarcodeCandidateSubtitle),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: candidates.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                final profile = candidate.profile;
                return ListTile(
                  title: Text(profile.name),
                  subtitle: Text(
                    profile.brand?.isNotEmpty == true
                        ? profile.brand!
                        : l10n.caloriesBarcodeUnknownBrand,
                  ),
                  trailing: Text(
                    '${profile.per100Kcal.toStringAsFixed(0)} kcal',
                  ),
                  onTap: () => onSelect(candidate),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
