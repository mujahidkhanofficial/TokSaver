/// Sealed class hierarchy for all app-level errors.
/// UI layers map these to user-facing strings; never expose raw exceptions.
sealed class AppError {
  const AppError({this.message});

  final String? message;

  /// Short user-facing message key (resolved via AppLocalizations or fallback).
  String get userMessage => message ?? 'An error occurred';

  @override
  String toString() => message ?? userMessage;
}

/// Network-level failure (no connection, timeout, DNS, etc.)
class NetworkError extends AppError {
  const NetworkError({super.message, this.cause});
  final Object? cause;

  @override
  String get userMessage => message ?? 'Network connection failed';
}

/// HTTP error returned by the extraction API or CDN.
class HttpError extends AppError {
  const HttpError({required this.statusCode, super.message, this.body});
  final int statusCode;
  final String? body;

  @override
  String get userMessage => message ?? (statusCode == 404
      ? 'Video not found'
      : 'Server error ($statusCode)');
}

/// URL is syntactically invalid or not a TikTok link.
class InvalidUrlError extends AppError {
  const InvalidUrlError({super.message});

  @override
  String get userMessage => message ?? 'Invalid TikTok link';
}

/// URL is valid TikTok but the video is private/unavailable.
class VideoUnavailableError extends AppError {
  const VideoUnavailableError({super.message});

  @override
  String get userMessage => message ?? 'Video unavailable';
}

/// Extraction/parsing failed (malformed API response, changed schema).
class ParseError extends AppError {
  const ParseError({super.message});

  @override
  String get userMessage => message ?? 'Unable to analyze video';
}

/// Insufficient device storage.
class StorageError extends AppError {
  const StorageError({this.requiredBytes, super.message});
  final int? requiredBytes;

  @override
  String get userMessage => message ?? 'Not enough storage';
}

/// Permission denied by user or system.
class PermissionError extends AppError {
  const PermissionError({super.message});

  @override
  String get userMessage => message ?? 'Storage permission required';
}

/// Download was interrupted (network drop, system killed service, paused, etc.)
class DownloadInterruptedError extends AppError {
  const DownloadInterruptedError({super.message});

  @override
  String get userMessage => message ?? 'Download interrupted';
}

/// Generic / unexpected error — wraps unknown exceptions.
class UnknownError extends AppError {
  const UnknownError({super.message, this.cause});
  final Object? cause;

  @override
  String get userMessage => message ?? 'Something went wrong';
}
