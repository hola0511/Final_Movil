
plugins {
    id("com.android.application")

    id("com.google.gms.google-services")

    id("com.google.firebase.crashlytics")

    id("dev.flutter.flutter-gradle-plugin")
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

    buildTypes {
        release {
            // Configuración temporal para pruebas.
            // Configurar firma de release propia
            // antes de la entrega definitiva.
            signingConfig = signingConfigs.getByName("debug")
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
