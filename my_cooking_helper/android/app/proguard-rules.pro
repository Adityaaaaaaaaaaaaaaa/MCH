#########################################
#        My Cooking Helper Rules        #
#     Verified for Flutter + Firebase   #
#     Gemini + Spoonacular + YouTube    #
#########################################

# --- Flutter Core / Engine ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- Google Play Core (Fix R8 MissingClass errors) ---
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# --- Firebase & Google Services ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# --- Kotlin / Coroutines ---
-keepclassmembers class kotlinx.** { *; }
-keepclassmembers class kotlin.** { *; }

# --- Gson / JSON Serialization (Gemini & Spoonacular) ---
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
-keepattributes *Annotation*

# --- Retrofit / HTTP (if used indirectly) ---
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-dontwarn javax.annotation.**

# --- Your Models (Recipe, Instruction, etc.) ---
-keep class **.models.** { *; }

# --- YouTube API / Google API Client (safe reflection) ---
-keep class com.google.api.** { *; }
-keep class com.google.api.services.youtube.** { *; }
-dontwarn com.google.api.**

# --- Misc: prevent stripping of JSON fields used dynamically ---
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

#########################################
#  End of My Cooking Helper ProGuard    #
#########################################
