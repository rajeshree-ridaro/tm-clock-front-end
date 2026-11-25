import 'package:dio/dio.dart';

import 'package:tm_clock/core/config/env.dart';
import 'package:tm_clock/data/api/token_store.dart';

/// API error in the shape of the spec's `Error` schema (`code`, `message`, `details`).
class ApiException implements Exception {
  ApiException({required this.status, required this.code, required this.message, this.details});

  final int? status;

  /// Machine code from the API, e.g. `OUTSIDE_SITE`, `CLOCKED_IN_ELSEWHERE`.
  final String code;

  /// Already in the caller's language (the client sends `Accept-Language`).
  final String message;
  final Map<String, dynamic>? details;

  /// The user-facing text, so screens can show `'$e'` directly.
  @override
  String toString() => message;
}

/// One Dio instance for both apps: base URL, bearer token, language header,
/// refresh-on-401 and error mapping. Repositories call this, screens never do.
class ApiClient {
  ApiClient({required this.tokens, required String Function() language, String? baseUrl})
      : _language = language,
        dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens.accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        options.headers['Accept-Language'] = language();
        handler.next(options);
      },
      onError: (error, handler) async {
        final retried = error.requestOptions.extra['retried'] == true;
        if (error.response?.statusCode == 401 && !retried && await _refresh()) {
          final opts = error.requestOptions..extra['retried'] = true;
          opts.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          try {
            return handler.resolve(await dio.fetch(opts));
          } on DioException catch (e) {
            return handler.next(e);
          }
        }
        handler.next(error);
      },
    ));
  }

  final Dio dio;
  final TokenStore tokens;
  final String Function() _language;

  Future<bool> _refresh() async {
    final refresh = tokens.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: dio.options.baseUrl))
          .post<Map<String, dynamic>>('/auth/refresh', data: {'refreshToken': refresh});
      final data = res.data!;
      tokens.save(access: data['accessToken'] as String, refresh: data['refreshToken'] as String);
      return true;
    } on DioException {
      tokens.clear();
      return false;
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _wrap(() => dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? body}) => _wrap(() => dio.post<T>(path, data: body));

  Future<T> patch<T>(String path, {Object? body}) => _wrap(() => dio.patch<T>(path, data: body));

  Future<T> delete<T>(String path) => _wrap(() => dio.delete<T>(path));

  Future<T> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data as T;
    } on DioException catch (e) {
      final body = e.response?.data;
      final status = e.response?.statusCode;
      if (body is Map<String, dynamic> && body['code'] is String) {
        throw ApiException(
          status: status,
          code: body['code'] as String,
          message: (body['message'] as String?) ?? _fallbackMessage(status),
          details: body['details'] as Map<String, dynamic>?,
        );
      }
      // No `{ code, message }` body (proxy error, mock validation, no connection):
      // still give the user one short sentence in their language, never Dio's text.
      final offline = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      throw ApiException(
        status: status,
        code: offline ? 'NETWORK' : 'HTTP_${status ?? 0}',
        message: offline ? _text(_offline) : _fallbackMessage(status),
        details: body is Map<String, dynamic> ? body : null,
      );
    }
  }

  String _fallbackMessage(int? status) => _text(switch (status) {
        400 || 422 => _invalid,
        401 => _signedOut,
        403 => _forbidden,
        404 => _notFound,
        _ => _generic,
      });

  String _text(Map<String, String> m) => m[_language()] ?? m['en']!;

  static const _offline = {
    'en': "Can't reach TM Clock. Check your connection and try again.",
    'es': 'No se puede conectar con TM Clock. Revisa tu conexión e intenta de nuevo.',
  };
  static const _invalid = {
    'en': 'Some details are missing or not valid. Check them and try again.',
    'es': 'Faltan datos o no son válidos. Revísalos e intenta de nuevo.',
  };
  static const _signedOut = {
    'en': 'Your session ended. Please sign in again.',
    'es': 'Tu sesión terminó. Vuelve a iniciar sesión.',
  };
  static const _forbidden = {
    'en': "You don't have access to this.",
    'es': 'No tienes acceso a esto.',
  };
  static const _notFound = {
    'en': "We couldn't find that.",
    'es': 'No encontramos eso.',
  };
  static const _generic = {
    'en': 'Something went wrong. Please try again.',
    'es': 'Algo salió mal. Intenta de nuevo.',
  };
}
