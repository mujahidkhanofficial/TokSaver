# TikTok Video Downloader

## Lightweight Production Software Requirements Specification

**Version:** 1.0
**Platform:** Android first, iOS-ready architecture
**Framework:** Flutter
**Distribution:** Google Play Store initially
**Business Model:** Free, No Ads, Optional Donations
**UI Direction:** Modern iOS-inspired native-quality interface
**Developer:** Afridi Labz / Mujahid Afridi

---

# 1. Product Overview

TikTok Video Downloader is a lightweight Flutter mobile application that allows users to download publicly accessible TikTok media through a supported URL workflow.

The application shall prioritize:

* Very fast startup
* Low RAM usage
* Minimal battery consumption
* Clean iOS-inspired UI
* Simple download workflow
* Reliable download management
* No advertisements
* Optional user donations
* Privacy-first local storage
* Play Store compliance

The application shall not attempt to replicate TikTok itself.

---

# 2. Core User Flow

```text
Copy TikTok Link
       ↓
Open App
       ↓
URL Automatically Detected
       ↓
Analyze Video
       ↓
Show Preview + Metadata
       ↓
Select Available Quality
       ↓
Download
       ↓
Download Manager
       ↓
Saved to Device
```

Primary screen should allow the user to complete the basic workflow in as few interactions as possible.

---

# 3. MVP Features

## 3.1 URL Input

Required:

* Paste TikTok URL
* Manual URL entry
* Clipboard detection
* URL validation
* Support normal TikTok share URLs where technically supported
* Clear invalid URL message

Example:

```text
Paste TikTok link

[ https://www.tiktok.com/... ]

              [Analyze]
```

If a valid TikTok URL is detected in the clipboard:

```text
TikTok link detected

[Use Link]     [Dismiss]
```

The application must not automatically start a download without explicit user action.

---

# 4. Video Analysis

After URL analysis, display:

* Thumbnail
* Video title/description where available
* Creator username where available
* Duration
* Available video qualities
* File format
* Estimated file size where available

Example:

```text
┌─────────────────────────────┐
│                             │
│        Video Preview        │
│                             │
└─────────────────────────────┘

@username

Video Title

Quality

● Best Available
○ 1080p
○ 720p
○ 480p

        [Download]
```

The application must only display formats actually returned by the extractor/source.

---

# 5. Download Manager

Required:

* Start download
* Pause
* Resume
* Cancel
* Retry
* Download progress
* Download speed
* Estimated remaining time
* Downloaded size
* Total size
* Failed state
* Completed state

Download states:

```text
Queued
Downloading
Paused
Completed
Failed
Cancelled
```

Downloads must continue safely when the user navigates away from the current screen.

---

# 6. Download Queue

The user can have multiple downloads.

Requirements:

* Queue downloads
* Sequential or limited concurrent downloading
* Maximum concurrent downloads configurable internally
* Reorder queued items where practical
* Retry failed downloads
* Clear completed items

Default concurrency should be conservative to reduce battery, memory and network consumption.

---

# 7. Download History

Store locally:

* Title
* Creator
* Thumbnail reference where appropriate
* Original URL
* Local file path
* Download date
* File size
* Selected quality
* Status

Actions:

* Open video
* Share
* Open containing folder/location where Android permits
* Download again
* Delete history
* Delete downloaded file

History must survive application restart.

---

# 8. File Management

Default destination should use an Android-approved media/download location.

Requirements:

* Save downloaded videos to user-accessible storage
* Android scoped-storage compatibility
* MediaStore integration where appropriate
* Avoid unrestricted filesystem permissions
* Detect insufficient storage
* Prevent filename conflicts
* Sanitize filenames

Filename example:

```text
@username - Video Title.mp4
```

If duplicate:

```text
@username - Video Title (1).mp4
```

---

# 9. Clipboard Detection

Clipboard detection must be privacy-conscious.

Rules:

