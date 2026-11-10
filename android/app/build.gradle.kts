
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")

    id("com.google.gms.google-services")

    id("com.google.firebase.crashlytics")

    id("dev.flutter.flutter-gradle-plugin")
}

// Cargar las propiedades de firma.
// El archivo permanece fuera del repositorio.
val keystoreProperties = Properties()

val keystorePropertiesFile =
    rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

android {
    namespace = "com.example.eventos_g62_5"

    compileSdk = flutter.compileSdkVersion

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.eventos_g62_5"

        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode

        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias =
                keystoreProperties.getProperty("keyAlias")

            keyPassword =
                keystoreProperties.getProperty("keyPassword")

            storeFile =
                keystoreProperties.getProperty("storeFile")
                    ?.let { file(it) }

            storePassword =
                keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Firmar con el certificado propio.
            signingConfig =
                signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
