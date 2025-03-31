plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.Apiary"
    compileSdk = 34 // Esplicito invece di flutter.compileSdkVersion
    ndkVersion = "25.2.9519653" // Versione più comune e stabile

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.example.Apiary"
        minSdk = 24
        targetSdk = 34 // Esplicito invece di flutter.targetSdkVersion
        versionCode = 1 // Esplicito invece di flutter.versionCode
        versionName = "1.0.0" // Esplicito invece di flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    packagingOptions {
         resources.excludes.add("META-INF/AL2.0")
         resources.excludes.add("META-INF/LGPL2.1")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}

flutter {
    source = "../.."
}