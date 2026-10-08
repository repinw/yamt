// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeIngredientAmountConversion _$RecipeIngredientAmountConversionFromJson(
  Map<String, dynamic> json,
) => RecipeIngredientAmountConversion(
  amountPerPiece: readPreparedMealInt(json['amount_per_piece']),
  unit: readPreparedMealAmountUnit(json['unit']),
);

Map<String, dynamic> _$RecipeIngredientAmountConversionToJson(
  RecipeIngredientAmountConversion instance,
) => <String, dynamic>{
  'amount_per_piece': instance.amountPerPiece,
  'unit': writePreparedMealAmountUnit(instance.unit),
};

PreparedMeal _$PreparedMealFromJson(Map<String, dynamic> json) => PreparedMeal(
  id: readPreparedMealString(json['id']),
  name: readPreparedMealString(json['name']),
  totalPortions: readPreparedMealInt(json['total_portions']),
  remainingPortions: readPreparedMealDouble(json['remaining_portions']),
  totalKcal: readPreparedMealDouble(json['total_kcal']),
  totalProtein: readPreparedMealDouble(json['total_protein']),
  totalCarbs: readPreparedMealDouble(json['total_carbs']),
  totalFat: readPreparedMealDouble(json['total_fat']),
  createdAt: _readDateTimeOrNow(json['created_at']),
  updatedAt: _readDateTimeOrNow(json['updated_at']),
  components:
      (json['components'] as List<dynamic>?)
          ?.map(
            (e) => PreparedMealComponent.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
  imageAssetId: readPreparedMealOptionalString(json['image_asset_id']),
  imageUrl: readPreparedMealOptionalString(json['image_url']),
  recipeUrl: readPreparedMealOptionalString(json['recipe_url']),
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
  finalNetWeight: readPreparedMealOptionalInt(json['final_net_weight']),
  inPot: json['in_pot'] as bool?,
  potTareWeight: (json['pot_tare_weight'] as num?)?.toInt(),
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
      'in_pot': ?instance.inPot,
      'pot_tare_weight': ?instance.potTareWeight,
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