* Do not continuously monitor clipboard in background
* Inspect clipboard when application enters foreground or user taps paste/analyze
* Detect supported TikTok URLs only
* Never upload clipboard contents
* Do not store unrelated clipboard content

---

# 10. UI / UX

## Design Direction

The application shall use a **modern iOS-inspired interface**, adapted properly for Android rather than attempting to imitate iOS pixel-for-pixel.

Design characteristics:

* Clean
* Minimal
* Spacious
* Rounded cards
* Subtle borders
* Strong typography hierarchy
* Smooth transitions
* Large touch targets
* Minimal visual noise
* No glassmorphism
* No heavy blur effects
* No unnecessary animations

Avoid:

* Excessive gradients
* GPU-heavy blur
* Excessive shadows
* Decorative animations
* Complex dashboards

---

# 11. Main Screens

## Home

Primary actions:

```text
TokSaver

Paste a TikTok link

[ Paste Link ]

Recent Downloads
```

Optional clipboard detection banner.

---

## Video Preview

```text
Thumbnail

Creator
Title
Duration

Available Quality

1080p
720p
480p

[ Download ]
```

---

## Downloads

Sections:

```text
Downloading
Queued
Completed
Failed
```

Each item:

```text
Thumbnail
Title
1080p • 14.2 MB

████████████░░ 82%

2.4 MB/s
ETA 00:03

Pause    Cancel
```

---

## History

Simple searchable list.

Actions available through swipe/context menu.

---

## Settings

Sections:

```text
Downloads
Appearance
Notifications
Privacy
About
Support
```

---

# 12. Theme

Support:

* Light
* Dark
* System default

Use Material 3 / Flutter theming while maintaining the iOS-inspired visual language.

No hardcoded colors inside individual widgets.

Centralize:

```text
AppColors
AppTypography
AppSpacing
AppRadius
AppTheme
```

---

# 13. Donation

The application shall contain **no advertisements**.

Users may optionally support development.

Settings:

```text
Support Development

If you find this app useful, you can
optionally support its development.

[Support Development]
```

Donation must never:

* Block features
* Disable downloads
* Show forced prompts
* Manipulate users
* Be required for continued use

For Play Store distribution, the implementation must use the appropriate Google Play-supported billing/donation mechanism and comply with current Play policies. The exact donation implementation shall be decided during Play Store compliance implementation rather than hard-coded into the core architecture.

---

# 14. Notifications

Optional notifications:

```text
Download completed
Download failed
Download paused
```

Notification example:

```text
Download Complete

Video Title
14.2 MB • 1080p

[Open]
```

Users must be able to disable notifications.

---

# 15. Sharing

After download:

```text
[Open]
[Share]
[Delete]
```

Use Android/iOS native sharing APIs through Flutter plugins.

---

# 16. Permissions

Follow least-privilege architecture.

The application must avoid unnecessary permissions.

Do not request:

* Contacts
* Location
* Phone
* SMS
* Microphone
* Camera

Storage/media permissions should only be requested where required by the target Android version and selected storage workflow.

---

# 17. Privacy

Privacy-first design.

The app should operate without requiring an account.

Do not collect:

* User identity
* Contact list
* Clipboard history
* Personal files
* Download history remotely

Downloaded URLs and metadata should remain local unless the user explicitly initiates an external action.

No hidden analytics should be introduced into the MVP.

---

# 18. TikTok Compliance

The application must not falsely imply that it is an official TikTok product.

Use neutral branding such as:

```text
TokSaver
```

with appropriate legal/trademark disclaimers where required.

The application must respect:

* TikTok terms and policies
* Copyright
* Creator rights
* Platform restrictions
* Google Play policies
* Applicable laws

The application must not bypass access controls or download private/protected content without authorization.

Watermark/copyright handling must be designed around applicable platform and creator-rights requirements.

---

# 19. Architecture

Use a lightweight layered architecture.

```text
lib/
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│
├── core/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   ├── utils/
│   └── constants/
│
├── features/
│   ├── home/
│   ├── analyzer/
│   ├── downloads/
│   ├── history/
│   ├── settings/
│   └── donation/
│
└── shared/
    ├── widgets/
    └── models/
```

