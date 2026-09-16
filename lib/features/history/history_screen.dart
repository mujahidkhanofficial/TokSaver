import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/storage/storage_providers.dart';
import '../../shared/models/download_task.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedTaskIds = {};
  bool _isSelectionMode = false;
  String _selectedFilter = 'all'; // 'all', 'video', 'audio', 'photos'
  String? _selectedCreator; // '@creator' or null for all

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String taskId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedTaskIds.add(taskId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<DownloadTask> tasks) {
    setState(() {
      _selectedTaskIds.addAll(tasks.map((t) => t.id));
      _isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTaskIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selectedTaskIds.length} item(s)?'),
        content: const Text(
          'This will remove the download record and associated file from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(downloadRepositoryProvider);
      for (final id in _selectedTaskIds) {
        await repository.deleteTask(id, deleteFile: true);
      }
      _clearSelection();
    }
  }

  Future<void> _exportHistory() async {
    final repository = ref.read(downloadRepositoryProvider);
    final jsonString = await repository.exportHistoryJson();

    await SharePlus.instance.share(
      ShareParams(
        text: jsonString,
        subject: 'TokSaver_History_Backup.json',
      ),
    );
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import History Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste the JSON history backup string below to restore records:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              maxLines: 5,
              style: AppTypography.monoSmall.copyWith(fontSize: 11),
              decoration: const InputDecoration(
                hintText: '{\n  "version": 1,\n  "tasks": [...]\n}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                final repo = ref.read(downloadRepositoryProvider);
                final count = await repo.importHistoryJson(text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Successfully imported $count items.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Import failed: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _openFile(DownloadTask task) {
    final isImage = task.mimeType?.startsWith('image/') ?? false;
    if (isImage) {
      context.push(AppRoutes.photoGallery, extra: task);
    } else {
      context.push(AppRoutes.player, extra: task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(completedDownloadsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedTaskIds.length} Selected')
            : const Text('Download History'),
        centerTitle: !_isSelectionMode,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            historyAsync.maybeWhen(
              data: (tasks) => IconButton(
                icon: const Icon(Icons.select_all_rounded),
                tooltip: 'Select All',
                onPressed: () => _selectAll(tasks),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Selected',
              color: AppColors.error,
              onPressed: _deleteSelected,
            ),
          ] else ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              color: AppColors.surfaceDark,
              onSelected: (val) {
                if (val == 'export') _exportHistory();
                if (val == 'import') _showImportDialog();
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_rounded, size: 20, color: Colors.white),
                      SizedBox(width: AppSpacing.sm),
                      Text('Export History Backup', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.file_download_outlined, size: 20, color: Colors.white),
                      SizedBox(width: AppSpacing.sm),
                      Text('Import History Backup', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: historyAsync.when(
        data: (allTasks) {
          if (allTasks.isEmpty) {
            return _buildEmptyState(context);
          }

          // Extract unique creators
          final creators = allTasks
              .map((t) => t.author.trim())
              .where((a) => a.isNotEmpty)
              .toSet()
              .toList();

          // Filter by search query
          final query = _searchController.text.trim().toLowerCase();
          var filtered = allTasks.where((t) {
            final matchesQuery = query.isEmpty ||
                t.title.toLowerCase().contains(query) ||
                t.author.toLowerCase().contains(query);

            final isImage = t.mimeType?.startsWith('image/') ?? false;
            final matchesType = switch (_selectedFilter) {
              'video' => !t.isAudioOnly && !isImage,
              'audio' => t.isAudioOnly,
              'photos' => isImage,
              _ => true,
            };

            final matchesCreator =
                _selectedCreator == null || t.author.trim() == _selectedCreator;

            return matchesQuery && matchesType && matchesCreator;
          }).toList();

          return CustomScrollView(
            slivers: [
              // ── Search & Filter Bars ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.sm,
                    AppSpacing.pagePadding,
                    AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _searchController,
                        hint: 'Search downloaded titles, tags, @creator...',
                        prefix: const Icon(Icons.search_rounded, size: 20),
                        suffix: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Media Type Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterPill(
                              label: 'All (${allTasks.length})',
                              isSelected: _selectedFilter == 'all',
                              onTap: () => setState(() => _selectedFilter = 'all'),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _FilterPill(
                              label: 'Videos',
                              isSelected: _selectedFilter == 'video',
                              onTap: () => setState(() => _selectedFilter = 'video'),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _FilterPill(
                              label: 'Audio (MP3)',
                              isSelected: _selectedFilter == 'audio',
                              onTap: () => setState(() => _selectedFilter = 'audio'),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _FilterPill(
                              label: 'Photos',
                              isSelected: _selectedFilter == 'photos',
                              onTap: () => setState(() => _selectedFilter = 'photos'),
                            ),
                          ],
                        ),
                      ),
                      // Creator Filter Chips (if multiple creators exist)
                      if (creators.length > 1) ...[
                        const SizedBox(height: AppSpacing.xs),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _CreatorChip(
                                label: 'All Creators',
                                isSelected: _selectedCreator == null,
                                onTap: () => setState(() => _selectedCreator = null),
                              ),
                              ...creators.map((c) => Padding(
                                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                                    child: _CreatorChip(
                                      label: '@$c',
                                      isSelected: _selectedCreator == c,
                                      onTap: () => setState(() => _selectedCreator = c),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Items Grid ────────────────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No matching history items.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filtered[index];
                        return _buildGridItem(context, task);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading history: $err')),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, DownloadTask task) {
    final theme = Theme.of(context);
    final isSelected = _selectedTaskIds.contains(task.id);
    final isImage = task.mimeType?.startsWith('image/') ?? false;

    return AppCard(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(task.id);
        } else {
          _openFile(task);
        }
      },
      onLongPress: () => _toggleSelection(task.id),
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          task.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: task.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      task.isAudioOnly
                          ? Icons.music_note_rounded
                          : isImage
                              ? Icons.photo_library_rounded
                              : Icons.movie_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 40,
                    ),
                  ),
                )
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    task.isAudioOnly
                        ? Icons.music_note_rounded
                        : isImage
                            ? Icons.photo_library_rounded
                            : Icons.movie_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 40,
                  ),
                ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                task.isAudioOnly ? 'MP3' : (isImage ? 'PHOTO' : (task.hasWatermark ? 'WM' : 'HD')),
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: task.isAudioOnly
                      ? AppColors.warning
                      : isImage
                          ? AppColors.success
                          : AppColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: _isSelectionMode
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.black45,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  )
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: Icon(
                      isImage ? Icons.zoom_in_rounded : Icons.play_arrow_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
          Positioned(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.title,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${task.author} • ${task.formattedTotalSize}',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
                Icons.history_rounded,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No download history', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Videos, photos, and audio tracks you download will be saved here for easy offline playback and sharing.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Explore & Download',
              icon: Icons.search_rounded,
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatorChip extends StatelessWidget {
  const _CreatorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected
          ? AppColors.primary.withValues(alpha: 0.15)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.transparent,
        width: 1,
      ),
      onPressed: onTap,
    );
  }
}
