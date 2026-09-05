import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/auth_service.dart';
import '../config/app_config.dart';
import 'api_exception.dart';

/// Marks a request that should go out without a bearer token.
const String noAuthKey = 'phamdash_no_auth';

/// Marks a request that has already been through the 401 refresh-and-retry, so
/// a second 401 ends in sign-out instead of looping.
const String _retriedKey = 'phamdash_retried';

/// The single HTTP entry point for the PhamDash API.
class ApiClient {
  ApiClient(this._auth, {Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 15)
      // Deliberately generous. Calendar reads are not always cheap: every
      // GET /calendar/events* checks the last sync time and, if it is older
      // than 15 minutes, performs a full Google Calendar sync inline before
      // responding - up to 250 events over a network round trip. The Kotlin
      // app's 30s is marginal for that first post-idle request.
      ..receiveTimeout = const Duration(seconds: 60)
      ..sendTimeout = const Duration(seconds: 60)
      ..headers['Accept'] = 'application/json'
      // Let any status reach the error mapper rather than having Dio throw
      // before we can read the body.
      ..validateStatus = (status) => status != null && status < 400;

    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;
  final AuthService _auth;

  /// Emitted when the session could not be recovered and the user was signed
  /// out. The router listens so it can send them back to /login.
  final _sessionExpired = StreamController<void>.broadcast();
  Stream<void> get sessionExpired => _sessionExpired.stream;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[noAuthKey] == true) return handler.next(options);

    final token = await _auth.idToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// The 401 contract, mirroring the web client's `httpClient.js`: force a
  /// token refresh and retry the request **exactly once**; if the retry also
  /// fails, sign out. This is what stops a token that expired mid-session from
  /// bouncing the user to the login screen for no reason.
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final response = error.response;
    final options = error.requestOptions;

    final isRetryable401 = response?.statusCode == 401 &&
        options.extra[noAuthKey] != true &&
        options.extra[_retriedKey] != true;

    if (isRetryable401) {
      final token = await _auth.idToken(forceRefresh: true);
      if (token != null) {
        options.extra[_retriedKey] = true;
        options.headers['Authorization'] = 'Bearer $token';
        try {
          final retried = await _dio.fetch<dynamic>(options);
          return handler.resolve(retried);
        } on DioException catch (retryError) {
          if (retryError.response?.statusCode != 401) {
            return handler.reject(_wrap(retryError));
          }
          // A second 401 means the refreshed token is not acceptable either;
          // fall through to sign-out.
        }
      }

      await _auth.signOut();
      _sessionExpired.add(null);
      return handler.reject(
        DioException(
          requestOptions: options,
          response: response,
          error: const SessionExpiredException(),
        ),
      );
    }

    handler.reject(_wrap(error));
  }

  DioException _wrap(DioException error) => DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: _toApiException(error),
      );

  static ApiException _toApiException(DioException error) {
    if (error.error is ApiException) return error.error as ApiException;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          'The server took too long to respond. If this was the first calendar '
          'load in a while it may still be syncing - try again.',
        );
      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException('The server certificate was rejected.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (error.response == null) {
          return const NetworkException(
            'Could not reach the PhamDash API. Check that it is running and '
            'that the app is pointed at the right address.',
          );
        }
      case DioExceptionType.badResponse:
        break;
    }

    final response = error.response;
    return ApiException(
      response?.statusCode,
      messageFromBody(
        response?.data,
        response?.statusCode,
        response?.statusMessage,
      ),
    );
  }

  /// Degrades through the three body shapes the API actually produces.
  static String messageFromBody(
    dynamic body,
    int? statusCode,
    String? statusMessage,
  ) {
    // 1. The middleware shape { "message": ..., "statusCode": ... }, and the
    //    controllers' Conflict(new { message = ... }).
    if (body is Map) {
      final message = body['message'] ?? body['title'] ?? body['detail'];
      if (message is String && message.isNotEmpty) return message;

      // ASP.NET validation-problem shape, produced by e.g. an invalid event
      // category colour: { "errors": { "Color": ["..."] } }.
      if (body['errors'] is Map) {
        for (final value in (body['errors'] as Map).values) {
          if (value is List) {
            for (final entry in value) {
              if (entry is String && entry.isNotEmpty) return entry;
            }
          }
        }
      }
    }

    // 2. A bare string body - PeopleController returns
    //    NotFound($"Person with ID {id} not found") with no JSON wrapper.
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isNotEmpty && trimmed.length <= 300) return trimmed;
    }

    // 3. Nothing usable left; fall back to the status.
    if (statusMessage != null && statusMessage.isNotEmpty) return statusMessage;
    return 'Request failed${statusCode != null ? ' ($statusCode)' : ''}.';
  }

  Future<T?> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<T>(path, queryParameters: query));

  Future<T?> post<T>(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send(() => _dio.post<T>(path, data: body, queryParameters: query));

  Future<T?> put<T>(String path, {Object? body}) =>
      _send(() => _dio.put<T>(path, data: body));

  Future<void> delete(String path) => _send(() => _dio.delete<dynamic>(path));

  /// Multipart upload. Both upload endpoints name the form field `file`.
  ///
  /// The content type is left unset on purpose so Dio writes the multipart
  /// boundary itself; setting it by hand produces a body the server cannot
  /// parse.
  Future<T?> upload<T>(
    String path, {
    required String filePath,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return _send(() => _dio.post<T>(path, data: form));
  }

  Future<T?> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      // Most deletes and some updates answer 204 with no body.
      if (response.statusCode == 204) return null;
      return response.data;
    } on DioException catch (error) {
      final wrapped = error.error;
      throw wrapped is ApiException ? wrapped : _toApiException(error);
    }
  }

  void dispose() {
    _sessionExpired.close();
    _dio.close();
  }
}
