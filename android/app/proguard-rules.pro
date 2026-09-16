# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App Native Classes
-keep class com.afridilabz.tiktok_downloader.** { *; }
-dontwarn com.afridilabz.tiktok_downloader.**

# Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Drift / SQLite
-keep class com.google.crypto.tink.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# Keep enums
-keepclassmembers enum * { *; }

# Keep Kotlin metadata & line numbers for debugging
-keepattributes *Annotation*, Signature, Exception, InnerClasses, EnclosingMethod
-keepattributes SourceFile, LineNumberTable

# Dio / OkHttp / Desugar
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**

# Play Core (deferred components not used)
-dontwarn com.google.android.play.core.**

# Video Player / ExoPlayer / Media3
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**