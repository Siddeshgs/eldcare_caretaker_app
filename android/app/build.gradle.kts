plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") // Required for Firebase
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")   // Correct Kotlin plugin name
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.eldcare_caretaker_app"   // Must match your package name
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true   // REQUIRED
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.eldcare_caretaker_app" // ✅ Use consistent package name
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // ✅ REQUIRED
    implementation("com.google.firebase:firebase-database-ktx:20.3.0") // ✅ Firebase Database
    implementation("com.google.firebase:firebase-analytics-ktx:21.5.0") // Optional: Analytics
}

flutter {
    source = "../.."
}
