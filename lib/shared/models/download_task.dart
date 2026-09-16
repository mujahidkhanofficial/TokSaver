import 'package:flutter/foundation.dart';

/// Current status of a download task lifecycle.
enum DownloadStatus {
  queued,
  downloading,
  paused,
  finalizing,
  completed,
  failed,
  cancelled;

  bool get isTerminal =>
      this == completed || this == failed || this == cancelled;

  bool get isActive =>
      this == downloading || this == queued || this == finalizing;

  bool get canPause => this == downloading;

  bool get canResume => this == paused || this == failed;

  bool get canCancel =>
      this == queued || this == downloading || this == paused;

  bool get canRetry => this == failed || this == cancelled;
}

/// In-memory domain representation of an active or completed download task.
@immutable
class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.author,
    this.authorAvatarUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.targetFilePath,
    required this.fileName,
    this.storageType = 'media_store',
    this.storageUri,
    this.mimeType,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    this.speedBytesPerSec = 0,
    this.etaDuration,
    this.hasWatermark = false,
    this.isAudioOnly = false,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  final String id;
  final String url;
  final String title;
  final String author;
  final String? authorAvatarUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;

  /// User-visible target path or canonical identifier.
  final String targetFilePath;
  final String fileName;

  /// Underlying storage model: 'media_store', 'legacy_file', or 'file_system'.
  final String storageType;

  /// Content URI ('content://...') on modern Android or null for raw paths.
  final String? storageUri;

  /// Verified MIME type (e.g. 'video/mp4', 'audio/mpeg').
  final String? mimeType;

  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final int speedBytesPerSec;
  final Duration? etaDuration;
  final bool hasWatermark;
  final bool isAudioOnly;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  /// Canonical URI to access/open/share the file: prefers storageUri (content://) then targetFilePath.
  String get canonicalUri => storageUri ?? targetFilePath;

  /// Progress fraction from 0.0 to 1.0.
  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  /// Progress as percentage integer 0..100.
  int get progressPercent => (progress * 100).toInt();

  /// Human-readable download speed (e.g. "2.4 MB/s").
  String get formattedSpeed {
    if (speedBytesPerSec <= 0) return '0 KB/s';
    if (speedBytesPerSec < 1024 * 1024) {
      final kb = speedBytesPerSec / 1024;
      return '${kb.toStringAsFixed(1)} KB/s';
    }
    final mb = speedBytesPerSec / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  /// Human-readable file size.
  String get formattedTotalSize => formatBytes(totalBytes);
  String get formattedDownloadedSize => formatBytes(downloadedBytes);

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'author': author,
      'authorAvatarUrl': authorAvatarUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'targetFilePath': targetFilePath,
      'fileName': fileName,
      'storageType': storageType,
      'storageUri': storageUri,
      'mimeType': mimeType,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.name,
      'hasWatermark': hasWatermark,
      'isAudioOnly': isAudioOnly,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    DownloadStatus status;
    try {
      status = DownloadStatus.values.byName(json['status'] as String? ?? 'completed');
    } catch (_) {
      status = DownloadStatus.completed;
    }

    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? 'TikTok Creator',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      targetFilePath: json['targetFilePath'] as String? ?? json['fileName'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'media_file',
      storageType: json['storageType'] as String? ?? 'media_store',
      storageUri: json['storageUri'] as String?,
      mimeType: json['mimeType'] as String?,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt() ?? 0,
      status: status,
      hasWatermark: json['hasWatermark'] as bool? ?? false,
      isAudioOnly: json['isAudioOnly'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  DownloadTask copyWith({
    String? id,
    String? url,
    String? title,
    String? author,
    String? authorAvatarUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? targetFilePath,
    String? fileName,
    String? storageType,
    String? storageUri,
    String? mimeType,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    int? speedBytesPerSec,
    Duration? etaDuration,
    bool? hasWatermark,
    bool? isAudioOnly,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      author: author ?? this.author,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      targetFilePath: targetFilePath ?? this.targetFilePath,
      fileName: fileName ?? this.fileName,
      storageType: storageType ?? this.storageType,
      storageUri: storageUri ?? this.storageUri,
      mimeType: mimeType ?? this.mimeType,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      etaDuration: etaDuration ?? this.etaDuration,
      hasWatermark: hasWatermark ?? this.hasWatermark,
      isAudioOnly: isAudioOnly ?? this.isAudioOnly,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          downloadedBytes == other.downloadedBytes &&
          totalBytes == other.totalBytes &&
          speedBytesPerSec == other.speedBytesPerSec &&
          storageUri == other.storageUri;

  @override
  int get hashCode =>
      id.hashCode ^
      status.hashCode ^
      downloadedBytes.hashCode ^
      totalBytes.hashCode ^
      speedBytesPerSec.hashCode ^
      storageUri.hashCode;
}
