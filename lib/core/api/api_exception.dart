/// Errors thrown by the repository layer.
///
/// The API's error bodies are not uniformly shaped. `ExceptionHandlingMiddleware`
/// emits `{ "message": ..., "statusCode": ... }`, but controllers also return
/// status codes directly with bodies that are variously empty, a bare string
/// (`NotFound($"Person with ID {id} not found")`), or `{ "message": ... }` with
/// no `statusCode`. Model-validation failures return ASP.NET's
/// validation-problem shape instead.
///
/// [ApiException.fromBody] therefore degrades in three steps: parsed
/// `{message}` → the raw body as a message → the status code alone. The Vue
/// client calls `response.json()` and loses bare-string bodies entirely.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  /// 409 — a duplicate spelling word, event-category or spelling-list name, or
  /// a person already attending an event. Callers usually want to show this
  /// inline on a form rather than as a generic failure.
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Raised when the session cannot be recovered — the 401 retry already ran and
/// failed, so the user has been signed out.
class SessionExpiredException extends ApiException {
  const SessionExpiredException()
      : super(401, 'Session expired. Please sign in again.');
}

/// The network never reached the API (no connectivity, DNS failure, timeout).
class NetworkException extends ApiException {
  const NetworkException(String message) : super(null, message);
}