Architecture principles:

* Feature-first
* Dependency inversion where useful
* No unnecessary abstraction
* No over-engineering
* UI independent from download implementation
* Download state independent from UI lifecycle

---

# 20. Recommended Flutter Stack

## Core

```text
Flutter
Dart
Material 3
```

## State Management

Use:

```text
Riverpod
```

Use providers only where state actually requires them.

Avoid global mutable state.

---

## Navigation

Use:

```text
go_router
```

Keep routing simple.

---

## Networking

Use:

```text
Dio
```

Requirements:

* Timeouts
* Cancellation
* Download streaming
* Retry support
* HTTP error handling

---

## Local Database

Use:

```text
Drift + SQLite
```

Store:

* Download records
* Queue state
* Settings where appropriate
* Metadata

Do not store large video files inside SQLite.

---

## File System

Use appropriate Flutter filesystem/path packages and Android MediaStore integration.

Architecture:

```text
Downloader
    ↓
Temporary File
    ↓
Validation
    ↓
MediaStore / User Storage
```

---

## Background Downloads

The downloader should use a platform-appropriate background execution strategy.

Important requirement:

> Download state must not depend on the Flutter UI being open.

Android background work should use native Android facilities where required rather than relying solely on a Dart isolate.

For long-running downloads, design a small native Android bridge/service layer.

---

# 21. Download Engine Architecture

```text
DownloadController
        │
        ▼
DownloadQueue
        │
        ▼
DownloadTask
        │
        ▼
NetworkDownloader
        │
        ▼
Temporary File
        │
        ▼
File Validator
        │
        ▼
MediaStore
```

Each task should have a persistent ID.

Example:

```text
DownloadTask
├── id
├── sourceUrl
├── filename
├── quality
├── status
├── progress
├── downloadedBytes
├── totalBytes
├── createdAt
└── completedAt
```

---

# 22. Error Handling

User-facing errors must be understandable.

Examples:

```text
Invalid TikTok link

Video unavailable

Unable to analyze video

Network connection failed

Download interrupted

Not enough storage

Download failed

Try again
```

Internal logs should contain technical diagnostics.

Never expose stack traces to normal users.

---

# 23. Performance Requirements

Target:

* Cold startup: ideally < 2 seconds on mid-range devices
* Minimal first-frame delay
* No unnecessary background services
* No continuous polling
* No video processing unless required
* Lazy-load nonessential screens
* Avoid large image caches
* Dispose controllers/resources correctly

Memory:

```text
Idle:
Target <100 MB where practical

Downloading:
Avoid unnecessary memory growth

Multiple downloads:
Use streaming/chunked writes rather than loading files into RAM
```

---

# 24. Offline Behavior

The application should remain usable offline for:

* Viewing download history
* Viewing completed downloads
* Managing local files
* Opening downloaded media
* Changing settings

Network-dependent operations should show:

```text
No internet connection
```

without crashing.

---

# 25. Logging

Use structured local debug logging.

Production builds:

* Disable verbose logs
* Never log sensitive user data
* Never log complete clipboard contents
* Never log authentication secrets
* Never log unnecessary URLs

Optional diagnostic export can be added later.

---

# 26. Testing

## Unit Tests

Test:

* URL validation
* Filename sanitization
* Download state transitions
* Queue behavior
* Retry logic
* Database operations
* Settings

## Widget Tests

Test:

* Home screen
* URL input
* Video preview
* Download item
* Error states
* Settings

## Integration Tests

Test:

```text
URL
 ↓
Analyze
 ↓
Select quality
 ↓
Download
 ↓
Save
 ↓
History
```

Also test:

* App restart during download
* Network interruption
* Disk full
* Duplicate filename
* Cancel/resume
* Multiple queued downloads

---

# 27. Android Requirements

Target modern Android versions and comply with the current Google Play target API requirement at release time.

Support:

