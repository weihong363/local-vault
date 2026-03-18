plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val bundledSlmModelFileName = "qwen2.5-0.5b-instruct-q4_k_m.gguf"
val generatedModelAssetsDir = layout.buildDirectory.dir("generated/modelAssets")

android {
    namespace = "com.ironion.localvault"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ironion.localvault"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 启用 multidex 支持（如果需要）
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // 启用代码压缩但不混淆（避免 ML Kit 类被移除）
            isMinifyEnabled = false
            isShrinkResources = false
            
            // 注意：暂时禁用 ProGuard 以避免 ML Kit 类被错误移除
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    sourceSets {
        getByName("main").assets.setSrcDirs(listOf(generatedModelAssetsDir))
    }
}

dependencies {
    implementation("androidx.preference:preference-ktx:1.2.1")
    // 添加中文 OCR 模型依赖
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
}

flutter {
    source = "../.."
}

val syncModelAssets by tasks.registering(Sync::class) {
    from(rootProject.projectDir.parentFile.resolve("assets/models"))
    into(generatedModelAssetsDir.map { it.dir("models") })
    include(bundledSlmModelFileName)
}

tasks.named("preBuild") {
    dependsOn(syncModelAssets)
}
