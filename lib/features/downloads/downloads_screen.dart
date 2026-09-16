import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/storage/storage_providers.dart';
import '../../shared/models/download_task.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import 'download_controller.dart';

/// Downloads screen displaying real-time active, queued, paused, and failed tasks.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inMemoryTasks = ref.watch(downloadTasksMapProvider);
    final dbActiveTasks = ref.watch(activeDownloadsStreamProvider);

    // Merge in-memory tasks (which have speed/ETA) with DB active tasks
    final tasksMap = <String, DownloadTask>{};

    dbActiveTasks.maybeWhen(
      data: (dbTasks) {
        for (final t in dbTasks) {
          tasksMap[t.id] = t;
        }
      },
      orElse: () {},
    );

    // Override with in-memory active tasks for live progress
    for (final entry in inMemoryTasks.entries) {
      tasksMap[entry.key] = entry.value;
    }

    final allTasks = tasksMap.values.toList();
    final downloading = allTasks
        .where((t) =>
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.finalizing)
        .toList();
    final queued = allTasks.where((t) => t.status == DownloadStatus.queued).toList();
    final paused = allTasks.where((t) => t.status == DownloadStatus.paused).toList();
    final failed = allTasks.where((t) => t.status == DownloadStatus.failed).toList();

    final hasAny = downloading.isNotEmpty || queued.isNotEmpty || paused.isNotEmpty || failed.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (downloading.isNotEmpty)
            TextButton(
              onPressed: () {
                for (final t in downloading) {
                  ref.read(downloadTasksMapProvider.notifier).pauseDownload(t.id);
                }
              },
              child: const Text('Pause All'),
            )
          else if (paused.isNotEmpty)
            TextButton(
              onPressed: () {
                for (final t in paused) {
                  ref.read(downloadTasksMapProvider.notifier).resumeDownload(t.id);
                }
              },
              child: const Text('Resume All'),
            ),
        ],
      ),
      body: !hasAny
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                if (downloading.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Downloading', downloading.length, AppColors.downloading),
                  ...downloading.map((t) => _buildTaskCard(context, ref, t)),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (queued.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Queued', queued.length, theme.colorScheme.onSurfaceVariant),
                  ...queued.map((t) => _buildTaskCard(context, ref, t)),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (paused.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Paused', paused.length, AppColors.paused),
                  ...paused.map((t) => _buildTaskCard(context, ref, t)),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (failed.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Failed', failed.length, AppColors.error),
                  ...failed.map((t) => _buildTaskCard(context, ref, t)),
                ],
              ],
            ),
      bottomSheet: (downloading.length + queued.length + paused.length >= 2)
          ? Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (downloading.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                      label: const Text('Pause All'),
                      onPressed: () {
                        for (final t in downloading) {
                          ref.read(downloadTasksMapProvider.notifier).pauseDownload(t.id);
                        }
                      },
                    ),
                  if (paused.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                      label: const Text('Resume All'),
                      onPressed: () {
                        for (final t in paused) {
                          ref.read(downloadTasksMapProvider.notifier).resumeDownload(t.id);
                        }
                      },
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                    label: const Text('Cancel All', style: TextStyle(color: AppColors.error)),
                    onPressed: () {
                      for (final t in [...downloading, ...paused, ...queued]) {
                        ref.read(downloadTasksMapProvider.notifier).cancelDownload(t.id);
                      }
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$title ($count)',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, DownloadTask task) {
    final theme = Theme.of(context);
    final isFinalizing = task.status == DownloadStatus.finalizing;
    final isDownloading = task.status == DownloadStatus.downloading;
    final isPaused = task.status == DownloadStatus.paused;
    final isFailed = task.status == DownloadStatus.failed;
    final isQueued = task.status == DownloadStatus.queued;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: task.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: task.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                task.isAudioOnly ? Icons.music_note_rounded : Icons.movie_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              task.isAudioOnly ? Icons.music_note_rounded : Icons.movie_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppTypography.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${task.author}',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
                            decoration: BoxDecoration(
                              color: task.isAudioOnly
                                  ? theme.colorScheme.secondaryContainer
                                  : theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              task.isAudioOnly ? 'MP3' : (task.hasWatermark ? 'WM' : 'NO-WM'),
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: task.isAudioOnly
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            task.totalBytes > 0
                                ? '${task.formattedDownloadedSize} / ${task.formattedTotalSize}'
                                : task.formattedDownloadedSize,
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDownloading)
                      IconButton(
                        icon: const Icon(Icons.pause_circle_filled_rounded, size: 28),
                        color: AppColors.paused,
                        tooltip: 'Pause',
                        onPressed: () => ref
                            .read(downloadTasksMapProvider.notifier)
                            .pauseDownload(task.id),
                      )
                    else if (isPaused)
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
                        color: theme.colorScheme.primary,
                        tooltip: 'Resume',
                        onPressed: () => ref
                            .read(downloadTasksMapProvider.notifier)
                            .resumeDownload(task.id),
                      )
                    else if (isFailed)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 28),
                        color: theme.colorScheme.primary,
                        tooltip: 'Retry',
                        onPressed: () => ref
                            .read(downloadTasksMapProvider.notifier)
                            .retryDownload(task.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: theme.colorScheme.onSurfaceVariant,
                      tooltip: 'Cancel',
                      onPressed: () => ref
                          .read(downloadTasksMapProvider.notifier)
                          .cancelDownload(task.id),
                    ),
                  ],
                ),
              ],
            ),
            if (isDownloading || isPaused || isQueued || isFinalizing) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: SizedBox(
                  height: 7,
                  child: Stack(
                    children: [
                      Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      if (!isQueued && !isFinalizing)
                        FractionallySizedBox(
                          widthFactor: task.progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPaused
                                    ? [AppColors.paused, AppColors.warning]
                                    : [AppColors.primary, AppColors.mintAccent],
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        )
                      else
                        LinearProgressIndicator(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          minHeight: 7,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFinalizing
                        ? 'Saving to gallery…'
                        : (isQueued ? 'Waiting in queue...' : '${task.progressPercent}%'),
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPaused ? AppColors.paused : theme.colorScheme.primary,
                    ),
                  ),
                  if (isDownloading && task.speedBytesPerSec > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            '${task.formattedSpeed}${task.etaDuration != null ? ' • ${task.etaDuration!.inSeconds}s left' : ''}',
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (isFailed && task.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Error: ${task.errorMessage}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_done_rounded,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No active downloads', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Paste a TikTok video link on the home screen to download videos and audio.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Paste Link',
              icon: Icons.link_rounded,
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}
