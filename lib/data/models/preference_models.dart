import 'package:freezed_annotation/freezed_annotation.dart';

part 'preference_models.freezed.dart';
part 'preference_models.g.dart';

/// `GET /api/user-preferences`.
///
/// Every field is nullable and the endpoint returns an **all-null object rather
/// than a 404** when nothing has been saved.
///
/// `PUT` is a full upsert-replace: every field omitted from the body is written
/// as null. The MVP therefore never writes preferences - a careless save from
/// the phone would wipe the web app's saved theme. Read, merge, then write is
/// mandatory if that ever changes.
@freezed
abstract class UserPreference with _$UserPreference {
  const factory UserPreference({
    /// Hex, e.g. `#10b981`. Used as the Material colour-scheme seed.
    String? primaryColor,

    /// PrimeVue-specific; no Material equivalent, ignored on mobile.
    String? themePreset,

    /// PrimeVue-specific; ignored on mobile.
    String? surfaceColor,
    bool? darkMode,
  }) = _UserPreference;

  factory UserPreference.fromJson(Map<String, dynamic> json) =>
      _$UserPreferenceFromJson(json);
}
