import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/errors/app_error.dart';
import '../../shared/models/video_metadata.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_error_view.dart';
import '../downloads/download_controller.dart';
import 'analyzer_provider.dart';

class VideoDetailScreen extends ConsumerStatefulWidget {
  const VideoDetailScreen({
    super.key,
    this.url,
    this.initialMetadata,
  });

  final String? url;
  final VideoMetadata? initialMetadata;

  @override
  ConsumerState<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends ConsumerState<VideoDetailScreen> {
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialMetadata != null) {
        // Already analyzed
      } else if (widget.url != null && widget.url!.isNotEmpty) {
        ref.read(analyzerStateProvider.notifier).analyze(widget.url!);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDownloadSelected(
    BuildContext context,
    VideoMetadata metadata, {
    bool hasWatermark = false,
    bool isAudioOnly = false,
  }) async {
    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final taskId = await ref
        .read(downloadTasksMapProvider.notifier)
        .startDownload(metadata, hasWatermark: hasWatermark, isAudioOnly: isAudioOnly);

    if (context.mounted) {
      navigator.pop();

      if (taskId != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              isAudioOnly
                  ? 'Audio download started'
                  : 'Video download started',
            ),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: AppColors.primaryLight,
              onPressed: () {
                router.go(AppRoutes.downloads);
              },
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to start download. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onDownloadAllPhotos(BuildContext context, VideoMetadata metadata) async {
    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final taskIds = await ref
        .read(downloadTasksMapProvider.notifier)
        .startPhotoDownloads(metadata);

    if (context.mounted) {
      navigator.pop();

      if (taskIds.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Downloading ${taskIds.length} photos...'),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: AppColors.primaryLight,
              onPressed: () {
                router.go(AppRoutes.downloads);
              },
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to start photo downloads.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyzerState = ref.watch(analyzerStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Options'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: widget.initialMetadata != null
          ? _buildContent(context, widget.initialMetadata!)
          : analyzerState.when(
              data: (metadata) {
                if (metadata == null) {
                  return const Center(
                    child: Text('No video information found.'),
                  );
                }
                return _buildContent(context, metadata);
              },
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Analyzing TikTok link...',
                      style: AppTypography.titleMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Fetching highest quality stream and metadata',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, _) {
                final message = error is AppError
                    ? error.userMessage
                    : 'Failed to analyze this TikTok link.';
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: AppErrorView(
                      message: message,
                      onRetry: widget.url != null
                          ? () => ref
                              .read(analyzerStateProvider.notifier)
                              .analyze(widget.url!)
                          : null,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildContent(BuildContext context, VideoMetadata metadata) {
    final isPhoto = metadata.isPhotoPost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPhoto)
            _buildPhotoCarouselCard(context, metadata)
          else
            _buildVideoPreviewCard(context, metadata),
          const SizedBox(height: AppSpacing.lg),
          _buildAuthorCard(context, metadata),
          const SizedBox(height: AppSpacing.lg),
          if (isPhoto)
            ..._buildPhotoDownloadOptions(context, metadata)
          else
            ..._buildVideoDownloadOptions(context, metadata),
        ],
      ),
    );
  }

  Widget _buildPhotoCarouselCard(BuildContext context, VideoMetadata metadata) {
    final theme = Theme.of(context);
    final images = metadata.images;

    return AppCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPhotoIndex = idx;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imgUrl = images[index];
                    return CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_rounded, size: 48),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '${_currentPhotoIndex + 1} / ${images.length}',
                        style: AppTypography.monoSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (metadata.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                metadata.title,
                style: AppTypography.titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPreviewCard(BuildContext context, VideoMetadata metadata) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.coverUrl != null && metadata.coverUrl!.isNotEmpty)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: metadata.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_rounded, size: 48),
                    ),
                  ),
                ),
                if (metadata.durationSeconds > 0)
                  Positioned(
                    bottom: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            metadata.formattedDuration,
                            style: AppTypography.monoSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          if (metadata.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                metadata.title,
                style: AppTypography.titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthorCard(BuildContext context, VideoMetadata metadata) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: metadata.authorAvatarUrl != null
                ? CachedNetworkImageProvider(metadata.authorAvatarUrl!)
                : null,
            child: metadata.authorAvatarUrl == null
                ? Text(
                    metadata.authorName.isNotEmpty
                        ? metadata.authorName[0].toUpperCase()
                        : '?',
                    style: AppTypography.titleMedium.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.authorName.isNotEmpty
                      ? metadata.authorName
                      : metadata.authorUsername,
                  style: AppTypography.titleSmall,
                ),
                if (metadata.authorUsername.isNotEmpty)
                  Text(
                    '@${metadata.authorUsername}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatChip(
                Icons.favorite_rounded,
                _formatCount(metadata.likeCount),
                AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildStatChip(
                Icons.mode_comment_rounded,
                _formatCount(metadata.commentCount),
                theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhotoDownloadOptions(BuildContext context, VideoMetadata metadata) {
    final theme = Theme.of(context);

    return [
      Text(
        'AVAILABLE FORMATS',
        style: AppTypography.labelMedium.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),

      // Download All Photos (Primary)
      AppCard(
        onTap: () => _onDownloadAllPhotos(context, metadata),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.photo_library_rounded,
                color: theme.colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Download All Photos (${metadata.images.length})',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          'HD',
                          style: AppTypography.monoSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Save full-resolution slideshow to Pictures/TokSaver',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),

      const SizedBox(height: AppSpacing.sm),

      // Audio Only (Soundtrack)
      if (metadata.audioUrl != null && metadata.audioUrl!.isNotEmpty)
        AppCard(
          onTap: () => _onDownloadSelected(
            context,
            metadata,
            hasWatermark: false,
            isAudioOnly: true,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Audio (MP3)',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Extract background music / soundtrack',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),

      const SizedBox(height: AppSpacing.xl),
    ];
  }

  List<Widget> _buildVideoDownloadOptions(BuildContext context, VideoMetadata metadata) {
    final theme = Theme.of(context);

    return [
      Text(
        'AVAILABLE FORMATS',
        style: AppTypography.labelMedium.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),

      // Option 1: No Watermark (Primary)
      AppCard(
        onTap: () => _onDownloadSelected(
          context,
          metadata,
          hasWatermark: false,
          isAudioOnly: false,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.high_quality_rounded,
                color: theme.colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Video (No Watermark)',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          'BEST',
                          style: AppTypography.monoSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Clean video with no TikTok logo (HD MP4)',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),

      const SizedBox(height: AppSpacing.sm),

      // Option 2: With Watermark
      AppCard(
        onTap: () => _onDownloadSelected(
          context,
          metadata,
          hasWatermark: true,
          isAudioOnly: false,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.water_drop_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video (With Watermark)',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Original stream with TikTok watermark (MP4)',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),

      const SizedBox(height: AppSpacing.sm),

      // Option 3: Audio Only (MP3)
      AppCard(
        onTap: () => _onDownloadSelected(
          context,
          metadata,
          hasWatermark: false,
          isAudioOnly: true,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: theme.colorScheme.onSecondaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio Only (MP3)',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Extract music / soundtrack only',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),

      const SizedBox(height: AppSpacing.xl),
    ];
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
