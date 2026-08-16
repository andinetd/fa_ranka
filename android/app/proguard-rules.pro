# Keep Flutter engine and generated registration stable during release shrinking.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**

# Preserve generated plugin registrant classes used by Flutter.
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }
