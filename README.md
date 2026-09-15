# ⚡ TokSave — Premium TikTok Video & Audio Downloader

<p align="center">
  <img src="assets/icons/app_icon.png" width="100" alt="TokSave Logo" />
</p>

<p align="center">
  <b>A blazing fast, 100% ad-free, zero-telemetry TikTok HD video and audio downloader for Android and Web.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/State-Riverpod-blue" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Database-Drift%20SQLite-teal" alt="Drift" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/Privacy-100%25%20Zero%20Telemetry-purple" alt="Privacy" />
</p>

---

## ✨ Key Features

- 🚫 **100% Ad-Free & Privacy First:** Zero trackers, no analytics, no account required. Everything stays on your device.
- ⚡ **No Watermark (HD):** Download crisp, watermark-free videos directly from TikTok CDN.
- 🎵 **Extract MP3 Audio:** Download crystal-clear audio tracks and TikTok background music.
- 🎬 **TikTok-Style Media History:** Switch between a 2-column TikTok-style cover grid or list view with search, filters, and batch delete.
- 🖤 **AMOLED Pure Black & Dynamic Themes:** Handcrafted design system featuring Frosted Glass navigation, glowing accents, and pure OLED black (`#000000`).
- ⏸️ **Resumable Downloads:** HTTP `Range` streaming engine allows pausing, resuming, and auto-reconnection on network drops.
- 📱 **Android Foreground Service:** Background download engine with live notification progress and automatic Android MediaStore / Gallery indexing.
- 📊 **Storage Analytics:** Live breakdown of storage consumed by Videos, Audio, and Cache with 1-tap cache cleaner.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev) (Dart 3)
- **Architecture:** Feature-First Clean Architecture
- **State Management:** [Flutter Riverpod](https://riverpod.dev)
- **Local Database:** [Drift (SQLite)](https://drift.simonbinder.eu/) with web Wasm (`sql.js`) support
- **Networking:** [Dio](https://pub.dev/packages/dio) with custom streaming chunk sink & ETA calculation
- **Design System:** Material 3 with Frosted Glass (`BackdropFilter`) & custom Haptic Feedback

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.22.0 or higher)
- Android Studio / VS Code with Flutter extension
- Android device or emulator (API 26+) / Chrome for Web

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mujahidkhanofficial/TokSave.git
   cd TokSave
