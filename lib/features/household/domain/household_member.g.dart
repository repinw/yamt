// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseholdMember _$HouseholdMemberFromJson(Map<String, dynamic> json) =>
    _HouseholdMember(
      uid: json['uid'] as String,
      role: $enumDecode(_$HouseholdRoleEnumMap, json['role']),
      joinedAt: const DateTimeJsonConverter().fromJson(
        json['joined_at'] as DateTime,
      ),
    );

Map<String, dynamic> _$HouseholdMemberToJson(_HouseholdMember instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'role': _$HouseholdRoleEnumMap[instance.role]!,
      'joined_at': const DateTimeJsonConverter().toJson(instance.joinedAt),
    };

const _$HouseholdRoleEnumMap = {
  HouseholdRole.admin: 'admin',
  HouseholdRole.member: 'member',
};
