import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

/// Normalize household scope value.
String? normalizeHouseholdScopeValue(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

/// Signed in household recovery user id.
String? signedInHouseholdRecoveryUserId(Ref ref) {
  return normalizeHouseholdScopeValue(
    ref.read(authStateChangesProvider).asData?.value?.uid,
  );
}
