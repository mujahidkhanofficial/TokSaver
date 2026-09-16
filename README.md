<div align="center">

# 🎬 TokSaver

### High-Performance, Privacy-First TikTok Media Downloader & Player for Android

[![Flutter](https://img.shields.io/badge/Flutter-3.29%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-SDK%2026%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20Riverpod%202.0-blueviolet)]()
[![Database](https://img.shields.io/badge/Storage-Drift%20SQLite-00B8D9)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()

A modern, ad-free utility built with Flutter and Material 3 to extract, download, organize, and play HD TikTok videos, audio tracks, and photo slideshows with zero watermarks.

---

</div>

## ✨ Key Features

### 🚀 1. Universal Media Extraction & Batch Downloader
* **Watermark-Free HD Videos**: Instant analysis and direct high-speed download of original resolution videos.
* **TikTok Photo Slideshows**: Full carousel detection with batch download options (`ZIP` archive or individual high-res images).
* **Audio & MP3 Extraction**: Direct extraction of original TikTok background music and sounds.
* **Batch Multi-Link Queue**: Paste up to 20 TikTok links simultaneously with automatic URL deduplication and tracking query stripping (`tt_from`, `is_from_webapp`, etc.).

### 📱 2. System Integration & Share-to-Download
* **Android Share Sheet Integration (`SEND` Intent)**: Share any TikTok video directly to TokSaver from the official TikTok app for one-tap analysis and download.
* **Smart Clipboard Detection**: Automatically detects copied TikTok links on app launch with instant download action pills.

### 🎥 3. In-App Gestural Media Player & Fullscreen Gallery
* **Gestural Video Player**:
  * **Double-tap Left / Right**: Fast seek (±10 seconds) with animated HUD indicators.
  * **Vertical Slide (Left Screen)**: Smooth in-app Brightness adjustment.
  * **Vertical Slide (Right Screen)**: Smooth Volume control HUD.
* **Picture-in-Picture (PiP) Mode**: Seamless background video playback while multitasking.
* **Audio & Ringtone Utility**: Set any downloaded TikTok sound directly as your Android Phone Ringtone or Notification sound.
* **Interactive Photo Viewer**: Fullscreen pinch-to-zoom (1.0x–4.5x) and drag-to-dismiss photo gallery with double-tap auto-zoom.

### 🛡️ 4. Offline Storage, Database & Backups
* **Drift SQLite Engine**: Robust, typed SQLite database tracking all downloads, metadata, creators, and timestamps.
* **Creator Filter Chips**: Filter history by creator handle (`@creator`), format (Video, Audio, Photos), and date.
* **JSON History Backup & Restore**: One-tap export and import of your entire download catalog.
* **Storage Analytics & Cache Cleaner**: Visual storage usage breakdown (Videos vs Audio) and one-tap cache cleaner.

### 🎨 5. Material 3 & AMOLED Aesthetics
* **Dynamic Theme Modes**: System default, Clean Light, Sleek Dark, and Pure AMOLED black (OLED battery saving).
* **Anti-Aliased Card Design**: Grouped inset cards with native M3 state layers, micro-animations, and custom switches.
* **iOS-Inspired Navigation Dock**: High-contrast icon feedback, spring micro-scale transitions, and active download badge count.

---

## 🏗️ Architecture & Tech Stack

TokSaver follows a modular, feature-first Clean Architecture pattern:

```
lib/
├── app/                  # Application bootstrap, router (GoRouter), & M3 themes
├── core/
│   ├── constants/        # API endpoints, limits, and app configuration
│   ├── network/          # TikWM extractor client, Dio engine, and download queue
│   ├── storage/          # Drift SQLite database, DAOs, and Android MediaStore integration
│   └── utils/            # URL validator, logger, PiP service, and share intent receiver
├── features/
│   ├── analyzer/         # URL analysis provider and format preview modal
│   ├── batch/            # Batch multi-link parser and queue manager
│   ├── downloads/        # Active download tasks stream and progress controller
│   ├── history/          # Completed history, creator filter chips, and JSON backup
│   ├── home/             # Main dashboard, quick action pills, and clipboard monitor
│   ├── photos/           # Photo slides extraction and image carousel models
│   ├── player/           # Gestural video player, PiP controller, and photo gallery
│   └── settings/         # Persistent settings repository, AMOLED toggle, and storage card
└── shared/               # Shared models (DownloadTask, VideoMetadata) and M3 widgets
```

---

## 🛠️ Build & Installation

### Prerequisites
* Flutter SDK `3.29.0` or higher
* Android SDK Platform `34` or `36`
* Java / JDK `17`

### 1. Clone the Repository
```bash
git clone https://github.com/mujahidkhanofficial/TokSaver.git
cd TokSaver
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# Run on connected Android device or emulator
flutter run

# Run on Chrome for UI preview
flutter run -d chrome
```

### 4. Build Release APK
```bash
# Universal release APK
flutter build apk --release

# Output path: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Testing

The repository contains a test suite covering repository operations, URL sanitization, download queuing, share intent parsing, and UI widget flows:

```bash
flutter test
```

---

## 🔒 Privacy & Legal Disclaimer

* **100% Local & Private**: TokSaver requires no user registration, collects zero personal analytics, and stores all history locally on your device.
* **Disclaimer**: TokSaver is an independent utility created for personal offline viewing. It is not affiliated with, sponsored, or endorsed by TikTok or ByteDance Ltd. Please respect intellectual property rights and the copyrights of content creators.

---

## 👨‍💻 Author

**Mujahid Khan**
* GitHub: [@mujahidkhanofficial](https://github.com/mujahidkhanofficial)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
