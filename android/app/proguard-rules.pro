# Flutter and Dart specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Game-specific rules for Production.Inc
-keep class com.production.inc.** { *; }

# Google Play Core (for Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

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

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
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

# R8 full mode compatibility
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*

# Keep crash reporting functionality
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Flutter embedding optimizations
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**