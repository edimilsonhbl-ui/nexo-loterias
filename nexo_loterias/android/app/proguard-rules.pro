# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Play Core — ignorar classes ausentes (Flutter deferred components não usados)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Modelo de dados
-keep class com.nexoloterias.nexo_loterias.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepclassmembers class ** {
    @kotlin.Metadata *;
}
