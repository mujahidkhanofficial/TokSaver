import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../errors/app_error.dart';
import '../utils/app_logger.dart';
import 'file_manager.dart';

/// Result returned after a completed download is finalized in persistent storage.
class StorageFinalizeResult {
  const StorageFinalizeResult({
    required this.storageType,
    required this.storageUri,
    this.filePath,
    required this.displayName,
    required this.mimeType,
    this.relativePath,
    required this.sizeBytes,
  });

  /// Storage category: 'media_store' for Android 10-16, 'legacy_file' for Android 8-9, 'file_system' for desktop/iOS.
  final String storageType;

  /// Canonical location identifier: 'content://...' for MediaStore or absolute file path.
  final String storageUri;

  /// Absolute filesystem path if directly accessible; null for pure MediaStore content URIs.
  final String? filePath;

  /// User-visible display name (e.g. 'Dance_Video.mp4').
  final String displayName;

  /// MIME type (e.g. 'video/mp4', 'audio/mpeg').
  final String mimeType;

  /// Relative directory within storage (e.g. 'Movies/TokSaver' or 'Music/TokSaver').
  final String? relativePath;

  /// Final verified file size in bytes.
  final int sizeBytes;

  @override
  String toString() =>
      'StorageFinalizeResult(storageType: $storageType, uri: $storageUri, displayName: $displayName, size: $sizeBytes)';
}

/// Abstract contract for platform-independent, scoped-storage-compliant media saving.
abstract class DownloadStorageService {
  /// Atomically commits a completed temporary download file into user-visible persistent storage.
  Future<StorageFinalizeResult> finalizeDownload({
    required String tempFilePath,
    required String fileName,
    required String mimeType,
    required bool isAudioOnly,
    String relativeSubDir = 'TokSaver',
  });

  /// Safely deletes a stored download using its content URI or file path.
  Future<bool> deleteStoredFile({
    required String storageUri,
    String storageType = 'media_store',
    String? filePath,
  });

  /// Checks whether the stored item currently exists.
  Future<bool> fileExists({
    required String storageUri,
    String storageType = 'media_store',
    String? filePath,
  });

  /// Opens the stored media file with the device default player.
  Future<bool> openFile({
    required String storageUri,
    required String mimeType,
    required String title,
    String storageType = 'media_store',
    String? filePath,
  });

  /// Shares the stored media file with external applications.
  Future<bool> shareFile({
    required String storageUri,
    required String mimeType,
    required String title,
    String storageType = 'media_store',
    String? filePath,
  });

  /// Checks if enough free storage is available for the given byte count.
  Future<bool> isStorageAvailable(int requiredBytes);
}

/// Android production storage adapter leveraging MediaStore & ContentResolver.
class AndroidMediaStoreStorageService implements DownloadStorageService {
  static const MethodChannel _channel =
      MethodChannel('com.afridilabz.tiktok_downloader/media_store');

  @override
  Future<StorageFinalizeResult> finalizeDownload({
    required String tempFilePath,
    required String fileName,
    required String mimeType,
    required bool isAudioOnly,
    String relativeSubDir = 'TokSaver',
  }) async {
    AppLogger.i('FINALIZATION_STARTED: $fileName (mime: $mimeType, audio: $isAudioOnly)');

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveToMediaStore',
        {
          'tempFilePath': tempFilePath,
          'displayName': fileName,
          'mimeType': mimeType,
          'isAudio': isAudioOnly,
          'relativeSubDir': relativeSubDir,
        },
      );

      if (result == null) {
        throw const StorageError(message: 'MediaStore native adapter returned null result.');
      }

      final uri = result['uri']?.toString() ?? '';
      final storageType = result['storageType']?.toString() ?? 'media_store';
      final path = result['filePath']?.toString();
      final displayName = result['displayName']?.toString() ?? fileName;
      final returnedMime = result['mimeType']?.toString() ?? mimeType;
      final relativePath = result['relativePath']?.toString();
      final size = (result['size'] as num?)?.toInt() ?? 0;

      final finalizeResult = StorageFinalizeResult(
        storageType: storageType,
        storageUri: uri,
        filePath: path,
        displayName: displayName,
        mimeType: returnedMime,
        relativePath: relativePath,
        sizeBytes: size,
      );

