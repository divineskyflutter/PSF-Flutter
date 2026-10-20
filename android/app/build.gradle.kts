import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase Cloud Messaging (push notifications). The Google Services plugin
// turns android/app/google-services.json into the app's Firebase config, and
// FAILS the build when the file is missing — so it is applied only when a
// google-services.json exists. Without one the app still builds and runs; it
// just skips push notifications (see lib/core/notifications).
//
// Put the file at android/app/google-services.json. One file works for both
// flavors when the Firebase project has an Android app for each package name
// (dev: com.example.psf_application, prod: com.divinesky.psf).
val hasGoogleServicesJson = listOf(
    "google-services.json",
    "src/dev/google-services.json",
    "src/prod/google-services.json",
).any { file(it).exists() }
if (hasGoogleServicesJson) {
    apply(plugin = "com.google.gms.google-services")
}

// Upload-key details for signing the Play Store build. Lives in
// android/key.properties (git-ignored, never committed) next to the keystore
// it points at. When the file is missing, prod falls back to the debug key so
// a plain `flutter build` still works, but Google Play will reject that build.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.example.psf_application"
    compileSdk = 36
    ndkVersion = "29.0.13113456 rc1"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.psf_application"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro",
            )
            // Lets Play Console symbolicate crashes in native code.
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }

    // The app switches between English/Hindi/Gujarati from inside the app
    // (not by the phone's language), so Play must ship every language's
    // resources to every device instead of only the phone's own.
    bundle {
        language {
            enableSplit = false
        }
    }

    flavorDimensions += "environment"

    productFlavors {
        create("prod") {
            dimension = "environment"
            // Google Play rejects any application id starting with
            // "com.example". This is the Play Store identity — it can never
            // be changed once the app is first uploaded, so confirm it
            // before the first upload.
            applicationId = "com.divinesky.psf"
            resValue("string", "app_name", "PSF Member")
            resValue("string", "domain_url", "psf-foundation.com")
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        create("dev") {
            dimension = "environment"
            resValue("string", "app_name", "PSF Foundation Dev")
            resValue("string", "domain_url", "dev.psf-foundation.com")
            // Dev builds stay on the debug key so they keep installing
            // over the existing test installs on the team's phones.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.multidex:multidex:2.0.1")
    // Login screen's mobile-number field: Google's Phone Number Hint
    // picker (see MainActivity.kt's showPhoneNumberHint) — needs no
    // dangerous runtime permission and no google-services.json/Firebase
    // project, just Google Play Services on the device.
    implementation("com.google.android.gms:play-services-auth:21.2.0")
}