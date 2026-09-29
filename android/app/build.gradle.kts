plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
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

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug") // replace for prod
        }
    }

    flavorDimensions += "environment"

    productFlavors {
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "PSF Foundation")
            resValue("string", "domain_url", "psf-foundation.com")
        }
        create("dev") {
            dimension = "environment"
            resValue("string", "app_name", "PSF Foundation Dev")
            resValue("string", "domain_url", "dev.psf-foundation.com")
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