plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.production.inc"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.production.inc"
        minSdk = 24  
        targetSdk = 35
        versionCode = 9
        versionName = "1.4.14"
        
        // Game-specific optimizations
        multiDexEnabled = true
        vectorDrawables.useSupportLibrary = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Enable desugaring for API features
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // Game performance optimizations with R8/ProGuard enabled
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
            
            // Enable debug symbols for better crash reporting
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
        }
    }

    // App Bundle configuration
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // AndroidX Core for better compatibility
    implementation("androidx.core:core-ktx:1.12.0")
    
    // Security library for better encryption
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
}
