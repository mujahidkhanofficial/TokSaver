# Google Play Data Safety Declaration

**App Name:** TokSaver  
**Package:** `com.afridilabz.tiktok_downloader`  
**Developer:** Afridi Labz  

Use these exact answers when filling out the **Data Safety form** in Google Play Console:

---

### Section 1: Data Collection and Security
1. **Does your app collect or share any of the required user data types?**  
   👉 **No** (The app does not collect, process on servers, or share any user data).
2. **Is all of the user data collected by your app encrypted in transit?**  
   👉 **Yes** (All network requests use HTTPS/TLS).
3. **Do you provide a way for users to request that their data be deleted?**  
   👉 **Yes** (Users can tap "Clear history" and "Clear cache" directly in Settings to permanently delete all local records and downloaded files).

---

### Section 2: Data Types Breakdown
- **Location:** None
- **Personal info (Name, Email, etc.):** None
- **Financial info:** None
- **Health and fitness:** None
- **Messages / SMS:** None
- **Photos and videos:**  
  - *Data collected?* **No**.  
  - *Data processed locally?* **Yes** (Videos downloaded upon explicit user command are saved to device storage; never sent to developer servers).
- **Audio files:**  
  - *Data collected?* **No**.  
  - *Data processed locally?* **Yes** (Extracted audio files saved upon explicit user command).
- **Files and docs:** None
- **Calendar:** None
- **Contacts:** None
- **App activity:** None (No analytics SDKs).
- **Web browsing:** None
- **App info and performance (Crash logs):** None
- **Device or other IDs:** None (No advertising ID, no Android ID collected).

---

### Section 3: Advertising ID Declaration
- **Does your app use the Android Advertising ID?**  
   👉 **No** (Ad-free, no ad networks).

