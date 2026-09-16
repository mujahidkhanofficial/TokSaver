import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/app_error.dart';
import '../utils/app_logger.dart';

/// Configured Dio singleton/factory for network requests and download streams.
class DioClient {
  static Dio? _instance;

  /// Default headers to mimic a modern mobile browser.
  static const Map<String, String> defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// Returns configured Dio client.
  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.connectTimeout,
        headers: defaultHeaders,
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );

    // Logging & error interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.d('--> HTTP ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d('<-- HTTP ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          AppLogger.w('HTTP Error: [${error.type}] ${error.message} - ${error.requestOptions.uri}');
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Converts a DioException into the appropriate domain AppError.
  static AppError mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkError(
          message: 'Connection timed out or failed. Check your internet connection.',
          cause: e,
        );

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final msg = e.response?.statusMessage ?? 'Server returned error status $status';
        return HttpError(
          statusCode: status,
          message: msg,
          body: e.response?.data?.toString(),
        );

      case DioExceptionType.cancel:
        return const DownloadInterruptedError(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return NetworkError(
          message: 'SSL certificate error. Please check your network security.',
          cause: e,
        );

      case DioExceptionType.unknown:
      default:
        return UnknownError(
          message: e.message ?? 'An unexpected network error occurred.',
          cause: e,
        );
    }
  }
}
