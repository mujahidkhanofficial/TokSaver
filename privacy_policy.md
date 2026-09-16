# Privacy Policy for TokSaver

**Last Updated:** September 16, 2026  
**Developer:** Afridi Labz (Mujahid Afridi)  
**Contact:** support@afridilabz.com  

---

## 1. Introduction
At **Afridi Labz**, we respect and prioritize your privacy. **TokSaver** is designed from the ground up to be a privacy-first utility. We believe that a video downloader does not need to know who you are, what you watch, or what you download.

## 2. Information We Do NOT Collect
- **No Personal Information:** We do not collect names, email addresses, phone numbers, contacts, or accounts.
- **No Analytics or Telemetry:** There are zero tracking SDKs, Firebase Analytics, Mixpanel, or third-party behavioral analytics in the app.
- **No Advertising IDs:** We do not serve advertisements, and we do not collect Google Advertising ID (AAID).
- **No Background Clipboard Surveillance:** The app only inspects clipboard content when explicitly opened or resumed by the user, and only to detect whether a TikTok URL is present. This setting can be completely disabled in the Settings screen.
- **No Cloud Synchronization:** Your download history, settings, and media files remain strictly local on your device.

## 3. Information Used Locally
- **Local SQLite Database:** Download records (video title, author name, thumbnail URL, and file paths) are stored locally in an encrypted/isolated SQLite database on your device using Drift. You can wipe this data at any time via the "Clear History" button in Settings.
- **Local File Storage:** Downloaded video and audio files are saved directly to your device's standard media directories (Movies / Downloads) so you can access them with your preferred media player.
- **Network Requests:** When you paste a TikTok link, the app contacts a video extraction service solely to fetch stream URLs for downloading. No user identifiers or device fingerprints are transmitted with this request.

## 4. Permissions Requested
- **Foreground Service (`FOREGROUND_SERVICE_DATA_SYNC`):** Used strictly to keep large video downloads active when the app is minimized or the screen is locked, displaying a persistent progress notification.
- **Notifications (`POST_NOTIFICATIONS`):** Required on Android 13+ to display download progress and completion alerts. Can be disabled in Settings.
- **Storage Access (`READ_MEDIA_VIDEO` / scoped storage):** Used solely to save downloaded media files to your device storage.

## 5. Third-Party Services & Trademarks
- **TikTok Trademark Notice:** TokSaver is an independent application developed by Afridi Labz. It is **not** affiliated with, authorized, maintained, sponsored, or endorsed by TikTok, ByteDance Ltd., or any of their affiliates.
- **Intellectual Property:** Users are solely responsible for respecting the copyright and intellectual property rights of content creators. The app is provided for personal offline backup and educational use.

## 6. Children's Privacy
The app does not collect personal data from anyone, including children under 13 years of age.

## 7. Changes to This Policy
If this privacy policy is updated, the changes will be reflected in this document with an updated "Last Updated" date.

## 8. Contact Us
If you have any questions or feedback regarding privacy, please contact us at:  
**Email:** `support@afridilabz.com`

