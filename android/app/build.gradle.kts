plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kdh.omninews"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        
        // Kotlin DSL에서는 이렇게 사용해야 함
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.kdh.omninews"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Kotlin DSL에서는 따옴표 안에 문자열을 넣습니다
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Flutter 임베딩을 명시적으로 추가해 보세요 (MainActivity.kt 에러 해결 위해)
    implementation("io.flutter:flutter_embedding_release:1.0.0-d2913632a4578ee4d0b8b1c4a69888c8a0672c4b")
}

flutter {
    source = "../.."
}