      AppLogger.i('FINALIZATION_COMPLETED: ${finalizeResult.storageUri} ($size bytes)');
      return finalizeResult;
    } on PlatformException catch (e, stack) {
      AppLogger.e('MediaStore platform error during finalization: ${e.message}', e, stack);
      if (e.code == 'STORAGE_ERROR' && (e.message?.contains('ENOSPC') ?? false)) {
        throw const StorageError(message: 'Insufficient storage space on device.');
      }
      throw StorageError(message: 'Failed to save media to gallery: ${e.message}');
    } catch (e, stack) {
      AppLogger.e('Unexpected error during MediaStore finalization', e, stack);
      throw StorageError(message: 'Unable to commit download to storage: $e');
    }
  }

  @override
  Future<bool> deleteStoredFile({
    required String storageUri,
    String storageType = 'media_store',
    String? filePath,
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('deleteMedia', {
        'uri': storageUri,
        'storageType': storageType,
        'filePath': filePath,
      });
      return success ?? false;
    } catch (e) {
      AppLogger.w('Failed to delete media via MediaStore: $e');
      return false;
    }
  }

  @override
  Future<bool> fileExists({
    required String storageUri,
    String storageType = 'media_store',
    String? filePath,
  }) async {
    try {
      final exists = await _channel.invokeMethod<bool>('mediaExists', {
        'uri': storageUri,
        'storageType': storageType,
        'filePath': filePath,
      });
      return exists ?? false;
    } catch (e) {
      AppLogger.w('Error checking MediaStore existence: $e');
      return false;
    }
  }

  @override
  Future<bool> openFile({
    required String storageUri,
    required String mimeType,
    required String title,
    String storageType = 'media_store',
    String? filePath,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('openMedia', {
        'uri': storageUri,
        'mimeType': mimeType,
        'title': title,
        'storageType': storageType,
        'filePath': filePath,
      });
      return ok ?? false;
    } catch (e) {
      AppLogger.e('Failed to open media: $e');
      return false;
    }
  }

  @override
  Future<bool> shareFile({
    required String storageUri,
    required String mimeType,
    required String title,
    String storageType = 'media_store',
    String? filePath,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('shareMedia', {
        'uri': storageUri,
        'mimeType': mimeType,
        'title': title,
        'storageType': storageType,
        'filePath': filePath,
      });
      return ok ?? false;
    } catch (e) {
      AppLogger.e('Failed to share media: $e');
      return false;
    }
  }

  @override
  Future<bool> isStorageAvailable(int requiredBytes) async {
    return true;
  }
}

/// Fallback storage adapter for iOS, macOS, Windows, Linux, and Web.
class DefaultFileSystemStorageService implements DownloadStorageService {
  @override
  Future<StorageFinalizeResult> finalizeDownload({
    required String tempFilePath,
    required String fileName,
    required String mimeType,
    required bool isAudioOnly,
    String relativeSubDir = 'TokSaver',
  }) async {
    if (kIsWeb) {
      return StorageFinalizeResult(
        storageType: 'web_storage',
        storageUri: tempFilePath,
        displayName: fileName,
        mimeType: mimeType,
        sizeBytes: 0,
      );
    }

    final tempFile = File(tempFilePath);
    if (!await tempFile.exists()) {
      throw StorageError(message: 'Temporary download file missing: $tempFilePath');
    }

    final totalBytes = await tempFile.length();
    final destDir = await FileManager.getDefaultDownloadDirectory();
    final uniquePath = await FileManager.resolveUniqueFilePath(
      directory: destDir,
      fileName: fileName,
    );

    final destFile = File(uniquePath);
    // Use streaming copy (64KB buffer) to safely bridge mount points without cross-device rename
    final reader = tempFile.openRead();
    final writer = destFile.openWrite();
    await reader.pipe(writer);

    final destSize = await destFile.length();
    if (destSize != totalBytes) {
      await destFile.delete();
      throw StorageError(message: 'Stream copy verification failed (size mismatch).');
    }

    // Safely clean up temporary file
    await tempFile.delete();

    return StorageFinalizeResult(
      storageType: 'file_system',
      storageUri: destFile.path,
      filePath: destFile.path,
      displayName: p.basename(destFile.path),
      mimeType: mimeType,
      relativePath: relativeSubDir,
      sizeBytes: destSize,
    );
  }

  @override
  Future<bool> deleteStoredFile({
    required String storageUri,
    String storageType = 'file_system',
    String? filePath,
  }) async {
    final path = filePath ?? storageUri;
    return FileManager.deleteFileIfExists(path);
  }

  @override
  Future<bool> fileExists({
    required String storageUri,
    String storageType = 'file_system',
    String? filePath,
  }) async {
    final path = filePath ?? storageUri;
    return FileManager.fileExists(path);
  }

  @override
  Future<bool> openFile({
    required String storageUri,
    required String mimeType,
    required String title,
    String storageType = 'file_system',
    String? filePath,
  }) async {
    if (kIsWeb) {
      final uri = Uri.parse(storageUri);
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    final path = filePath ?? storageUri;
    final file = File(path);
    if (await file.exists()) {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri);
      }
    }
    return false;
  }

  @override
  Future<bool> shareFile({
    required String storageUri,
    required String mimeType,
    required String title,
    String storageType = 'file_system',
    String? filePath,
  }) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(text: '$title: $storageUri', subject: title),
      );
      return true;
    }
    final path = filePath ?? storageUri;
    final file = File(path);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(text: title, files: [XFile(path, mimeType: mimeType)]),
      );
      return true;
    }
    return false;
  }

  @override
  Future<bool> isStorageAvailable(int requiredBytes) async {
    return true;
  }
}

/// Provider exposing the appropriate storage service for the active platform.
final downloadStorageServiceProvider = Provider<DownloadStorageService>((ref) {
  if (!kIsWeb && Platform.isAndroid) {
    return AndroidMediaStoreStorageService();
  }
  return DefaultFileSystemStorageService();
});