* Android scoped storage
* MediaStore
* Background execution restrictions
* Notification permission where applicable
* Adaptive launcher icon
* Android 12+ splash screen
* Edge-to-edge UI where appropriate

APK/AAB:

```text
Release format: Android App Bundle (.aab)
```

---

# 28. iOS Readiness

Although Android is the initial target, architecture should avoid Android-specific assumptions in the shared Flutter layer.

Keep:

```text
Presentation
Domain
Models
Database
Queue logic
```

platform-neutral.

Use platform interfaces for:

```text
Background downloading
Media storage
Sharing
Notifications
Billing
```

---

# 29. Security

Flutter:

* No secrets in source code
* No API keys in client unless genuinely public
* Validate all external data
* Sanitize filenames
* Validate file paths
* Prevent path traversal
* Validate downloaded content
* Avoid arbitrary executable file handling

Android:

* Minimize exported components
* Secure intents
* Secure FileProvider configuration
* No unnecessary permissions
* Release build obfuscation where appropriate

---

# 30. App States

The UI must explicitly handle:

```text
Initial
Loading
Analyzing
Ready
Downloading
Paused
Completed
Failed
Offline
No Results
Storage Error
Unsupported URL
```

Every state must have a recoverable user action where possible.

---

# 31. Accessibility

Support:

* Dynamic text sizing
* Screen readers
* Adequate contrast
* Minimum touch targets
* Semantic labels
* Keyboard navigation where applicable
* Reduced motion preference where practical

---

# 32. Localization

MVP:

```text
English
```

Architecture must support future localization.

Potential future:

```text
Urdu
Arabic
Pashto
```

Do not hardcode user-visible strings.

---

# 33. Analytics

MVP:

```text
No mandatory analytics
```

If analytics are introduced later:

* Explicit privacy review
* Minimal event collection
* No personal information
* No URL collection
* No clipboard collection
* User disclosure where required

---

# 34. App Store / Play Store Assets

Required before release:

* App icon
* Feature graphic
* Screenshots
* App description
* Privacy policy
* Terms where required
* Support/contact page
* Content rating
* Data Safety declaration
* App category
* Appropriate copyright/trademark disclosures

---

# 35. Non-Goals

The MVP will NOT include:

* TikTok account login
* Private account access
* Credential collection
* Cloud storage
* User accounts
* Social feed
* Video editor
* Video hosting
* Built-in social network
* Ads
* Forced donations
* Unnecessary analytics
* Heavy AI features

---

# 36. Future Features

Potential V2:

* Browser/share-sheet integration
* Batch URL import
* Playlist/bulk processing where legitimately supported
* Advanced download scheduling
* Download speed limiter
* Custom filename templates
* More supported media sources
* iOS release
* Desktop companion application
* Optional cloud backup
* Advanced media library

---

# 37. Definition of Production Ready

The application is production-ready when:

* Core download flow works reliably
* Download state survives app restart
* Failed downloads recover correctly
* Files are saved safely
* No critical crashes exist
* Android permission model is compliant
* Play Store policies are satisfied
* Privacy policy is published
* Release AAB passes testing
* No critical security issues remain
* Performance is acceptable on low/mid-range Android devices
* Dark/light/system themes work
* Accessibility basics are implemented
* No ads are present
* Donation is optional and compliant

---

# 38. Recommended MVP Screen Map

```text
App
│
├── Home
│    ├── Paste URL
│    └── Analyze
│
├── Video Details
│    ├── Preview
│    ├── Quality
│    └── Download
│
├── Downloads
│    ├── Active
│    ├── Queued
│    ├── Completed
│    └── Failed
│
├── History
│
└── Settings
     ├── Downloads
     ├── Appearance
     ├── Notifications
     ├── Privacy
     ├── Support Development
     └── About
```

---

# 39. Product Principle

The product should follow one central principle:

> **Paste → Choose → Download.**

Everything else should support that workflow without making the application feel like a complicated downloader dashboard.

The application should feel like a polished, lightweight mobile utility rather than an overloaded enterprise application.
