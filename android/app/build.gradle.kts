import java.util.Properties
import java.io.FileInputStream
import java.io.FileOutputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val versionPropertiesFile = rootProject.file("version.properties")
val versionProperties = Properties()
if (versionPropertiesFile.exists()) {
    versionProperties.load(FileInputStream(versionPropertiesFile))
}

var appVersionCode = versionProperties
    .getProperty("VERSION_CODE", flutter.versionCode.toString())
    .toInt()

val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (isReleaseBuild) {
    versionProperties.setProperty("VERSION_CODE", (appVersionCode + 1).toString())
    versionProperties.store(FileOutputStream(versionPropertiesFile), null)
}

android {
    namespace = "com.swappro.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.swappro.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersionCode
        versionName = flutter.versionName
    }
    
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
