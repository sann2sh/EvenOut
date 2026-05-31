import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://evenout-ilq1.onrender.com/api/v1',
      // The backend runs on Render's free tier, which spins down when idle and
      // takes ~30-50s to cold-start. Generous timeouts prevent the very first
      // request after login from failing with a DioException.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  )
    ..interceptors.add(_AuthInterceptor())
    ..interceptors.add(_RetryInterceptor());

  static Dio get instance => _dio;
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && session.accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    super.onRequest(options, handler);
  }
}

/// Retries idempotent requests that fail due to a cold-start timeout or a
/// transient connection error (common on the first request after the Render
/// backend wakes up). Retries up to [_maxRetries] times with a short backoff.
class _RetryInterceptor extends Interceptor {
  static const int _maxRetries = 2;

  bool _isTransient(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;

    if (_isTransient(err) && attempt < _maxRetries) {
      final nextAttempt = attempt + 1;
      await Future.delayed(Duration(seconds: nextAttempt * 2));

      final options = err.requestOptions;
      options.extra['retry_attempt'] = nextAttempt;

      try {
        final response = await ApiClient.instance.fetch(options);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    super.onError(err, handler);
  }
}
