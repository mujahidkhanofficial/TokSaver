import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/app_error.dart';
import '../storage/download_storage_service.dart';
import '../storage/file_manager.dart';
import '../utils/app_logger.dart';
import 'dio_client.dart';

/// Progress callback receiving updated progress data for an active download.
typedef OnDownloadProgress = void Function({
  required int downloadedBytes,
  required int totalBytes,
  required int speedBytesPerSec,
  Duration? eta,
});

/// Handles streaming execution for a single download task with HTTP range support
/// and enterprise MediaStore / Scoped Storage atomic finalization.
class DownloadEngine {
  DownloadEngine({
    required this.taskId,
    required this.downloadUrl,
    required this.fileName,
    required this.mimeType,
    this.isAudioOnly = false,
    Dio? dio,
    DownloadStorageService? storageService,
  })  : _dio = dio ?? DioClient.instance,
        _storageService = storageService ??
            (Platform.isAndroid
                ? AndroidMediaStoreStorageService()
                : DefaultFileSystemStorageService());

  final String taskId;
  final String downloadUrl;
  final String fileName;
  final String mimeType;
  final bool isAudioOnly;
  final Dio _dio;
  final DownloadStorageService _storageService;

  CancelToken? _cancelToken;
  bool _isPaused = false;
  bool _isCancelled = false;

  bool get isPaused => _isPaused;
  bool get isCancelled => _isCancelled;

  /// Starts or resumes downloading and atomically commits to MediaStore on completion.
  Future<StorageFinalizeResult> execute({
    required OnDownloadProgress onProgress,
  }) async {
    _cancelToken = CancelToken();
    _isPaused = false;
    _isCancelled = false;

    final tempFilePath = await FileManager.getTempFilePath(taskId);
    final tempFile = File(tempFilePath);

    int existingBytes = 0;
    if (await tempFile.exists()) {
      existingBytes = await tempFile.length();
    }

    AppLogger.i('DOWNLOAD_START: task $taskId, existing bytes: $existingBytes, url: $downloadUrl');

    IOSink? sink;
    Response<ResponseBody>? response;

    try {
      final headers = Map<String, dynamic>.from(DioClient.defaultHeaders);
      if (existingBytes > 0) {
        headers['Range'] = 'bytes=$existingBytes-';
      }

      response = await _dio.get<ResponseBody>(
        downloadUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          receiveTimeout: AppConstants.receiveTimeout,
        ),
        cancelToken: _cancelToken,
      );

      final statusCode = response.statusCode ?? 200;
      final isPartial = statusCode == 206;

      // Determine total content length
      int totalBytes = -1;
      final contentLengthHeader = response.headers.value(Headers.contentLengthHeader);
      if (contentLengthHeader != null) {
        final len = int.tryParse(contentLengthHeader) ?? -1;
        if (len > 0) {
          totalBytes = isPartial ? (len + existingBytes) : len;
        }
      }

      // If server does not support partial content and returned 200, restart from 0
      final fileMode = (isPartial && existingBytes > 0) ? FileMode.append : FileMode.write;
      var downloadedBytes = (isPartial && existingBytes > 0) ? existingBytes : 0;

      sink = tempFile.openWrite(mode: fileMode);

      final stream = response.data?.stream;
      if (stream == null) {
        throw const HttpError(statusCode: 500, message: 'Empty response body stream.');
      }

      AppLogger.i('WRITE_STARTED: task $taskId to temp $tempFilePath');

      // Speed calculation variables
      var lastSampleTime = DateTime.now();
      var bytesSinceLastSample = 0;
      var currentSpeed = 0;
      var lastUiUpdateTime = DateTime.now();

      await for (final chunk in stream) {
        if (_isPaused || _isCancelled) {
          break;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;
        bytesSinceLastSample += chunk.length;

        final now = DateTime.now();
        final elapsedSampleMs = now.difference(lastSampleTime).inMilliseconds;

        // Calculate speed every 500ms
        if (elapsedSampleMs >= 500) {
          currentSpeed = ((bytesSinceLastSample / elapsedSampleMs) * 1000).round();
          lastSampleTime = now;
          bytesSinceLastSample = 0;
        }

        // Throttle UI callbacks to ~250ms
        final elapsedUiMs = now.difference(lastUiUpdateTime).inMilliseconds;
        if (elapsedUiMs >= 250 || (totalBytes > 0 && downloadedBytes >= totalBytes)) {
          lastUiUpdateTime = now;

          Duration? eta;
          if (totalBytes > 0 && currentSpeed > 0) {
            final remainingBytes = totalBytes - downloadedBytes;
            if (remainingBytes > 0) {
              eta = Duration(seconds: remainingBytes ~/ currentSpeed);
            }
          }

          onProgress(
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes > 0 ? totalBytes : downloadedBytes,
            speedBytesPerSec: currentSpeed,
            eta: eta,
          );
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (_isPaused) {
        throw const DownloadInterruptedError(message: 'Download was paused.');
      }
      if (_isCancelled) {
        await FileManager.deleteFileIfExists(tempFilePath);
        throw const DownloadInterruptedError(message: 'Download was cancelled.');
      }

      AppLogger.i('WRITE_COMPLETED: task $taskId ($downloadedBytes bytes). Starting finalization.');

      // Finalize: commit to MediaStore / Scoped Storage
      final finalizeResult = await _storageService.finalizeDownload(
        tempFilePath: tempFilePath,
        fileName: fileName,
        mimeType: mimeType,
        isAudioOnly: isAudioOnly,
        relativeSubDir: 'TokSaver',
      );

      AppLogger.i('DOWNLOAD_COMPLETED: task $taskId -> ${finalizeResult.storageUri}');
      return finalizeResult;
    } on DioException catch (e) {
      await sink?.close();
      if (CancelToken.isCancel(e) || _isPaused || _isCancelled) {
        if (_isCancelled) {
          await FileManager.deleteFileIfExists(tempFilePath);
        }
        throw const DownloadInterruptedError(message: 'Download stopped.');
      }
      throw DioClient.mapDioException(e);
    } catch (e, stack) {
      await sink?.close();
      if (_isCancelled) {
        await FileManager.deleteFileIfExists(tempFilePath);
      }
      if (e is AppError) rethrow;
      AppLogger.e('DOWNLOAD_FAILED: task $taskId error', e, stack);
      throw UnknownError(message: 'Download failed: $e', cause: e);
    }
  }

  /// Pauses download stream cleanly, retaining downloaded bytes in .part file.
  void pause() {
    _isPaused = true;
    _cancelToken?.cancel('PAUSED');
  }

  /// Cancels download and cleans up temp files.
  void cancel() {
    _isCancelled = true;
    _cancelToken?.cancel('CANCELLED');
  }
}
