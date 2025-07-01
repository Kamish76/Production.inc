# Flutter and Dart specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Game-specific rules for Production.Inc
-keep class com.production.inc.** { *; }

# SQLite rules (for game persistence)
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# SharedPreferences rules
-keep class android.content.SharedPreferences { *; }

# Audio player rules
-keep class androidx.media.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Flutter specific optimizations
-dontwarn io.flutter.plugin.**
-dontwarn io.flutter.util.**