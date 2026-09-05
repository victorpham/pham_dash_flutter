// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPreference _$UserPreferenceFromJson(Map<String, dynamic> json) =>
    _UserPreference(
      primaryColor: json['primaryColor'] as String?,
      themePreset: json['themePreset'] as String?,
      surfaceColor: json['surfaceColor'] as String?,
      darkMode: json['darkMode'] as bool?,
    );

Map<String, dynamic> _$UserPreferenceToJson(_UserPreference instance) =>
    <String, dynamic>{
      'primaryColor': instance.primaryColor,
      'themePreset': instance.themePreset,
      'surfaceColor': instance.surfaceColor,
      'darkMode': instance.darkMode,
    };
