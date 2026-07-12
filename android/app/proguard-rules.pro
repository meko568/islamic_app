# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Adhan library
-keep class com.batoulapps.adhan.** { *; }

# Hijri library
-keep class com.github.msarhan.ummalqura.** { *; }

# Google Fonts
-keep class com.google.fonts.** { *; }

# Shared Preferences
-keep class io.github.v7lin.shared_preferences.** { *; }

# Fix for Play Store missing classes (R8 errors)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keep class com.google.android.play.core.** { *; }

# General Flutter Proguard Rules
-dontwarn javax.xml.bind.**
-dontwarn android.util.Size
-dontwarn android.util.Range
