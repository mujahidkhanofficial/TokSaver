/// Application-wide constants.
/// All timeouts, limits, and fixed strings live here — never scattered in feature code.
abstract final class AppConstants {
  AppConstants._();

  // ── Network ─────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration analyzeTimeout = Duration(seconds: 30);

  // ── Download Engine ──────────────────────────────────────────────────────────
  /// Default max concurrent downloads (conservative for battery/RAM).
  static const int defaultMaxConcurrentDownloads = 1;

  /// Absolute max the user can configure.
  static const int maxAllowedConcurrentDownloads = 3;

  /// Chunk size for streaming writes — 512 KB.
  static const int downloadChunkSize = 512 * 1024;

  /// Speed calculation rolling window (samples).
  static const int speedSampleWindow = 5;

  // ── File ─────────────────────────────────────────────────────────────────────
  static const String tempDownloadDirName = 'downloads_temp';
  static const String mediaSubDir = 'TokSaver';
  static const int maxFilenameLength = 180;

  // ── URL Validation ───────────────────────────────────────────────────────────
  static const List<String> tiktokHosts = [
    'tiktok.com',
    'www.tiktok.com',
    'vm.tiktok.com',
    'vt.tiktok.com',
    'm.tiktok.com',
  ];

  // ── History ──────────────────────────────────────────────────────────────────
  /// Max history entries kept in DB (oldest pruned on overflow).
  static const int maxHistoryEntries = 500;

  // ── Thumbnail cache ───────────────────────────────────────────────────────────
  static const int thumbnailCacheMaxWidth = 360;

  // ── App meta ─────────────────────────────────────────────────────────────────
  static const String appName = 'TokSaver';
  static const String developerName = 'Afridi Labz';
  static const String supportEmail = 'support@afridilabz.com';

  // ── Platform channel names ───────────────────────────────────────────────────
  static const String downloadServiceChannel = 'com.afridilabz.tiktok_downloader/download_service';
}
