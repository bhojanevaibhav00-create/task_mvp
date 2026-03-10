# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Prevent R8 from stripping Flutter Local Notifications classes (Crucial for reminders)
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Fix for R8 missing class errors related to Play Store deferred components
-dontwarn com.google.android.play.core.**

# Gson (Required by flutter_local_notifications for payload serialization)
-keep class com.google.gson.** { *; }

# Keep generic classes that might be used by plugins
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }