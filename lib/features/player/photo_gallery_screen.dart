import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/storage/download_storage_service.dart';
import '../../shared/models/download_task.dart';

class PhotoGalleryScreen extends ConsumerStatefulWidget {
  const PhotoGalleryScreen({
    super.key,
    required this.task,
  });

  final DownloadTask task;

  @override
  ConsumerState<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerState<PhotoGalleryScreen> {
  final TransformationController _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _showControls = true;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final matrix = Matrix4.identity();
      matrix.setEntry(0, 0, 2.5);
      matrix.setEntry(1, 1, 2.5);
      matrix.setEntry(0, 3, -position.dx * 1.5);
      matrix.setEntry(1, 3, -position.dy * 1.5);
      _transformController.value = matrix;
    }
  }

  Future<void> _sharePhoto() async {
    final storage = ref.read(downloadStorageServiceProvider);
    final task = widget.task;
    await storage.shareFile(
      storageUri: task.storageUri ?? task.targetFilePath,
      mimeType: task.mimeType ?? 'image/jpeg',
      title: task.title,
      storageType: task.storageType,
      filePath: task.targetFilePath,
    );
  }

  Future<void> _openExternal() async {
    final storage = ref.read(downloadStorageServiceProvider);
    final task = widget.task;
    await storage.openFile(
      storageUri: task.storageUri ?? task.targetFilePath,
      mimeType: task.mimeType ?? 'image/jpeg',
      title: task.title,
      storageType: task.storageType,
      filePath: task.targetFilePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final file = File(task.targetFilePath);
    final isLocalFile = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Zoomable Image Canvas ─────────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() => _showControls = !_showControls);
            },
            onDoubleTapDown: (d) => _doubleTapDetails = d,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 4.5,
              child: Center(
                child: isLocalFile
                    ? Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => _buildFallbackImage(task),
                      )
                    : _buildFallbackImage(task),
              ),
            ),
          ),

          // ── Top Bar ───────────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              task.title,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '@${task.author}',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        tooltip: 'Share',
                        onPressed: _sharePhoto,
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                        tooltip: 'Open in Gallery',
                        onPressed: _openExternal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Info Bar ───────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task.fileName,
                        style: AppTypography.monoSmall.copyWith(color: Colors.white70),
                      ),
                      Text(
                        task.formattedTotalSize,
                        style: AppTypography.monoSmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(DownloadTask task) {
    if (task.thumbnailUrl != null && task.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: task.thumbnailUrl!,
        fit: BoxFit.contain,
        placeholder: (ctx, url) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        errorWidget: (ctx, url, err) => const Center(
          child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.photo_rounded, size: 64, color: Colors.white54),
    );
  }
}
