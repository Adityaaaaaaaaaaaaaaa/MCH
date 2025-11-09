# Flutter & Dart related
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase / Google services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Kotlin coroutines & reflection safety
-keepclassmembers class kotlinx.** { *; }
-keepclassmembers class kotlin.** { *; }

# Gson / JSON parsing (used by HTTP & Spoonacular)
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
-keepattributes *Annotation*

# Prevent stripping of models used via reflection
-keep class **.models.** { *; }
