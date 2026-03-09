# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# Keep ML Kit Text Recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# Keep Google Play Services Vision classes
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.vision.text.** { *; }

# Keep ML Kit model classes
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.mlkit.model.** { *; }

# Keep Flutter plugin classes
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Keep Local Vault app classes
-keep class com.ironion.local_vault.** { *; }
