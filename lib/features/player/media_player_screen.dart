import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/storage/download_storage_service.dart';
import '../../core/utils/pip_service.dart';
import '../../shared/models/download_task.dart';
import 'widgets/player_controls_overlay.dart';

/// Built-in in-app media player screen with double-tap seek & vertical swipe HUD gestures.
class MediaPlayerScreen extends ConsumerStatefulWidget {
  const MediaPlayerScreen({
    super.key,
    required this.task,
  });

  final DownloadTask task;

  @override
  ConsumerState<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends ConsumerState<MediaPlayerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  bool _showControls = true;
  bool _isInPip = false;
  Timer? _hideTimer;
  bool _isLooping = false;
  double _playbackSpeed = 1.0;

  // ── Gesture & HUD State ───────────────────────────────────────────────────
  double _volume = 1.0;
  double _brightness = 0.5; // Virtual brightness overlay
  bool _showVolumeHud = false;
  bool _showBrightnessHud = false;
  Timer? _hudTimer;

  bool _showLeftSeekRipple = false;
  bool _showRightSeekRipple = false;
  Timer? _seekRippleTimer;

  StreamSubscription<bool>? _pipSubscription;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _pipSubscription = PipService.instance.onPipModeChanged.listen((inPip) {
      if (mounted) {
        setState(() {
          _isInPip = inPip;
          if (inPip) {
            _showControls = false;
            _hideTimer?.cancel();
          } else {
            _showControls = true;
            _startHideTimer();
          }
        });
      }
    });

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final task = widget.task;
      final uriStr = task.storageUri;
      final filePath = task.targetFilePath;

      VideoPlayerController controller;

      if (uriStr != null && uriStr.startsWith('content://')) {
        controller = VideoPlayerController.contentUri(Uri.parse(uriStr));
      } else if (filePath.isNotEmpty && File(filePath).existsSync()) {
        controller = VideoPlayerController.file(File(filePath));
      } else {
        controller = VideoPlayerController.contentUri(Uri.parse(task.canonicalUri));
      }

      _controller = controller;

      await controller.initialize();
      controller.addListener(_playerListener);
      await controller.setLooping(_isLooping);
      await controller.setPlaybackSpeed(_playbackSpeed);
      await controller.setVolume(_volume);
      await controller.play();

