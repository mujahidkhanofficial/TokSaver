import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Manages local file operations, directory resolution, and filename sanitization.
class FileManager {
  /// Windows & POSIX reserved filenames that must not be used directly.
  static final Set<String> _reservedNames = {
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
  };

  /// Sanitize filename by removing illegal filesystem characters, path traversal,
  /// reserved words, and limiting length while preserving file extension.
  static String sanitizeFileName(
    String name, {
    String defaultName = 'download',
    String? extensionOverride,
  }) {
    // 1. Remove path traversal sequences (../, ..\, etc.)
    var sanitized = name
        .replaceAll(RegExp(r'\.\.[/\\]?'), '')
        .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 2. Separate extension and stem
    var ext = p.extension(sanitized);
    var stem = p.basenameWithoutExtension(sanitized);

    if (extensionOverride != null && extensionOverride.isNotEmpty) {
      ext = extensionOverride.startsWith('.') ? extensionOverride : '.$extensionOverride';
    }

    // 3. Remove trailing dots and spaces from stem
    stem = stem.replaceAll(RegExp(r'[\.\s]+$'), '').trim();

    // 4. Fallback if empty
    if (stem.isEmpty) {
      stem = defaultName;
    }

    // 5. Guard against reserved names
    if (_reservedNames.contains(stem.toUpperCase())) {
      stem = '${stem}_file';
    }

    // 6. Enforce length limit while preserving extension
    final maxStemLength = AppConstants.maxFilenameLength - ext.length;
    if (maxStemLength > 0 && stem.length > maxStemLength) {
      stem = stem.substring(0, maxStemLength).trim();
    }

    return '$stem$ext';
  }

  /// Resolve standard MIME type for a file name and media type.
  static String resolveMimeType(String fileName, {bool isAudio = false}) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.mp4':
        return 'video/mp4';
      case '.webm':
        return 'video/webm';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
      case '.aac':
        return 'audio/mp4';
      case '.ogg':
      case '.opus':
        return 'audio/ogg';
      default:
        return isAudio ? 'audio/mpeg' : 'video/mp4';
    }
  }

  /// Resolve canonical file extension for a MIME type.
  static String resolveExtension(String mimeType, {bool isAudio = false}) {
    final lower = mimeType.toLowerCase();
    if (lower.contains('audio/mpeg') || lower.contains('mp3')) return '.mp3';
    if (lower.contains('audio/mp4') || lower.contains('m4a')) return '.m4a';
    if (lower.contains('audio/ogg') || lower.contains('opus')) return '.ogg';
    if (lower.contains('video/webm')) return '.webm';
    return isAudio ? '.mp3' : '.mp4';
  }

  /// Get the dedicated temporary directory for in-progress downloads (.part files).
  static Future<Directory> getTempDirectory() async {
    if (kIsWeb) {
      return Directory('/tmp');
    }
    final cacheDir = await getTemporaryDirectory();
    final tempDir = Directory(p.join(cacheDir.path, AppConstants.tempDownloadDirName));
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  /// Get the default destination directory for completed downloads.
  static Future<Directory> getDefaultDownloadDirectory() async {
    if (kIsWeb) {
      return Directory('/web_downloads');
    }

    if (Platform.isAndroid) {
      try {
        final externalDirs = await getExternalStorageDirectories(
          type: StorageDirectory.movies,
        );
        if (externalDirs != null && externalDirs.isNotEmpty) {
          final target = Directory(p.join(externalDirs.first.path, AppConstants.mediaSubDir));
          if (!await target.exists()) {
            await target.create(recursive: true);
          }
          return target;
        }
      } catch (e) {
        AppLogger.w('Failed to get external storage movies dir: $e');
      }

      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final target = Directory(p.join(downloadsDir.path, AppConstants.mediaSubDir));
        if (!await target.exists()) {
          await target.create(recursive: true);
        }
        return target;
      }
    }

    // Fallback for iOS or desktop
    final docsDir = await getApplicationDocumentsDirectory();
    final target = Directory(p.join(docsDir.path, AppConstants.mediaSubDir));
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  /// Resolve unique file path in target directory, appending (1), (2), etc. if conflict exists.
  static Future<String> resolveUniqueFilePath({
    required Directory directory,
    required String fileName,
  }) async {
    if (kIsWeb) {
      return fileName;
    }
    final ext = p.extension(fileName);
    final stem = p.basenameWithoutExtension(fileName);

    var candidatePath = p.join(directory.path, fileName);
    var candidateFile = File(candidatePath);
    var counter = 1;

    while (await candidateFile.exists()) {
      final newName = '$stem ($counter)$ext';
      candidatePath = p.join(directory.path, newName);
      candidateFile = File(candidatePath);
      counter++;
    }

    return candidatePath;
  }

  /// Create a unique temp file path for a task ID with .part extension.
  static Future<String> getTempFilePath(String taskId) async {
    final tempDir = await getTempDirectory();
    return p.join(tempDir.path, '$taskId.part');
  }

  /// Delete file if it exists.
  static Future<bool> deleteFileIfExists(String filePath) async {
    if (kIsWeb || filePath.isEmpty) return false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      AppLogger.e('Error deleting file: $filePath', e);
    }
    return false;
  }

  /// Check if file exists.
  static Future<bool> fileExists(String filePath) async {
    if (kIsWeb || filePath.isEmpty) return false;
    try {
      return await File(filePath).exists();
    } catch (_) {
      return false;
    }
  }

  /// Get actual size of a file in bytes.
  static Future<int> getFileSize(String filePath) async {
    if (kIsWeb || filePath.isEmpty) return 0;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }
}
