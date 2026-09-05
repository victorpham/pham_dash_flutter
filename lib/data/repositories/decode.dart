/// Decoding helpers shared by the repositories.
///
/// The API answers `204 No Content` on most deletes and some updates, and
/// `ApiClient` turns that into a null payload, so every decoder here has to
/// tolerate null rather than assume a body.
library;

/// Decodes a JSON array into a list of models, skipping anything that is not an
/// object. Returns an empty list for a null or non-list payload.
List<T> decodeList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((entry) => fromJson(Map<String, dynamic>.from(entry)))
      .toList(growable: false);
}

/// Decodes a single JSON object, or null when the payload is absent or is not
/// an object.
T? decodeOrNull<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  if (data is! Map) return null;
  return fromJson(Map<String, dynamic>.from(data));
}

/// Decodes a single JSON object that the endpoint contractually always returns.
T decodeRequired<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
  String what,
) {
  final decoded = decodeOrNull(data, fromJson);
  if (decoded == null) {
    throw StateError('Expected $what in the response body, got: $data');
  }
  return decoded;
}