      if (widget.task.isAudioOnly) {
        _rotationController.repeat();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startHideTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not load media file: $e';
        });
      }
    }
  }

  void _playerListener() {
    if (!mounted) return;
    final isPlaying = _controller?.value.isPlaying ?? false;
    if (widget.task.isAudioOnly) {
      if (isPlaying && !_rotationController.isAnimating) {
        _rotationController.repeat();
      } else if (!isPlaying && _rotationController.isAnimating) {
        _rotationController.stop();
      }
    }
    setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_isInPip) return;
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    if (c.value.position >= c.value.duration && c.value.duration.inMilliseconds > 0) {
      c.seekTo(Duration.zero);
      c.play();
    } else if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    _startHideTimer();
  }

  void _seekRelative(Duration delta) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    final target = c.value.position + delta;
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, c.value.duration.inMilliseconds),
    );
    c.seekTo(clamped);
    _startHideTimer();
  }

  void _triggerDoubleTapSeek(bool isRight) {
    _seekRelative(Duration(seconds: isRight ? 10 : -10));
    _seekRippleTimer?.cancel();
    setState(() {
      if (isRight) {
        _showRightSeekRipple = true;
        _showLeftSeekRipple = false;
      } else {
        _showLeftSeekRipple = true;
        _showRightSeekRipple = false;
      }
    });
    _seekRippleTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showLeftSeekRipple = false;
          _showRightSeekRipple = false;
        });
      }
    });
  }

  void _handleVerticalDrag(DragUpdateDetails details, BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final isRightSide = details.globalPosition.dx > screenWidth / 2;
    final delta = -details.primaryDelta! / 200.0;

    _hudTimer?.cancel();

    if (isRightSide) {
      // Adjust Volume
      final newVol = (_volume + delta).clamp(0.0, 1.0);
      setState(() {
        _volume = newVol;
        _showVolumeHud = true;
        _showBrightnessHud = false;
      });
      _controller?.setVolume(newVol);
    } else {
      // Adjust Brightness
      final newBright = (_brightness + delta).clamp(0.0, 1.0);
      setState(() {
        _brightness = newBright;
        _showBrightnessHud = true;
        _showVolumeHud = false;
      });
    }

    _hudTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showVolumeHud = false;
          _showBrightnessHud = false;
        });
      }
    });
  }

  Future<void> _toggleLoop() async {
    final next = !_isLooping;
    setState(() => _isLooping = next);
    await _controller?.setLooping(next);
    _startHideTimer();
  }

  Future<void> _setSpeed(double speed) async {
    setState(() => _playbackSpeed = speed);
    await _controller?.setPlaybackSpeed(speed);
    _startHideTimer();
  }

  Future<void> _enterPip() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    final size = c.value.size;
    final width = size.width > 0 ? size.width.toInt() : 9;
    final height = size.height > 0 ? size.height.toInt() : 16;

    await PipService.instance.enterPictureInPicture(
      numerator: width,
      denominator: height,
    );
  }

  Future<void> _setAsRingtone() async {
    final task = widget.task;
    final uri = task.storageUri ?? task.targetFilePath;
    final success = await PipService.instance.setAsRingtone(
      uri: uri,
      title: task.title,
      mimeType: task.mimeType,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Ringtone picker opened.'
                : 'Unable to set ringtone or feature unsupported.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareMedia() async {
    final storage = ref.read(downloadStorageServiceProvider);
    final task = widget.task;
    final mime = task.mimeType ?? (task.isAudioOnly ? 'audio/mpeg' : 'video/mp4');

    await storage.shareFile(
      storageUri: task.storageUri ?? task.targetFilePath,
      mimeType: mime,
      title: task.title,
      storageType: task.storageType,
      filePath: task.targetFilePath,
    );
  }

  Future<void> _openExternalApp() async {
    final storage = ref.read(downloadStorageServiceProvider);
    final task = widget.task;
    final mime = task.mimeType ?? (task.isAudioOnly ? 'audio/mpeg' : 'video/mp4');

    await storage.openFile(
      storageUri: task.storageUri ?? task.targetFilePath,
      mimeType: mime,
      title: task.title,
      storageType: task.storageType,
      filePath: task.targetFilePath,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hudTimer?.cancel();
    _seekRippleTimer?.cancel();
    _pipSubscription?.cancel();
    _rotationController.dispose();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isAudio = task.isAudioOnly;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Media Content ──────────────────────────────────────────
              if (_hasError)
                _buildErrorState()
              else if (!_isInitialized || _controller == null)
                _buildLoadingState()
              else if (isAudio)
                _buildAudioView()
              else
                _buildVideoView(constraints),

              // ── Brightness Overlay Simulator ───────────────────────────
              if (!isAudio && _brightness < 0.5)
                IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: (0.5 - _brightness) * 1.5),
                  ),
                ),

              // ── Fast Seek Double-Tap Badges ────────────────────────────
              if (_showLeftSeekRipple)
                Positioned(
                  left: 40,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildSeekBadge(icon: Icons.fast_rewind_rounded, text: '-10s'),
                  ),
                ),
              if (_showRightSeekRipple)
                Positioned(
                  right: 40,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildSeekBadge(icon: Icons.fast_forward_rounded, text: '+10s'),
                  ),
                ),

              // ── Volume & Brightness HUD ────────────────────────────────
              if (_showVolumeHud)
                Center(
                  child: _buildHudOverlay(
                    icon: _volume == 0
                        ? Icons.volume_off_rounded
                        : _volume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded,
                    value: _volume,
                    label: 'Volume',
                  ),
                ),
              if (_showBrightnessHud)
                Center(
                  child: _buildHudOverlay(
                    icon: Icons.brightness_6_rounded,
                    value: _brightness,
                    label: 'Brightness',
                  ),
                ),

              // ── Controls Overlay ───────────────────────────────────────
              if (_isInitialized && _controller != null && !_hasError && !_isInPip)
                PlayerControlsOverlay(
                  controller: _controller!,
                  title: task.title,
                  author: task.author,
                  isAudio: isAudio,
                  isVisible: _showControls,
                  isLooping: _isLooping,
                  playbackSpeed: _playbackSpeed,
                  onTogglePlayPause: _togglePlayPause,
                  onToggleControls: _toggleControls,
                  onToggleLoop: _toggleLoop,
                  onSpeedSelected: _setSpeed,
                  onShare: _shareMedia,
                  onOpenExternal: _openExternalApp,
                  onBack: () => Navigator.of(context).pop(),
                  onSeekBackward: () => _seekRelative(const Duration(seconds: -10)),
                  onSeekForward: () => _seekRelative(const Duration(seconds: 10)),
                  onEnterPip: !isAudio ? _enterPip : null,
                  onSetRingtone: isAudio ? _setAsRingtone : null,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeekBadge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudOverlay({
    required IconData icon,
    required double value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 36),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(value * 100).toInt()}%',
            style: AppTypography.monoSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 54),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Playback Error',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage ?? 'Unable to play this media file.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: _initializePlayer,
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open in External App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _openExternalApp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView(BoxConstraints constraints) {
    final controller = _controller!;
    final size = controller.value.size;
    final aspectRatio = (size.width > 0 && size.height > 0)
        ? size.width / size.height
        : controller.value.aspectRatio;

    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTapDown: (details) {
        final screenWidth = constraints.maxWidth;
        final isRight = details.localPosition.dx > screenWidth / 2;
        _triggerDoubleTapSeek(isRight);
      },
      onVerticalDragUpdate: (details) => _handleVerticalDrag(details, constraints),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio > 0 ? aspectRatio : (9 / 16),
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildAudioView() {
    final task = widget.task;
    final thumb = task.thumbnailUrl;

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              AppColors.surfaceDark,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vinyl Record Disc
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF141418),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 35,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.white12, width: 4),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vinyl Grooves
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 1.5),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 1.5),
                        ),
                      ),
                      // Center Artwork / Icon
                      ClipOval(
                        child: thumb != null && thumb.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: thumb,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  color: AppColors.primary,
                                  child: const Icon(Icons.music_note_rounded, size: 36, color: Colors.black),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  color: AppColors.primary,
                                  child: const Icon(Icons.music_note_rounded, size: 36, color: Colors.black),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: AppColors.primary,
                                child: const Icon(Icons.music_note_rounded, size: 36, color: Colors.black),
                              ),
                      ),
                      // Spindle Hole
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Track Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (task.author.isNotEmpty)
                      Text(
                        '@${task.author}',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Audio (MP3) • ${task.formattedTotalSize}',
                      style: AppTypography.monoSmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
