import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/utils/share_intent_service.dart';
import '../../core/utils/url_validator.dart';
import '../../shared/models/download_task.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';
import '../analyzer/analyzer_provider.dart';
import 'widgets/batch_download_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  String? _detectedClipboardUrl;
  bool _isCheckingClipboard = false;

  late final AnimationController _animController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _recentFade;
  late final Animation<Offset> _recentSlide;
  late final Animation<double> _tipsFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ));

    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
    ));

    _recentFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );
    _recentSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
    ));

    _tipsFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
      _initShareIntentListener();
    });
  }

  void _initShareIntentListener() {
    ShareIntentService.instance.initialize(
      onUrlReceived: (sharedUrl) {
        if (mounted) {
          context.push(AppRoutes.videoDetail, extra: sharedUrl);
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    if (_isCheckingClipboard) return;
    final isAutoEnabled = ref.read(autoClipboardProvider).value ?? true;
    if (!isAutoEnabled) return;

    _isCheckingClipboard = true;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();

      if (text != null && text.isNotEmpty) {
        final extracted = UrlValidator.extractFirstUrl(text);
        if (extracted != null &&
            UrlValidator.isValidTikTokUrl(extracted) &&
            extracted != _detectedClipboardUrl &&
            extracted != _urlController.text.trim()) {
          setState(() {
            _detectedClipboardUrl = extracted;
          });
        }
      }
    } catch (_) {
      // Ignore clipboard access errors
    } finally {
      _isCheckingClipboard = false;
    }
  }

  void _analyzeUrl(String url) {
    final clean = UrlValidator.cleanTrackingParameters(url.trim());
    if (clean.isEmpty) return;

    ref.read(analyzerStateProvider.notifier).reset();
    context.push(AppRoutes.videoDetail, extra: clean);
  }

  void _pasteFromClipboard() async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      final extracted = UrlValidator.extractFirstUrl(text) ?? text;
      _urlController.text = extracted;
      if (UrlValidator.isValidTikTokUrl(extracted)) {
        _analyzeUrl(extracted);
      }
    }
  }

  void _showBatchDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => const BatchDownloadDialog(),
    );
  }

  void _openDownloadedFile(DownloadTask task) {
    HapticFeedback.selectionClick();
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
    final isDark = theme.brightness == Brightness.dark;
    final completedDownloads = ref.watch(completedDownloadsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.mintAccent],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            RichText(
              text: TextSpan(
                style: AppTypography.titleLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                children: const [
                  TextSpan(text: 'Tok'),
                  TextSpan(
                    text: 'Saver',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.dynamic_feed_rounded),
            tooltip: 'Batch Multi-Link',
            onPressed: _showBatchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        children: [
          // ── Hero Banner & Quick Actions ───────────────────────────────
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    _QuickActionPill(
                      icon: Icons.paste_rounded,
                      label: 'Paste Link',
                      onTap: _pasteFromClipboard,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _QuickActionPill(
                      icon: Icons.dynamic_feed_rounded,
                      label: 'Batch Multi-Link',
                      onTap: _showBatchDialog,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _QuickActionPill(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => context.go(AppRoutes.history),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Clipboard Detection Banner ────────────────────────────────
          if (_detectedClipboardUrl != null) ...[
            _ClipboardBanner(
              url: _detectedClipboardUrl!,
              onUse: () {
                final url = _detectedClipboardUrl!;
                setState(() => _detectedClipboardUrl = null);
                _urlController.text = url;
                _analyzeUrl(url);
              },
              onDismiss: () {
                setState(() => _detectedClipboardUrl = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── URL Input Card ────────────────────────────────────────────
          FadeTransition(
            opacity: _cardFade,
            child: SlideTransition(
              position: _cardSlide,
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                color: isDark ? const Color(0xFF16161D) : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Download TikTok Media',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'HD Videos, MP3 Audio & Photo Slideshows',
                                style: AppTypography.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _urlController,
                      hint: 'Paste TikTok link (e.g. https://vm.tiktok.com/...)',
                      prefix: const Icon(Icons.link_rounded, size: 20),
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_urlController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => _urlController.clear(),
                            ),
                          IconButton(
                            icon: const Icon(Icons.paste_rounded, size: 20),
                            tooltip: 'Paste from clipboard',
                            onPressed: _pasteFromClipboard,
                          ),
                        ],
                      ),
                      onSubmitted: (val) {
                        if (UrlValidator.isValidTikTokUrl(val)) {
                          _analyzeUrl(val);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppButton(
                            label: 'Analyze & Download',
                            icon: Icons.search_rounded,
                            onPressed: () {
                              final text = _urlController.text.trim();
                              if (text.isNotEmpty) {
                                _analyzeUrl(text);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.dynamic_feed_rounded, size: 18),
                            label: const Text('Batch'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                                horizontal: AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: _showBatchDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Recent Downloads Section ──────────────────────────────────
          FadeTransition(
            opacity: _recentFade,
            child: SlideTransition(
              position: _recentSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Downloads',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.history),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  completedDownloads.when(
                    data: (allCompleted) {
                      final recent = allCompleted.take(4).toList();
                      if (recent.isEmpty) {
                        return _buildNoRecentDownloads(context);
                      }
                      return Column(
                        children: recent.map((t) => _buildRecentItem(context, t)).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Quick Guide / Tips ────────────────────────────────────────
          FadeTransition(
            opacity: _tipsFade,
            child: _buildQuickTips(context),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildNoRecentDownloads(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.movie_outlined,
            size: 38,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No downloads yet — paste a link above to start',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(BuildContext context, DownloadTask task) {
    final theme = Theme.of(context);
    final isImage = task.mimeType?.startsWith('image/') ?? false;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => _openDownloadedFile(task),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: SizedBox(
              width: 52,
              height: 52,
              child: task.thumbnailUrl != null
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
                          size: 24,
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
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.title,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${task.author} • ${task.formattedTotalSize}',
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isImage ? Icons.zoom_in_rounded : Icons.play_circle_outline_rounded,
            ),
            color: theme.colorScheme.primary,
            onPressed: () => _openDownloadedFile(task),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('How to Download', style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _TipStep(step: '1', text: 'Open TikTok and tap "Share" on any video.'),
          const _TipStep(step: '2', text: 'Tap "Copy Link" or tap TokSaver directly in share sheet.'),
          const _TipStep(step: '3', text: 'TokSaver receives and analyzes the highest quality stream.'),
          const _TipStep(step: '4', text: 'Select HD Video, Photos, or MP3 Audio and tap Download.'),
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B24) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClipboardBanner extends StatelessWidget {
  const _ClipboardBanner({
    required this.url,
    required this.onUse,
    required this.onDismiss,
  });

  final String url;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.content_paste_rounded, color: theme.colorScheme.onPrimaryContainer, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TikTok Link Detected in Clipboard',
                  style: AppTypography.labelMedium.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  url,
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUse,
            child: const Text('Download'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDismiss,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}

class _TipStep extends StatelessWidget {
  const _TipStep({required this.step, required this.text});
  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: AppTypography.monoSmall.copyWith(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
