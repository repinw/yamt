// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  uid: json['uid'] as String,
  householdId: json['householdId'] as String?,
  email: json['email'] as String?,
  displayName: json['displayName'] as String?,
  isAnonymous: json['isAnonymous'] as bool? ?? false,
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'householdId': instance.householdId,
      'email': instance.email,
      'displayName': instance.displayName,
      'isAnonymous': instance.isAnonymous,
    };
