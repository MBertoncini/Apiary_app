// File: android/settings.gradle.kts

pluginManagement {
    // Blocco esistente per trovare Flutter SDK
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
             localPropertiesFile.inputStream().use { properties.load(it) }
        }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    plugins {
        // Dichiarazione del plugin Foojay (CORRETTO - rimane qui)
        id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal() // Necessario per trovare il plugin foojay
    }
}

// Blocco per *applicare* i plugin allo script settings.gradle.kts
plugins {
    id("dev.flutter.flutter-plugin-loader") // Già presente
    // --- APPLICA IL PLUGIN FOOJAY QUI ---
    id("org.gradle.toolchains.foojay-resolver-convention")
    // --- FINE APPLICAZIONE ---
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

// Rimuoviamo completamente il blocco toolchainManagement poiché il plugin foojay
// dovrebbe configurare automaticamente i repository JDK quando applicato

rootProject.name = "android" // O il nome corretto
include(":app")