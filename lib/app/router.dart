import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/analyzer/video_detail_screen.dart';
import '../features/player/media_player_screen.dart';
import '../features/player/photo_gallery_screen.dart';
import '../shared/models/download_task.dart';
import '../shared/widgets/nav_shell.dart';

/// Route name constants — never use raw strings.
abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String videoDetail = '/video-detail';
  static const String downloads = '/downloads';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String player = '/player';
  static const String photoGallery = '/photo-gallery';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: true,
  routes: [
    // ── Shell with bottom nav ───────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          NavShell(navigationShell: navigationShell),
      branches: [
        // Tab 0 — Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 1 — Downloads
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.downloads,
              name: 'downloads',
              builder: (context, state) => const DownloadsScreen(),
            ),
          ],
        ),
        // Tab 2 — History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.history,
              name: 'history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        // Tab 3 — Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Modal routes (outside nav shell) ─────────────────────────────────
    GoRoute(
      path: AppRoutes.videoDetail,
      name: 'videoDetail',
      pageBuilder: (context, state) {
        String? url;
        dynamic metadata;
        if (state.extra is String) {
          url = state.extra as String;
        } else if (state.extra != null) {
          metadata = state.extra;
        } else {
          url = state.uri.queryParameters['url'];
        }

        return CustomTransitionPage(
          key: state.pageKey,
          child: VideoDetailScreen(
            url: url,
            initialMetadata: metadata,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    ),

    // Built-in Video & Audio Player route
    GoRoute(
      path: AppRoutes.player,
      name: 'player',
      pageBuilder: (context, state) {
        final task = state.extra as DownloadTask;
        return CustomTransitionPage(
          key: state.pageKey,
          child: MediaPlayerScreen(task: task),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
        );
      },
    ),

    // Built-in Photo Gallery & Zoom Viewer route
    GoRoute(
      path: AppRoutes.photoGallery,
      name: 'photoGallery',
      pageBuilder: (context, state) {
        final task = state.extra as DownloadTask;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PhotoGalleryScreen(task: task),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
        );
      },
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
