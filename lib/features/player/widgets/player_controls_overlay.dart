import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class PlayerControlsOverlay extends StatelessWidget {
  const PlayerControlsOverlay({
    super.key,
    required this.controller,
    required this.title,
    required this.author,
    required this.isAudio,
    required this.isVisible,
    required this.isLooping,
    required this.playbackSpeed,
    required this.onTogglePlayPause,
    required this.onToggleControls,
    required this.onToggleLoop,
    required this.onSpeedSelected,
    required this.onShare,
    required this.onOpenExternal,
    required this.onBack,
    required this.onSeekBackward,
    required this.onSeekForward,
    this.onEnterPip,
    this.onSetRingtone,
  });

  final VideoPlayerController controller;
  final String title;
  final String author;
  final bool isAudio;
  final bool isVisible;
  final bool isLooping;
  final double playbackSpeed;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onToggleControls;
  final VoidCallback onToggleLoop;
  final ValueChanged<double> onSpeedSelected;
  final VoidCallback onShare;
  final VoidCallback onOpenExternal;
  final VoidCallback onBack;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;
  final VoidCallback? onEnterPip;
  final VoidCallback? onSetRingtone;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _showSpeedPicker(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Playback Speed',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...speeds.map((s) => ListTile(
                    title: Text(
                      '${s}x',
                      style: AppTypography.labelLarge.copyWith(
                        color: playbackSpeed == s ? AppColors.primary : Colors.white,
                        fontWeight: playbackSpeed == s ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: playbackSpeed == s
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      onSpeedSelected(s);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final position = value.position;
    final duration = value.duration;
    final isPlaying = value.isPlaying;
    final isEnded = position >= duration && duration.inMilliseconds > 0;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: GestureDetector(
          onTap: onToggleControls,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Top Navigation Bar ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          tooltip: 'Back',
                          onPressed: onBack,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (author.isNotEmpty)
                                Text(
                                  '@$author',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // PiP Button for Video
                        if (!isAudio && onEnterPip != null)
                          IconButton(
                            icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
                            tooltip: 'Picture-in-Picture',
                            onPressed: onEnterPip,
                          ),
                        // Ringtone Button for Audio
                        if (isAudio && onSetRingtone != null)
                          IconButton(
                            icon: const Icon(Icons.ring_volume_rounded, color: Colors.white),
                            tooltip: 'Set as Ringtone',
                            onPressed: onSetRingtone,
                          ),
                        // Share Button
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.white),
                          tooltip: 'Share',
                          onPressed: onShare,
                        ),
                        // External App Overflow
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                          color: AppColors.surfaceDark,
                          onSelected: (action) {
                            if (action == 'external') onOpenExternal();
                            if (action == 'ringtone' && onSetRingtone != null) onSetRingtone!();
                          },
                          itemBuilder: (ctx) => [
                            if (isAudio && onSetRingtone != null)
                              const PopupMenuItem(
                                value: 'ringtone',
                                child: Row(
                                  children: [
                                    Icon(Icons.ring_volume_rounded, size: 20, color: Colors.white),
                                    SizedBox(width: AppSpacing.sm),
                                    Text('Set as Ringtone', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'external',
                              child: Row(
                                children: [
                                  Icon(Icons.open_in_new_rounded, size: 20, color: Colors.white),
                                  SizedBox(width: AppSpacing.sm),
                                  Text('Open in Gallery / External App', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Center Controls ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rewind 10s
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                          tooltip: 'Rewind 10s',
                          onPressed: onSeekBackward,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      // Big Play / Pause / Replay Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onTogglePlayPause,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Icon(
                                isEnded
                                    ? Icons.replay_rounded
                                    : isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                size: 44,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      // Forward 10s
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                          tooltip: 'Forward 10s',
                          onPressed: onSeekForward,
                        ),
                      ),
                    ],
                  ),

                  // ── Bottom Scrubber & Quick Actions ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Slider Bar
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: position.inMilliseconds
                                .toDouble()
                                .clamp(0.0, duration.inMilliseconds.toDouble()),
                            max: duration.inMilliseconds > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0,
                            onChanged: (val) {
                              controller.seekTo(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                        // Time Display & Controls Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                              style: AppTypography.monoSmall.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Speed badge button
                                InkWell(
                                  onTap: () => _showSpeedPicker(context),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs + 2,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      '${playbackSpeed}x',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                // Loop Toggle
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  icon: Icon(
                                    isLooping ? Icons.repeat_one_on_rounded : Icons.repeat_rounded,
                                    color: isLooping ? AppColors.primary : Colors.white70,
                                    size: 20,
                                  ),
                                  tooltip: isLooping ? 'Looping On' : 'Loop Off',
                                  onPressed: onToggleLoop,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
