// File: android/build.gradle.kts

buildscript {
    val kotlinVersion = "1.8.20" 
    val agpVersion = "8.1.3"     // Abbassato a una versione più stabile

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:$agpVersion")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configurazione Java per tutto il progetto - semplificata
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }

    // Applica la configurazione Kotlin solo ai progetti con plugin Kotlin
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = JavaVersion.VERSION_17.toString()
            }
        }
    }
}

// Configurazione dei percorsi di build
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}