// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIngredientAmountConversion _$RecipeIngredientAmountConversionFromJson(
  Map<String, dynamic> json,
) => RecipeIngredientAmountConversion(
  amountPerPiece: _readIntOrZero(json['amount_per_piece']),
  unit: _readAmountUnitOrPiece(json['unit']),
);

Map<String, dynamic> _$RecipeIngredientAmountConversionToJson(
  RecipeIngredientAmountConversion instance,
) => <String, dynamic>{
  'amount_per_piece': instance.amountPerPiece,
  'unit': _writeAmountUnit(instance.unit),
};

PreparedMeal _$PreparedMealFromJson(Map<String, dynamic> json) => PreparedMeal(
  id: _readRequiredString(json['id']),
  name: _readRequiredString(json['name']),
  totalPortions: _readIntOrZero(json['total_portions']),
  remainingPortions: _readDoubleOrZero(json['remaining_portions']),
  totalKcal: _readDoubleOrZero(json['total_kcal']),
  totalProtein: _readDoubleOrZero(json['total_protein']),
  totalCarbs: _readDoubleOrZero(json['total_carbs']),
  totalFat: _readDoubleOrZero(json['total_fat']),
  createdAt: _readDateTimeOrNow(json['created_at']),
  updatedAt: _readDateTimeOrNow(json['updated_at']),
  components:
      (json['components'] as List<dynamic>?)
          ?.map(
            (e) => PreparedMealComponent.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
  imageAssetId: _readTrimmedNullableString(json['image_asset_id']),
  imageUrl: _readTrimmedNullableString(json['image_url']),
  recipeUrl: _readTrimmedNullableString(json['recipe_url']),
  recipeIngredients:
      (json['recipe_ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  recipeInstructions:
      (json['recipe_instructions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  ignoredRecipeIngredients:
      (json['ignored_recipe_ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  recipeIngredientAssignments:
      (json['recipe_ingredient_assignments'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ) ??
      {},
  recipeIngredientAmountConversions:
      (json['recipe_ingredient_amount_conversions'] as Map<String, dynamic>?)
          ?.map(
            (k, e) => MapEntry(
              k,
              RecipeIngredientAmountConversion.fromJson(
                e as Map<String, dynamic>,
              ),
            ),
          ) ??
      {},
  pendingRecipeIngredients:
      (json['pending_recipe_ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  finalNetWeight: _readNullableInt(json['final_net_weight']),
  remainingNetWeight: _readNullableInt(json['remaining_net_weight']),
);

Map<String, dynamic> _$PreparedMealToJson(PreparedMeal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_asset_id': instance.imageAssetId,
      'image_url': instance.imageUrl,
      'recipe_url': instance.recipeUrl,
      'recipe_ingredients': instance.recipeIngredients,
      'recipe_instructions': instance.recipeInstructions,
      'ignored_recipe_ingredients': instance.ignoredRecipeIngredients,
      'recipe_ingredient_assignments': instance.recipeIngredientAssignments,
      'recipe_ingredient_amount_conversions': instance
          .recipeIngredientAmountConversions
          .map((k, e) => MapEntry(k, e.toJson())),
      'pending_recipe_ingredients': instance.pendingRecipeIngredients,
      'final_net_weight': instance.finalNetWeight,
      'remaining_net_weight': instance.remainingNetWeight,
      'total_portions': instance.totalPortions,
      'remaining_portions': instance.remainingPortions,
      'total_kcal': instance.totalKcal,
      'total_protein': instance.totalProtein,
      'total_carbs': instance.totalCarbs,
      'total_fat': instance.totalFat,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'components': instance.components.map((e) => e.toJson()).toList(),
    };

PreparedMealComponent _$PreparedMealComponentFromJson(
  Map<String, dynamic> json,
) => PreparedMealComponent(
  inventoryItemId: _readRequiredString(json['inventory_item_id']),
  name: _readRequiredString(json['name']),
  brand: _readTrimmedNullableString(json['brand']),
  imageUrl: _readTrimmedNullableString(json['image_url']),
  usedAmount: _readIntOrZero(json['used_amount']),
  usedUnit: _readAmountUnitOrPiece(json['used_unit']),
  totalKcal: _readDoubleOrZero(json['total_kcal']),
  totalProtein: _readDoubleOrZero(json['total_protein']),
  totalCarbs: _readDoubleOrZero(json['total_carbs']),
  totalFat: _readDoubleOrZero(json['total_fat']),
  sourceItemSnapshot: InventoryItem.fromJson(
    json['source_item_snapshot'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$PreparedMealComponentToJson(
  PreparedMealComponent instance,
) => <String, dynamic>{
  'inventory_item_id': instance.inventoryItemId,
  'name': instance.name,
  'brand': instance.brand,
  'image_url': instance.imageUrl,
  'used_amount': instance.usedAmount,
  'used_unit': _writeAmountUnit(instance.usedUnit),
  'total_kcal': instance.totalKcal,
  'total_protein': instance.totalProtein,
  'total_carbs': instance.totalCarbs,
  'total_fat': instance.totalFat,
  'source_item_snapshot': instance.sourceItemSnapshot.toJson(),
};
