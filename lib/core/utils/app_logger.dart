import 'package:logger/logger.dart';

/// Structured logger — debug builds only.
/// Production builds compile out all log calls (level = off).
abstract final class AppLogger {
  static final Logger _logger = Logger(
    level: const bool.fromEnvironment('dart.vm.product') ? Level.off : Level.debug,
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
    ),
    output: ConsoleOutput(),
  );

  static void d(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  static void i(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  static void w(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  static void e(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
