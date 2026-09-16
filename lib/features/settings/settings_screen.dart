import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/file_manager.dart';
import '../../core/storage/storage_permission_handler.dart';
import '../../core/storage/storage_providers.dart';
import '../../shared/widgets/app_card.dart';
import 'settings_provider.dart';

/// Settings screen — full configuration adhering to SRS §11 with Material 3 native grouped cards.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showMaxConcurrentDialog(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Max Concurrent Downloads'),
        children: [1, 2, 3].map((count) {
          final isSelected = count == current;
          return ListTile(
            title: Text('$count ${count == 1 ? 'download' : 'downloads'} at a time'),
            trailing: isSelected
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () {
              ref.read(settingsRepositoryProvider).setMaxConcurrentDownloads(count);
              Navigator.of(ctx).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Appearance Theme'),
        children: [
          _ThemeOptionTile(
            title: 'System default',
            subtitle: 'Follow device system appearance',
            icon: Icons.brightness_auto_rounded,
            isSelected: currentMode == ThemeMode.system,
            onTap: () {
              ref.read(themeModeProvider.notifier).setSystem();
              Navigator.of(ctx).pop();
            },
          ),
          _ThemeOptionTile(
            title: 'Light',
            subtitle: 'Clean bright layout',
            icon: Icons.light_mode_rounded,
            isSelected: currentMode == ThemeMode.light,
            onTap: () {
              ref.read(themeModeProvider.notifier).setLight();
              Navigator.of(ctx).pop();
            },
          ),
          _ThemeOptionTile(
            title: 'Dark',
            subtitle: 'Sleek dark theme',
            icon: Icons.dark_mode_rounded,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () {
              ref.read(themeModeProvider.notifier).setDark();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      final tempDir = await FileManager.getTempDirectory();
      int bytesFreed = 0;
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            bytesFreed += await entity.length();
            await entity.delete();
          }
        }
      }

      final mb = (bytesFreed / (1024 * 1024)).toStringAsFixed(1);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bytesFreed > 0
                  ? 'Cache cleared ($mb MB freed)'
                  : 'Cache is already clean (0 MB)',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear cache')),
        );
      }
    }
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    bool deleteMediaFiles = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Clear History'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure you want to clear your completed downloads list?'),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: deleteMediaFiles,
                  title: const Text(
                    'Also delete downloaded files from device',
                    style: TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setDialogState(() {
                      deleteMediaFiles = val ?? false;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Clear'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(downloadRepositoryProvider).clearHistory(deleteFiles: deleteMediaFiles);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteMediaFiles
                  ? 'History and downloaded media files removed'
                  : 'Download history cleared (files preserved)',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isAmoled = ref.watch(amoledDarkProvider);
    final maxConcurrent = ref.watch(maxConcurrentDownloadsProvider).value ?? 1;
    final autoClipboard = ref.watch(autoClipboardProvider).value ?? true;
    final notifications = ref.watch(notificationsEnabledProvider).value ?? true;

    final bool isLightMode = themeMode == ThemeMode.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.huge + 40,
          ),
          children: [
            // ── Downloads ─────────────────────────────────────────────────
            const _SectionHeader(title: 'Downloads'),
            _SettingsGroup(
              children: [
                _M3ListTile(
                  title: 'Max concurrent downloads',
                  subtitle: '$maxConcurrent ${maxConcurrent == 1 ? 'download' : 'downloads'} at a time',
                  leadingIcon: Icons.speed_rounded,
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => _showMaxConcurrentDialog(context, ref, maxConcurrent),
                ),
                const _TileDivider(),
                _M3SwitchListTile(
                  title: 'Auto-detect clipboard links',
                  subtitle: 'Suggest download when app opens with a copied TikTok link',
                  leadingIcon: Icons.content_paste_rounded,
                  value: autoClipboard,
                  onChanged: (val) {
                    ref.read(settingsRepositoryProvider).setAutoClipboard(val);
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Appearance ────────────────────────────────────────────────
            const _SectionHeader(title: 'Appearance'),
            _SettingsGroup(
              children: [
                _M3ListTile(
                  title: 'Theme',
                  subtitle: switch (themeMode) {
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                    ThemeMode.system => 'System default',
                  },
                  leadingIcon: switch (themeMode) {
                    ThemeMode.light => Icons.light_mode_rounded,
                    ThemeMode.dark => Icons.dark_mode_rounded,
                    ThemeMode.system => Icons.brightness_auto_rounded,
                  },
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => _showThemeDialog(context, ref, themeMode),
                ),
                const _TileDivider(),
                _M3SwitchListTile(
                  title: 'Pure Black (AMOLED)',
                  subtitle: isLightMode
                      ? 'Only active in Dark theme'
                      : 'Pitch black surfaces for OLED battery saving',
                  leadingIcon: Icons.brightness_2_outlined,
                  value: isLightMode ? false : isAmoled,
                  enabled: !isLightMode,
                  onChanged: isLightMode
                      ? null
                      : (val) {
                          ref.read(amoledDarkProvider.notifier).setEnabled(val);
                        },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Notifications ─────────────────────────────────────────────
            const _SectionHeader(title: 'Notifications'),
            _SettingsGroup(
              children: [
                _M3SwitchListTile(
                  title: 'Download notifications',
                  subtitle: 'Show progress and status in system notification bar',
                  leadingIcon: Icons.notifications_outlined,
                  value: notifications,
                  onChanged: (val) async {
                    if (val) {
                      await StoragePermissionHandler.requestNotificationPermission();
                    }
                    ref.read(settingsRepositoryProvider).setNotificationsEnabled(val);
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Privacy & Storage ─────────────────────────────────────────
            const _SectionHeader(title: 'Storage & History'),
            _StorageAnalyticsCard(onClearCache: () => _clearCache(context)),
            const SizedBox(height: AppSpacing.sm),
            _SettingsGroup(
              children: [
                _M3ListTile(
                  title: 'Clear history',
                  subtitle: 'Manage or remove downloaded history records',
                  leadingIcon: Icons.history_rounded,
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => _clearHistory(context, ref),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Support Development ───────────────────────────────────────
            const _SectionHeader(title: 'Support'),
            _SettingsGroup(
              children: [
                _M3ListTile(
                  title: 'Support Development',
                  subtitle: '100% ad-free, no tracking, and privacy-first.',
                  leadingIcon: Icons.favorite_outline_rounded,
                  leadingColor: AppColors.error,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for your support! Optional tip jar coming soon.')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── About ─────────────────────────────────────────────────────
            const _SectionHeader(title: 'About'),
            _SettingsGroup(
              children: [
                _M3ListTile(
                  title: AppConstants.appName,
                  subtitle: 'v1.0.0 · ${AppConstants.developerName}',
                  leadingIcon: Icons.info_outline_rounded,
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: '1.0.0 (Build 1)',
                      applicationLegalese: '© 2026 ${AppConstants.developerName}. All rights reserved.',
                      children: const [
                        SizedBox(height: AppSpacing.md),
                        Text('A clean, private, ad-free TikTok video & audio downloader built for Android.'),
                      ],
                    );
                  },
                ),
                const _TileDivider(),
                _M3ListTile(
                  title: 'Open Source Licenses',
                  leadingIcon: Icons.article_outlined,
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => showLicensePage(context: context),
                ),
                const _TileDivider(),
                _M3ListTile(
                  title: 'TikTok Disclaimer',
                  subtitle: 'Independent utility not affiliated with TikTok or ByteDance.',
                  leadingIcon: Icons.gavel_outlined,
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Legal Disclaimer'),
                        content: const Text(
                          'TikTok is a registered trademark of ByteDance Ltd.\n\n'
                          'TokSaver is an independent utility created to download videos '
                          'for personal offline viewing. Please respect intellectual property and the copyright '
                          'of original content creators.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

/// Material 3 Grouped Settings Container with anti-alias clipping and consistent surface styling.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// Material 3 Interactive ListTile with native hover, splash, and cursor states.
class _M3ListTile extends StatelessWidget {
  const _M3ListTile({
    required this.title,
    this.subtitle,
    required this.leadingIcon,
    this.leadingColor,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final Color? leadingColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(
        leadingIcon,
        size: 22,
        color: leadingColor ?? (isDark ? const Color(0xFFB0B0C0) : const Color(0xFF505060)),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontSize: 12.5,
              ),
            )
          : null,
      trailing: trailing,
      mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      onTap: onTap,
    );
  }
}

/// Material 3 Switch List Tile with native switch track and thumb tokens.
class _M3SwitchListTile extends StatelessWidget {
  const _M3SwitchListTile({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      secondary: Icon(
        leadingIcon,
        size: 22,
        color: !enabled
            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35)
            : (isDark ? const Color(0xFFB0B0C0) : const Color(0xFF505060)),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: !enabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: !enabled
              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          fontSize: 12.5,
        ),
      ),
      value: value,
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: isDark ? const Color(0xFF282830) : const Color(0xFFE2E2E6),
      inactiveThumbColor: isDark ? const Color(0xFF9090A0) : const Color(0xFF888894),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return isDark ? Colors.white12 : Colors.black12;
      }),
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// Symmetrical Material 3 Inset Divider.
class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 54,
      endIndent: 16,
      color: theme.dividerColor.withValues(alpha: 0.35),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
      mouseCursor: SystemMouseCursors.click,
      hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs + 2,
        top: AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StorageAnalyticsCard extends ConsumerWidget {
  const _StorageAnalyticsCard({required this.onClearCache});

  final VoidCallback onClearCache;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyStream = ref.watch(completedDownloadsStreamProvider);

    return historyStream.when(
      data: (tasks) {
        int videoBytes = 0;
        int audioBytes = 0;

        for (final t in tasks) {
          if (t.isAudioOnly) {
            audioBytes += t.totalBytes;
          } else {
            videoBytes += t.totalBytes;
          }
        }

        final totalBytes = videoBytes + audioBytes;
        final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
        final videoMb = (videoBytes / (1024 * 1024)).toStringAsFixed(1);
        final audioMb = (audioBytes / (1024 * 1024)).toStringAsFixed(1);

        final videoRatio = totalBytes > 0 ? (videoBytes / totalBytes) : 0.0;
        final audioRatio = totalBytes > 0 ? (audioBytes / totalBytes) : 0.0;

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Storage Usage', style: AppTypography.titleMedium),
                  Text(
                    '$totalMb MB Used',
                    style: AppTypography.mono.copyWith(
                      color: totalBytes > 0 ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Segmented visual bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  height: 8,
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  child: totalBytes > 0
                      ? Row(
                          children: [
                            if (videoBytes > 0)
                              Expanded(
                                flex: (videoRatio * 100).round().clamp(1, 100),
                                child: Container(color: AppColors.primary),
                              ),
                            if (audioBytes > 0)
                              Expanded(
                                flex: (audioRatio * 100).round().clamp(1, 100),
                                child: Container(color: AppColors.warning),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: videoBytes > 0 ? AppColors.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Videos ($videoMb MB)', style: AppTypography.labelSmall),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: audioBytes > 0 ? AppColors.warning : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Audio ($audioMb MB)', style: AppTypography.labelSmall),
                    ],
                  ),
                  Material(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      hoverColor: AppColors.primary.withValues(alpha: 0.18),
                      splashColor: AppColors.primary.withValues(alpha: 0.28),
                      mouseCursor: SystemMouseCursors.click,
                      onTap: onClearCache,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(
                          'Clean Cache',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
