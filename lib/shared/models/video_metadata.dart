import 'package:flutter/foundation.dart';

/// Representation of parsed TikTok video or photo post information before downloading.
@immutable
class VideoMetadata {
  const VideoMetadata({
    required this.id,
    required this.originalUrl,
    required this.title,
    required this.authorName,
    required this.authorUsername,
    this.authorAvatarUrl,
    this.coverUrl,
    this.durationSeconds = 0,
    required this.videoUrlNoWatermark,
    this.videoUrlWatermark,
    this.audioUrl,
    this.images = const [],
    this.videoSizeBytes = 0,
    this.audioSizeBytes = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
  });

  final String id;
  final String originalUrl;
  final String title;
  final String authorName;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String? coverUrl;
  final int durationSeconds;
  final String videoUrlNoWatermark;
  final String? videoUrlWatermark;
  final String? audioUrl;

  /// High-resolution image URLs for TikTok photo slide / carousel posts.
  final List<String> images;

  final int videoSizeBytes;
  final int audioSizeBytes;
  final int likeCount;
  final int commentCount;
  final int shareCount;

  /// Returns true if this TikTok post is an image slideshow.
  bool get isPhotoPost => images.isNotEmpty;

  /// Formatted duration (e.g. "0:45" or "1:12").
  String get formattedDuration {
    if (durationSeconds <= 0) return isPhotoPost ? 'Photo Slide' : '0:00';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Safe display title fallback.
  String get displayTitle {
    if (title.trim().isEmpty) {
      return isPhotoPost ? 'TikTok Photos ($id)' : 'TikTok Video ($id)';
    }
    return title.trim();
  }

  /// Safe default filename for video.
  String get defaultVideoFileName {
    final cleanAuthor = authorUsername.replaceAll(RegExp(r'[^\w-]'), '_');
    return 'tiktok_${cleanAuthor}_$id.mp4';
  }

  /// Safe default filename for extracted audio.
  String get defaultAudioFileName {
    final cleanAuthor = authorUsername.replaceAll(RegExp(r'[^\w-]'), '_');
    return 'tiktok_${cleanAuthor}_$id.mp3';
  }

  /// Safe default filename for individual photo in carousel (1-indexed).
  String defaultPhotoFileName(int index, {String ext = 'jpg'}) {
    final cleanAuthor = authorUsername.replaceAll(RegExp(r'[^\w-]'), '_');
    final numStr = index.toString().padLeft(2, '0');
    return 'tiktok_${cleanAuthor}_${id}_$numStr.$ext';
  }
}
