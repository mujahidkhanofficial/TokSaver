import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/video_metadata_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/url_validator.dart';
import '../../../shared/widgets/app_button.dart';
import '../../downloads/download_controller.dart';

class BatchDownloadDialog extends ConsumerStatefulWidget {
  const BatchDownloadDialog({super.key});

  @override
  ConsumerState<BatchDownloadDialog> createState() => _BatchDownloadDialogState();
}

class _BatchDownloadDialogState extends ConsumerState<BatchDownloadDialog> {
  final TextEditingController _controller = TextEditingController();
  List<String> _validUrls = [];
  List<String> _invalidUrls = [];
  int _duplicateCount = 0;
  bool _isEnqueuing = false;
  int _processedCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.removeListener(_validateInput);
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _validUrls = [];
        _invalidUrls = [];
        _duplicateCount = 0;
      });
      return;
    }

    // Split by newlines or whitespace
    final lines = raw
        .split(RegExp(r'[\r\n\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final seen = <String>{};
    final valid = <String>[];
    final invalid = <String>[];
    int duplicates = 0;

    for (final token in lines) {
      final extracted = UrlValidator.extractFirstUrl(token) ?? token;
      if (UrlValidator.isValidTikTokUrl(extracted)) {
        final clean = UrlValidator.cleanTrackingParameters(extracted);
        if (seen.contains(clean)) {
          duplicates++;
        } else {
          seen.add(clean);
          if (valid.length < 20) {
            valid.add(clean);
          }
        }
      } else {
        invalid.add(token);
      }
    }

    setState(() {
      _validUrls = valid;
      _invalidUrls = invalid;
      _duplicateCount = duplicates;
    });
  }

  Future<void> _startBatchDownload() async {
    if (_validUrls.isEmpty || _isEnqueuing) return;

    setState(() {
      _isEnqueuing = true;
      _processedCount = 0;
    });

    final metadataService = TikWMVideoMetadataService();
    final downloadNotifier = ref.read(downloadTasksMapProvider.notifier);
    int queuedCount = 0;
    int failedCount = 0;

    for (final url in _validUrls) {
      try {
        final result = await metadataService.fetchMetadata(url);
        if (result.isOk) {
          final metadata = result.value;
          final taskId = await downloadNotifier.startDownload(metadata);
          if (taskId != null) {
            queuedCount++;
          } else {
            failedCount++;
          }
        } else {
          AppLogger.w('Batch download failed for item $url: ${result.error.userMessage}');
          failedCount++;
        }
      } catch (e) {
        AppLogger.w('Batch download error for item $url: $e');
        failedCount++;
      }

      if (mounted) {
        setState(() {
          _processedCount++;
        });
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            failedCount == 0
                ? '$queuedCount downloads queued successfully.'
                : '$queuedCount queued, $failedCount failed to analyze.',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = _validUrls.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.dynamic_feed_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Batch Download',
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _isEnqueuing ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Paste multiple TikTok links (one per line, up to 20 links). All downloads will be added to the queue.',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                enabled: !_isEnqueuing,
                maxLines: 6,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'https://www.tiktok.com/@user/video/...\nhttps://vm.tiktok.com/...',
                  hintStyle: AppTypography.bodySmall.copyWith(color: theme.hintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Summary status chips
              if (_controller.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      _buildChip(
                        label: '${_validUrls.length} valid',
                        color: AppColors.success,
                        icon: Icons.check_circle_rounded,
                      ),
                      if (_invalidUrls.isNotEmpty)
                        _buildChip(
                          label: '${_invalidUrls.length} invalid',
                          color: AppColors.error,
                          icon: Icons.error_rounded,
                        ),
                      if (_duplicateCount > 0)
                        _buildChip(
                          label: '$_duplicateCount duplicate${_duplicateCount > 1 ? 's' : ''} removed',
                          color: theme.colorScheme.onSurfaceVariant,
                          icon: Icons.content_copy_rounded,
                        ),
                      if (_validUrls.length >= 20)
                        _buildChip(
                          label: 'Max 20 URLs limit',
                          color: AppColors.warning,
                          icon: Icons.info_rounded,
                        ),
                    ],
                  ),
                ),

              if (_isEnqueuing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: totalCount > 0 ? _processedCount / totalCount : null,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Analyzing and enqueueing $_processedCount of $totalCount...',
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isEnqueuing ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: totalCount > 0 ? 'Download ($totalCount)' : 'Download',
                      icon: Icons.download_rounded,
                      isLoading: _isEnqueuing,
                      onPressed: totalCount > 0 && !_isEnqueuing
                          ? _startBatchDownload
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
