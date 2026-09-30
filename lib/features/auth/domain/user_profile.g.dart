// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  uid: json['uid'] as String,
  isAnonymous: json['isAnonymous'] as bool,
  householdId: json['householdId'] as String?,
  ownHouseholdId: json['ownHouseholdId'] as String?,
  email: json['email'] as String?,
  displayName: json['displayName'] as String?,
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'isAnonymous': instance.isAnonymous,
      'householdId': instance.householdId,
      'ownHouseholdId': instance.ownHouseholdId,
      'email': instance.email,
      'displayName': instance.displayName,
    };
