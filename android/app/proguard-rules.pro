# Flutter / Firebase ProGuard rules for release builds

# ── Flutter ──────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Firebase ─────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── Google Sign-In ───────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }

# ── Crashlytics (stack traces) ──────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ── RevenueCat / Purchases ───────────────────────────────
-keep class com.revenuecat.purchases.** { *; }

# ── url_launcher ─────────────────────────────────────────
-keep class androidx.browser.** { *; }

# ── Kotlin Serialization (if used) ───────────────────────
-keepclassmembers class * {
    @kotlinx.serialization.* *;
}

# ── General safety ───────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
