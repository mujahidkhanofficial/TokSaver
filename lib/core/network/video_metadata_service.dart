import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/app_error.dart';
import '../errors/result.dart';
import '../utils/app_logger.dart';
import '../../shared/models/video_metadata.dart';
import 'dio_client.dart';

/// Abstract contract for extracting TikTok video metadata and stream URLs.
abstract class VideoMetadataService {
  Future<Result<VideoMetadata>> fetchMetadata(String tiktokUrl);
}

/// Production implementation using the TikWM API engine with graceful error mapping.
class TikWMVideoMetadataService implements VideoMetadataService {
  TikWMVideoMetadataService({
    Dio? dio,
    String? apiBaseUrl,
  })  : _dio = dio ?? DioClient.instance,
        _apiBaseUrl = apiBaseUrl ?? 'https://www.tikwm.com/api/';

  final Dio _dio;
  final String _apiBaseUrl;

  @override
  Future<Result<VideoMetadata>> fetchMetadata(String tiktokUrl) async {
    try {
      AppLogger.i('Fetching metadata for: $tiktokUrl');

      final response = await _dio.post(
        _apiBaseUrl,
        data: FormData.fromMap({
          'url': tiktokUrl.trim(),
          'hd': 1,
        }),
        options: Options(
          sendTimeout: AppConstants.analyzeTimeout,
          receiveTimeout: AppConstants.analyzeTimeout,
        ),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        return const Result.err(
          ParseError(message: 'Unexpected response format from metadata service.'),
        );
      }

      final code = body['code'];
      if (code != 0) {
        final msg = body['msg']?.toString() ?? 'Video not found or is private.';
        return Result.err(VideoUnavailableError(message: msg));
      }

      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        return const Result.err(
          VideoUnavailableError(
            message: 'No video data returned. The video may be deleted, private, or region-restricted.',
          ),
        );
      }

      // Helper to normalize relative or protocol-relative URLs
      String? normalizeUrl(dynamic raw) {
        if (raw == null) return null;
        final url = raw.toString().trim();
        if (url.isEmpty) return null;
        if (url.startsWith('//')) {
          return 'https:$url';
        } else if (url.startsWith('/')) {
          return 'https://www.tikwm.com$url';
        }
        return url;
      }

      // Parse fields safely
      final id = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final title = data['title']?.toString() ?? '';
      final cover = normalizeUrl(data['cover'] ?? data['origin_cover']);
      final duration = (data['duration'] as num?)?.toInt() ?? 0;

      // Extract URLs: prefer hdplay, then play (without watermark)
      final playNoWatermark = normalizeUrl(data['hdplay'] ?? data['play']) ?? '';
      final playWatermark = normalizeUrl(data['wmplay']);
      final musicUrl = normalizeUrl(data['music'] ?? data['music_info']?['play']);

      final size = (data['size'] as num?)?.toInt() ?? 0;

      // Extract photo carousel images if available
      List<String> images = [];
      if (data['images'] is List) {
        images = (data['images'] as List)
            .map((e) => normalizeUrl(e))
            .whereType<String>()
            .where((u) => u.startsWith('https://') || u.startsWith('http://'))
            .toSet()
            .toList();
      }

      // Author data
      final authorData = data['author'] as Map<String, dynamic>?;
      final authorName = authorData?['nickname']?.toString() ?? 'TikTok Creator';
      final authorUsername = authorData?['unique_id']?.toString() ?? 'user';
      final authorAvatar = normalizeUrl(authorData?['avatar']);

      // Stats
      final diggCount = (data['digg_count'] as num?)?.toInt() ?? 0;
      final commentCount = (data['comment_count'] as num?)?.toInt() ?? 0;
      final shareCount = (data['share_count'] as num?)?.toInt() ?? 0;

      if (playNoWatermark.isEmpty &&
          (playWatermark == null || playWatermark.isEmpty) &&
          images.isEmpty) {
        return const Result.err(
          VideoUnavailableError(
            message: 'No downloadable video or photo stream found for this URL.',
          ),
        );
      }

      final fallbackVideoUrl = playNoWatermark.isNotEmpty
          ? playNoWatermark
          : (playWatermark ?? (images.isNotEmpty ? images.first : ''));

      final metadata = VideoMetadata(
        id: id,
        originalUrl: tiktokUrl,
        title: title,
        authorName: authorName,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatar,
        coverUrl: cover ?? (images.isNotEmpty ? images.first : null),
        durationSeconds: duration,
        videoUrlNoWatermark: fallbackVideoUrl,
        videoUrlWatermark: playWatermark,
        audioUrl: musicUrl,
        images: images,
        videoSizeBytes: size,
        likeCount: diggCount,
        commentCount: commentCount,
        shareCount: shareCount,
      );

      AppLogger.i(
        'Successfully extracted metadata: ${metadata.displayTitle} by @${metadata.authorUsername} '
        '(isPhoto: ${metadata.isPhotoPost}, photos: ${metadata.images.length})',
      );
      return Result.ok(metadata);
    } on DioException catch (e) {
      final appError = DioClient.mapDioException(e);
      AppLogger.w('Failed to fetch metadata: ${appError.message}');
      return Result.err(appError);
    } catch (e, stack) {
      AppLogger.e('Unexpected error parsing metadata', e, stack);
      return Result.err(UnknownError(message: 'Failed to extract video details: $e', cause: e));
    }
  }
}